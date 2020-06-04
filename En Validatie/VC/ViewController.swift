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

class ViewController: UIViewController, MFMailComposeViewControllerDelegate {
    
    @IBOutlet weak var labelScores: UILabel!
    @IBOutlet weak var constraintShareHeight: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        constraintShareHeight.constant = 0
        NotificationCenter.default.addObserver(self, selector: #selector(onScannedQR(_:)), name: Server.shared.$urls.notificationName, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Server.shared.$urls.notificationName, object: nil)
    }
    
    @objc func onScannedQR(_ notification:Notification) {
        ExposureManager.shared.detectExposures { result in
            
            switch(result) {
                
            case let .failure(error):
                self.labelScores.text = "Error \(error)"
                break;
            case let .success(exposureinfo):
                
                guard let exposures = exposureinfo else {
                    return
                }
                
                if exposures.count > 0 && Server.shared.diagnosisKeys.count > 0 {
                    let scannedKey = Server.shared.diagnosisKeys[0]
                    
                    self.labelScores.text =
                        "Test id: \(scannedKey.testId) \n" +
                        "Device name: \(scannedKey.deviceId) \n" +
                        "Source device name: \(UIDevice.current.name) \n" +
                        "Scanned TEK: \(scannedKey.keyData.base64EncodedString()) \n" +
                        "Attenuation: \(exposures.map({ ($0.attenuationValue)})) \n" +
                        "Duration: \(exposures.map({ ($0.attenuationDurations)})) \n" +
                        "Transmission risk: \(exposures.map({ ($0.transmissionRiskLevel)})) \n" +
                        "Transmission risk score: \(exposures.map({ ($0.totalRiskScore)}))"
                    
                    self.constraintShareHeight.constant = 50
                } else {
                    self.labelScores.text = "No exposure"
                    self.constraintShareHeight.constant = 0
                }
                break;
            }
        }
    }
    
    func showDialog(message:String) {
        let alert = UIAlertController(title: "Info", message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .destructive, handler: nil))
        alert.message = message
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func scanQrClick(_ sender: Any) {
        self.present(ScannerViewController(), animated: true, completion: nil)
    }
    
    @IBAction func shareClick(_ sender: Any) {
        if MFMailComposeViewController.canSendMail() {
            
            guard let body = self.labelScores.text else {
                return
            }
            
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setMessageBody(body, isHTML: false)

            present(mail, animated: true)
        } else {
            self.showDialog(message: "Mail not available")
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}

