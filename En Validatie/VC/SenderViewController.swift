/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

class SenderViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var imageViewQr: UIImageView!
    @IBOutlet weak var switchEN: UISwitch!
    @IBOutlet weak var buttonShare: UIButton!
    @IBOutlet weak var textFieldTestId: UITextField!
    @IBOutlet weak var labelDeviceName: UILabel!
    @IBOutlet weak var labelTEK: UILabel!
    @IBOutlet weak var LabelAPIVersion: UILabel!
    
    private var keyValueObservers = [NSKeyValueObservation]()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        keyValueObservers.append(ExposureManager.shared.manager.observe(\.exposureNotificationStatus) { [unowned self] manager, change in
            self.switchEN.isOn = ExposureManager.shared.manager.exposureNotificationEnabled
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textFieldTestId.delegate = self
        labelDeviceName.text = UIDevice.current.name
        let apiVersion = Config.infoDictionary["ENAPIVersion"] as? NSNumber
        LabelAPIVersion.text = "\(apiVersion?.intValue ?? 1)"
    }
    
    @IBAction func generateQRCode(_ sender: Any) {
        
        guard let testId = textFieldTestId.text, !testId.isEmpty else {
            showDialog(message: "Please enter a Test id")
            return
        }
                
        ExposureManager.shared.getTestDiagnosisKeys { result in
            
            switch(result) {
                
            case let .success(keys):
                guard let firstKey = keys.first, keys.count == 1 else {
                    self.showDialog(message: "You have \(keys.count) keys. Make sure you have 1 key")
                    return
                }
                
                let key = CodableDiagnosisKey(
                    keyData: firstKey.keyData,
                    rollingPeriod: firstKey.rollingPeriod,
                    rollingStartNumber: firstKey.rollingStartNumber,
                    transmissionRiskLevel: firstKey.transmissionRiskLevel,
                    testId: testId,
                    deviceId: UIDevice.current.name,
                    daysSinceOnsetOfSymptoms: 2
                )
                
                let jsonData = try! JSONEncoder().encode(key)
                let jsonString = String(data: jsonData, encoding: .utf8)
                self.generateQrCode(code: jsonString!)
                self.labelTEK.text = firstKey.keyData.base64EncodedString()
                
            case let .failure(error):
                print(error)
                self.showDialog(title: "Error", message: "\(error)")
            }
        }
    }
    
    @IBAction func switchChanged(_ sender: UISwitch) {
        ExposureManager.shared.manager.setExposureNotificationEnabled(sender.isOn) { error in
            if let error = error {
                self.switchEN.isOn = ExposureManager.shared.manager.exposureNotificationEnabled
                self.showDialog(title: "Error", message: "\(error)")
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    private func showDialog(title: String = "Info", message: String) {
        let alert = UIAlertController(title: title, message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .destructive, handler: nil))
        alert.message = message
        present(alert, animated: true, completion: nil)
    }
    
    private func generateQrCode(code: String) {
        let data = code.data(using: String.Encoding.ascii)
        
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            
            if let output = filter.outputImage?.transformed(by: transform) {
                imageViewQr.image = UIImage(ciImage: output)
            }
        }
    }
    
}
