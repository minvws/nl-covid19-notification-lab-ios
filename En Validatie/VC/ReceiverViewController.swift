/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit
import ExposureNotification
import CoreBluetooth
import MessageUI

class ReceiverViewController: UIViewController, MFMailComposeViewControllerDelegate {
    
//    @IBOutlet weak var labelScores: UILabel!    
    @IBOutlet weak var tableView: UITableView!
    
    private var scannedKey: CodableDiagnosisKey?
    private var exposureWindows = [ENExposureWindow]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(onScannedQR(_:)), name: Server.shared.$urls.notificationName, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Server.shared.$urls.notificationName, object: nil)
    }
    
    @objc func onScannedQR(_ notification: Notification) {
        ExposureManager.shared.detectExposures { result in
            
            switch(result) {
                
            case let .failure(error):
                self.scannedKey = nil
                self.exposureWindows = []
                self.showDialog(title: "Error", message: "\(error)")
                
            case let .success(exposureWindows):
                
                self.scannedKey = Server.shared.diagnosisKeys.first
                self.exposureWindows = exposureWindows
                
                if self.exposureWindows.isEmpty {
                    self.showDialog(message: "no exposure windows found")
                }
                self.tableView.reloadData()
                
//                self.labelScores.text =
//                    "Test id: \(scannedKey.testId) \n" +
//                    "Device name: \(UIDevice.current.name) \n" +
//                    "Source device name: \(scannedKey.deviceId) \n" +
//                    "Scanned TEK: \(scannedKey.keyData.base64EncodedString()) \n" +
//                    "Attenuation: \(exposures.map({ ($0.attenuationValue)})) \n" +
//                    "Attenuation Duration: \(exposures.map({ ($0.attenuationDurations)})) \n" +
//                    "Duration: \(exposures.map({ ($0.duration)})) \n" +
//                    "Transmission risk: \(exposures.map({ ($0.transmissionRiskLevel)})) \n" +
//                    "Transmission risk score: \(exposures.map({ ($0.totalRiskScore)}))"
                
            }
        }
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
    
    @IBAction func shareClick(_ sender: Any) {
//        if MFMailComposeViewController.canSendMail() {
//
//            guard let body = self.labelScores.text else {
//                return
//            }
//
//            let mail = MFMailComposeViewController()
//            mail.mailComposeDelegate = self
//            mail.setMessageBody(body, isHTML: false)
//
//            present(mail, animated: true)
//        } else {
//            self.showDialog(message: "Mail not available")
//        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}

extension ReceiverViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return exposureWindows.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let window = exposureWindows[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") else {
            return UITableViewCell()
        }
        
        cell.textLabel?.text = "\(window.date) | \(window.infectiousness)"
        
        return cell
    }
}
