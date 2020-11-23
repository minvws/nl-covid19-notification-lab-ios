//
//  CodableExposureWindow.swift
//  En Validatie
//
//  Created by Roel Spruit on 23/11/2020.
//  Copyright © 2020 Rijksoverheid. All rights reserved.
//

import Foundation
import ExposureNotification

struct CodableExposureWindow: Codable {
    let date: Date
    let scanInstances: [CodableScanInstance]
    let calibrationConfidence: UInt8
    
    struct CodableScanInstance: Codable {
        let minimumAttenuation: Int
        let typicalAttenuation: Int
        let secondsSinceLastScan: Int
    }
    
    init(_ exposureWindow: ENExposureWindow) {
        date = exposureWindow.date
        calibrationConfidence = exposureWindow.calibrationConfidence.rawValue
        scanInstances = exposureWindow.scanInstances.map({ (scanInstance) in
            CodableScanInstance(minimumAttenuation: Int(scanInstance.minimumAttenuation),
                                typicalAttenuation: Int(scanInstance.typicalAttenuation),
                                secondsSinceLastScan: scanInstance.secondsSinceLastScan)
        })
    }
}
