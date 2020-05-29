/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit
import ExposureNotification
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate {
    
    @IBOutlet weak var lblScan: UILabel!
    @IBOutlet weak var btnDetect: UIButton!
    @IBOutlet weak var textViewStatus: UITextView!
    @IBOutlet weak var btnDetectHeightConstraint: NSLayoutConstraint!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(onScannedQR(_:)), name: Server.shared.$urls.notificationName, object: nil)
        centralManager = CBCentralManager(delegate: self, queue: nil)
        centralManager.scanForPeripherals(withServices: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Server.shared.$urls.notificationName, object: nil)
    }
    
    @objc func onScannedQR(_ notification:Notification) {
        btnDetect.isHidden = false
        btnDetectHeightConstraint.constant = 50
        lblScan.isHidden = true
    }
    
    @IBAction func detectClick(_ sender: Any) {
        ExposureManager.shared.detectExposures { result in
            
            var rssi = " Average RSSI (all in range devices): "
            for (_, value) in self.rssiDict {
                let avg = value.reduce(0, +) / value.count
                rssi.append("[\(avg)]")
            }
            
            var string = String(describing: result)
            string.append(rssi)
            self.setStatus(text: string)
        }
    }
    
    @IBAction func scanQrClick(_ sender: Any) {
        self.present(ScannerViewController(), animated: true, completion: nil)
    }
    
    func setStatus(text:String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy HH:mm:ss"
        let date = formatter.string(from: Date())
        self.textViewStatus.text = "\(date) \n(\(text) \n\n" + self.textViewStatus.text
    }
    
    var rssiDict: [String: [Int]] = [:]
    var centralManager: CBCentralManager!
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if(central.state == .poweredOn) {
            centralManager.scanForPeripherals(withServices: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        var list = rssiDict[peripheral.identifier.uuidString] ?? []
        if(list.count > 10) {
            list.remove(at: 0)
        }
        list.append(RSSI.intValue)
        rssiDict[peripheral.identifier.uuidString] = list
    }
}

