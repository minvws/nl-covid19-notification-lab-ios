/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

class ServerViewController: UIViewController {
    
    @IBOutlet weak var imageViewQr: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func generateQRCode(_ sender: Any) {
        
        ExposureManager.shared.getAndPostDiagnosisKeys { result in
            switch(result) {
                
            case let .success(keys):
                if keys.count == 1 {
                    
                    let key = CodableDiagnosisKey(keyData: keys[0].keyData, rollingPeriod: keys[0].rollingPeriod, rollingStartNumber: keys[0].rollingStartNumber, transmissionRiskLevel: keys[0].transmissionRiskLevel)
                    let jsonData = try! JSONEncoder().encode(key)
                    let jsonString = String(data: jsonData, encoding: .utf8)
                    self.generateQrCode(code: jsonString!)
                } else {
                    self.showDialog(message: "You have \(keys.count) keys. Make sure you have 1 key")
                }
                break;
            case let .failure(error):
                print(error)
                self.showDialog(message: "Error \(error)")
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
    
    private func generateQrCode(code:String) {
        let data = code.data(using: String.Encoding.ascii)
        
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            
            if let output = filter.outputImage?.transformed(by: transform) {
                self.imageViewQr.image = UIImage(ciImage: output)
            }
        }
    }
    
}
