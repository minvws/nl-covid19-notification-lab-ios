/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit
import ExposureNotification
import CoreBluetooth

class ReceiverViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    
    @Persisted(userDefaultsKey: "testResults", notificationName: .init("TestResultsDidChange"), defaultValue: [])
    var testResults: [TestResult]
    
    private var exposureWindows = [ENExposureWindow]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(onScannedQR(_:)), name: Server.shared.$diagnosisKeyURL.notificationName, object: nil)
        
        updateUI()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Server.shared.$diagnosisKeyURL.notificationName, object: nil)
    }
    
    private func updateUI() {
        tableView.reloadData()
        shareButton.isEnabled = !testResults.isEmpty
        deleteButton.isEnabled = !testResults.isEmpty
    }
    
    @objc func onScannedQR(_ notification: Notification) {
        
        guard let scannedKey = Server.shared.diagnosisKeys.first else {
            self.showDialog(title: "Error", message: "No scanned diagnosiskey found")
            return
        }
                
        ExposureManager.shared.detectExposures { result in
            
            switch(result) {
            
            case let .failure(error):
                self.exposureWindows = []
                self.showDialog(title: "Error", message: "\(error)")
                
            case let .success(exposureWindows):
                
                if exposureWindows.isEmpty {
                    self.showDialog(message: "no exposure windows found")
                }
                
                self.generateTestResults(scannedKey: scannedKey, exposureWindows: exposureWindows)
                
                self.updateUI()
            }
        }
    }
    
    private func generateTestResults(scannedKey: CodableDiagnosisKey, exposureWindows: [ENExposureWindow]) {
        
        let testResultID = UUID()
        
        let newTestResults: [TestResult] = exposureWindows.flatMap { (window) in
            window.scanInstances.compactMap { (scan) in
                let windowID = UUID()
                
                return TestResult(
                    id: testResultID.uuidString,
                    test: scannedKey.testId,
                    scannedDevice: scannedKey.deviceId,
                    scannedTEK: scannedKey.keyData.base64EncodedString(),
                    timestamp: Date().timeIntervalSince1970,
                    exposureWindowID: windowID.uuidString,
                    exposureWindowTimestamp: window.date.timeIntervalSince1970,
                    calibrationConfidence: Int(window.calibrationConfidence.rawValue),
                    scanInstanceId: UUID().uuidString,
                    minAttenuation: scan.minimumAttenuation,
                    typicalAttenuation: scan.typicalAttenuation,
                    secondsSinceLastScan: scan.secondsSinceLastScan
                )
            }
        }
        
        testResults.append(contentsOf: newTestResults)
    }
    
    func showDialog(title: String = "Info", message:String) {
        let alert = UIAlertController(title: "Info", message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .destructive, handler: nil))
        alert.message = message
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func scanQrClick(_ sender: Any) {
        self.present(ScannerViewController(), animated: true, completion: nil)
    }
    
    @IBAction func trashClick(_ sender: Any) {
        let alert = UIAlertController(title: "Warning", message: "This will delete all stored testdata! This operation CANNOT be undone. Make sure you export any data you want to keep.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
            self.testResults = []
            self.updateUI()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func shareClick(_ sender: Any) {
        
        var lines = ["Id,Test,Scanned device,Scanned TEK,Timestamp,Exposure window id,Exposure window timestamp,Calibration confidence,Scan instance id,Min attenuation,Typical attenuation,Seconds since last scan"]
        
        testResults.forEach { (result) in
            lines.append("\(result.id),\(result.test),\(result.scannedDevice),\(result.scannedTEK),\(result.timestamp),\(result.exposureWindowID),\(result.exposureWindowTimestamp), \(result.calibrationConfidence),\(result.scanInstanceId),\(result.minAttenuation),\(result.typicalAttenuation),\(result.secondsSinceLastScan)")
        }
        
        let fileManager = FileManager.default
        do {
            let path = try fileManager.url(for: .documentDirectory, in: .allDomainsMask, appropriateFor: nil, create: false)
            let fileURL = path.appendingPathComponent("testresults.csv")
            try lines.joined(separator: "\n").write(to: fileURL, atomically: true, encoding: .utf8)

            let objectsToShare = [fileURL]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)

            self.present(activityVC, animated: true, completion: nil)
    
        } catch {
            print("error creating file")
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
        cellContent.append("\(testResult.test) - \(testResult.scannedDevice)")
        cellContent.append("\(Date(timeIntervalSince1970: testResult.timestamp))")
        cellContent.append("\(testResult.scannedTEK)")
        cellContent.append("Attn min: \(testResult.minAttenuation) Db, typical: \(testResult.typicalAttenuation) Db, secondsSinceLastScan: \(testResult.secondsSinceLastScan) s")
                
        cell.textLabel?.text = cellContent.joined(separator: "\n")
        cell.textLabel?.numberOfLines = 0
        
        return cell
    }
}

struct TestResult: Codable {
    let id: String
    let test: String
    let scannedDevice: String
    let scannedTEK: String
    let timestamp: Double //?
    let exposureWindowID: String
    let exposureWindowTimestamp: Double //?
    let calibrationConfidence: Int
    let scanInstanceId: String
    let minAttenuation: ENAttenuation
    let typicalAttenuation: ENAttenuation
    let secondsSinceLastScan: Int
}
