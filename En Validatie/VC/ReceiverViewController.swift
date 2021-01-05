/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit
import ExposureNotification
import CoreBluetooth

class ReceiverViewController: UIViewController, ScannerViewControllerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    
    private let testResultExporter = TestResultExporter()
    
    @Persisted(userDefaultsKey: "testResults", notificationName: .init("TestResultsDidChange"), defaultValue: [])
    private var testResults: [ScanTestResult]
        
    /// Contains deduplicated test results. Sorted old to new
    private var sanitizedTestResults: [ExportTestResult] {
        
        // order is reversed because deduplication assumes the first scan in the list should remain
        // and the following (identical) scans are duplicates.
        
        let convertedTestResults = testResults
            .reversed()
            .flatMap { testResultExporter.generateExportTestResults(from: $0) }
        
        return testResultExporter.deduplicate(testResults: convertedTestResults)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        updateUI()
    }
        
    @IBAction func scanQrClick(_ sender: Any) {
        guard ExposureManager.shared.manager.exposureNotificationEnabled else {
            showDialog(title: "Error", message: "Scanning a TEK QR Code is only possible if the Exposure Notification framework is enabled. Toggle it on the 'Status' screen.")
            return
        }
        
        let scanner = ScannerViewController()
        scanner.delegate = self
        self.present(scanner, animated: true, completion: nil)
    }
    
    @IBAction func trashClick(_ sender: Any) {
        let alert = UIAlertController(title: "Warning", message: "This will delete all data stored within the app! This will NOT remove the EN logs on the device. This operation CANNOT be undone. Make sure you export any data you want to keep first.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
            self.testResults = []
            Server.shared.clearData()
            self.updateUI()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func shareClick(_ sender: Any) {
        
        guard let csvFileURL = testResultExporter.generateCSV(scanResults: testResults, sanitizedTestResults: sanitizedTestResults) else {
            showDialog(title: "Error", message: "Unable to create testresult exportfile")
            return
        }
        
        let objectsToShare = [csvFileURL]
        let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        present(activityVC, animated: true, completion: nil)
    }
    
    private func updateUI() {
        tableView.reloadData()
        shareButton.isEnabled = !testResults.isEmpty
        deleteButton.isEnabled = !testResults.isEmpty
    }
    
    /// Called when `ScannerViewController` has successfully scanned a TEK QR code. The scanned diagnosiskey will be stored in Server.shared.diagnosisKey at this point.
    func onKeyScanned() {
        
        guard let scannedKey = Server.shared.diagnosisKey else {
            self.showDialog(title: "Error", message: "No scanned diagnosiskey found")
            return
        }
        
        ExposureManager.shared.getExposureWindows { result in
            
            switch(result) {
            
            case let .failure(error):
                self.showDialog(title: "Error", message: "\(error)")
                
            case let .success(exposureWindows):
                
                let allExposureWindows = exposureWindows.map(CodableExposureWindow.init)
                          
                let scanTestResult = ScanTestResult(
                    id: UUID().uuidString,
                    scannedTek: scannedKey.keyData.base64EncodedString(),
                    scanningDeviceId: UIDevice.current.name,
                    scannedDeviceId: scannedKey.deviceId,
                    testId: scannedKey.testId,
                    timestamp: Date().timeIntervalSince1970,
                    exposureWindows: allExposureWindows
                )
                
                self.testResults.append(scanTestResult)
                self.testResults = self.testResults.sortedNewToOld
                
                self.updateUI()
            }
        }
    }
    
    private func showDialog(title: String = "Info", message:String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Info", message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .destructive, handler: nil))
            alert.message = message
            self.present(alert, animated: true, completion: nil)
        }
    }
}

extension ReceiverViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            testResults.remove(at: indexPath.row)
            tableView.reloadData()
        }
    }
}

extension ReceiverViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return testResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let testResult = testResults[indexPath.row]
        
        let resultsForScan = sanitizedTestResults.filter { (tr) -> Bool in
            tr.id == testResult.id
        }.reversed()
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") else {
            return UITableViewCell()
        }
        
        var cellContent = [String]()
        
        cellContent.append("<style>body{font-size:16px;}</style>")
        cellContent.append("<b>Test:</b> \(testResult.testId)<br />")
        cellContent.append("<b>Scanning Device:</b> \(testResult.scanningDeviceId)<br />")
        cellContent.append("<b>Scanned Device:</b> \(testResult.scannedDeviceId)<br />")
        cellContent.append("<b>QR Scanned:</b> \(Date(timeIntervalSince1970: testResult.timestamp))<br />")
        cellContent.append("<b>TEK:</b> \(testResult.scannedTek)<br />")
        
        if !resultsForScan.isEmpty {
            cellContent.append("<b>Attenuation:</b> min:\(resultsForScan.minAttenuation) Db, typical:\(resultsForScan.averageAttenuation) Db<br />")
            cellContent.append("<b>Duration:</b>\(resultsForScan.duration) s<br />")
            cellContent.append("<b>Scans:</b>\(resultsForScan.count)")
        } else {
            cellContent.append("<b>Scans: </b>No scaninstances found")
        }
                        
        let data = cellContent.joined().data(using: String.Encoding.utf16, allowLossyConversion: false)!
        
        cell.textLabel?.attributedText = try! NSAttributedString(
            data: data,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
        )
        cell.textLabel?.numberOfLines = 0
        
        return cell
    }
}

extension Sequence where Element: AdditiveArithmetic {
    /// Returns the total sum of all elements in the sequence
    func sum() -> Element { reduce(.zero, +) }
}

extension Collection where Element: BinaryInteger {
    /// Returns the average of all elements in the array
    func average() -> Element { isEmpty ? .zero : sum() / Element(count) }
    /// Returns the average of all elements in the array as Floating Point type
    func average<T: FloatingPoint>() -> T { isEmpty ? .zero : T(sum()) / T(count) }
}

extension Collection where Element == ScanTestResult {
    var sortedOldToNew: [ScanTestResult] {
        self.sorted { (a, b) -> Bool in
            a.timestamp < b.timestamp
        }
    }
    
    var sortedNewToOld: [ScanTestResult] {
        self.sorted { (a, b) -> Bool in
            a.timestamp > b.timestamp
        }
    }
}
