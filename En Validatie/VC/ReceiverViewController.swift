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
    
    @Persisted(userDefaultsKey: "testResults", notificationName: .init("TestResultsDidChange"), defaultValue: [])
    var testResults: [ScanTestResult]
    
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
        
        let exportedTestResults = testResults.flatMap { self.generateExportTestResults(from: $0) }
        
        var lines = ["Id,Test,Scanning Device,Scanned device,Scanned TEK,Timestamp,Exposure window id,Exposure window timestamp,Calibration confidence,Scan instance id,Min attenuation,Typical attenuation,Seconds since last scan"]
        
        exportedTestResults.forEach { (result) in
            let scanInstanceId = result.scanInstanceId != nil ? "\(result.scanInstanceId ?? "")" : ""
            let minAttenuation = result.minAttenuation != nil ? "\(result.minAttenuation ?? 0)" : ""
            let typicalAttenuation = result.typicalAttenuation != nil ? "\(result.typicalAttenuation ?? 0)" : ""
            let secondsSinceLastScan = result.secondsSinceLastScan != nil ? "\(result.secondsSinceLastScan ?? 0)" : ""
            let exposureWindowID = result.exposureWindowID != nil ? "\(result.exposureWindowID ?? "")" : ""
            let exposureWindowTimestamp = result.exposureWindowTimestamp != nil ? "\(result.exposureWindowTimestamp ?? 0)" : ""
            let calibrationConfidence = result.calibrationConfidence != nil ? "\(result.calibrationConfidence ?? 0)" : ""
            
            lines.append("\(result.id),\(result.test),\(result.scanningDevice),\(result.scannedDevice),\(result.scannedTEK),\(result.timestamp),\(exposureWindowID),\(exposureWindowTimestamp),\(calibrationConfidence),\(scanInstanceId),\(minAttenuation),\(typicalAttenuation),\(secondsSinceLastScan)")
        }
        
        let fileManager = FileManager.default
        do {
            let path = try fileManager.url(for: .documentDirectory, in: .allDomainsMask, appropriateFor: nil, create: false)
            let fileURL = path.appendingPathComponent("labapp_export_\(UIDevice.current.name).csv")
            try lines.joined(separator: "\n").write(to: fileURL, atomically: true, encoding: .utf8)
            
            let objectsToShare = [fileURL]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            
            self.present(activityVC, animated: true, completion: nil)
            
        } catch {
            showDialog(title: "Error", message: "Unable to create testresult exportfile")
        }
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
                
                let scanTestResult = ScanTestResult(
                    id: UUID().uuidString,
                    scannedTek: scannedKey.keyData.base64EncodedString(),
                    scanningDeviceId: UIDevice.current.name,
                    scannedDeviceId: scannedKey.deviceId,
                    testId: scannedKey.testId,
                    timestamp: Date().timeIntervalSince1970,
                    exposureWindows: exposureWindows.map(CodableExposureWindow.init)
                )
                
                self.testResults.append(scanTestResult)
                self.testResults.sort { (a, b) -> Bool in
                    a.timestamp > b.timestamp
                }
                
//                self.generateTestResults(scannedKey: scannedKey, exposureWindows: exposureWindows)
                
                self.updateUI()
            }
        }
    }
    
    private func generateExportTestResults(from testResult: ScanTestResult) -> [ExportTestResult] {
        
        var newTestResults = [ExportTestResult]()
        
        let resultGenerationTimeStamp = Date().timeIntervalSince1970
        
        if testResult.exposureWindows.isEmpty {
            newTestResults.append(ExportTestResult(
                id: testResult.id,
                test: testResult.testId,
                scanningDevice: UIDevice.current.name,
                scannedDevice: testResult.scannedDeviceId,
                scannedTEK: testResult.scannedTek,
                timestamp: testResult.timestamp,
                exposureWindowID: nil,
                exposureWindowTimestamp: nil,
                calibrationConfidence: nil,
                scanInstanceId: nil,
                minAttenuation: nil,
                typicalAttenuation: nil,
                secondsSinceLastScan: nil
            ))
        }
        
        testResult.exposureWindows.forEach { (window) in
            
            let windowID = UUID()
            
            if window.scanInstances.isEmpty {
                newTestResults.append(ExportTestResult(
                    id: testResult.id,
                    test: testResult.testId,
                    scanningDevice: testResult.scanningDeviceId,
                    scannedDevice: testResult.scannedDeviceId,
                    scannedTEK: testResult.scannedTek,
                    timestamp: resultGenerationTimeStamp,
                    exposureWindowID: windowID.uuidString,
                    exposureWindowTimestamp: window.date.timeIntervalSince1970,
                    calibrationConfidence: Int(window.calibrationConfidence),
                    scanInstanceId: nil,
                    minAttenuation: nil,
                    typicalAttenuation: nil,
                    secondsSinceLastScan: nil
                ))
            }
            
            
            window.scanInstances.forEach { (scan) in
                
                newTestResults.append(ExportTestResult(
                    id: testResult.id,
                    test: testResult.testId,
                    scanningDevice: testResult.scanningDeviceId,
                    scannedDevice: testResult.scannedDeviceId,
                    scannedTEK: testResult.scannedTek,
                    timestamp: resultGenerationTimeStamp,
                    exposureWindowID: windowID.uuidString,
                    exposureWindowTimestamp: window.date.timeIntervalSince1970,
                    calibrationConfidence: Int(window.calibrationConfidence),
                    scanInstanceId: UUID().uuidString,
                    minAttenuation: scan.minimumAttenuation,
                    typicalAttenuation: scan.typicalAttenuation,
                    secondsSinceLastScan: scan.secondsSinceLastScan
                ))
            }
        }
        
        return newTestResults
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

extension ReceiverViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return testResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let testResult = testResults[indexPath.row]
        
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
        
        if testResult.allScanInstances.isEmpty {
            cellContent.append("<b>Scans: </b>No scaninstances found")
        } else {
            cellContent.append("<b>Attenuation:</b> min:\(testResult.minAttenuation) Db, typical:\(testResult.averageAttenuation) Db<br />")
            cellContent.append("<b>Duration:</b>\(testResult.duration) s<br />")
            cellContent.append("<b>Scans:</b>\(testResult.allScanInstances.count)")
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
