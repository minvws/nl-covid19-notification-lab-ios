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
    @IBOutlet weak var labelAPIVersion: UILabel!
    @IBOutlet weak var labelAppVersion: UILabel!
    
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
        labelAPIVersion.text = "v\(apiVersion?.intValue ?? 1)"
        labelAppVersion.text = "\((Config.infoDictionary["CFBundleShortVersionString"] as? String) ?? "") (\((Config.infoDictionary["CFBundleVersion"] as? String) ?? ""))"
        
    }
    
    @IBAction func generateQRCode(_ sender: Any) {
        
        guard let testId = textFieldTestId.text, !testId.isEmpty else {
            showDialog(message: "Please enter a Test id")
            clearQRCode()
            return
        }
                
        ExposureManager.shared.getTestDiagnosisKeys { result in
            
            switch(result) {
                
            case let .success(keys):
                guard let firstKey = keys.first, keys.count == 1 else {
                    self.showDialog(message: "You have \(keys.count) keys. Make sure you have 1 key")
                    self.clearQRCode()
                    return
                }
                
                let key = CodableDiagnosisKey(
                    keyData: firstKey.keyData,
                    rollingPeriod: firstKey.rollingPeriod,
                    rollingStartNumber: firstKey.rollingStartNumber,
                    transmissionRiskLevel: firstKey.transmissionRiskLevel,
                    testId: testId,
                    deviceId: UIDevice.current.name
                )
                
                let jsonData = try! JSONEncoder().encode(key)
                let jsonString = String(data: jsonData, encoding: .isoLatin1)
                self.generateQrCode(code: jsonString!)
                self.labelTEK.text = firstKey.keyData.base64EncodedString()
                
            case let .failure(error):
                print(error)
                self.showDialog(title: "Error", message: "\(error)")
                self.clearQRCode()
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
    
    private func clearQRCode() {
        labelTEK.text = nil
        imageViewQr.image = nil
    }
    
    private func generateQrCode(code: String) {
        
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            showDialog(title: "Error", message: "QR Code cannot be created due to an internal error (filter does not exist)")
            return
        }
        
        guard let data = code.data(using: .isoLatin1) else {
            showDialog(title: "Error", message: "QR Code cannot be created due to an internal error (unable to create data from string \(code))")
            return
        }
        
        filter.setValue(data, forKey: "inputMessage")
                
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        
        guard let outputImage = filter.outputImage else {
            showDialog(title: "Error", message: "QR Code cannot be created due to an internal error (no output image)")
            return
        }
            
        let scaledImage = outputImage.transformed(by: transform)
                
        imageViewQr.image = UIImage(ciImage: scaledImage)
    }
}
