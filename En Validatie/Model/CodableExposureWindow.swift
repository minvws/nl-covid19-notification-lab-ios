/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

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
    
    init(date: Date, scanInstances: [CodableExposureWindow.CodableScanInstance], calibrationConfidence: UInt8) {
        self.date = date
        self.scanInstances = scanInstances
        self.calibrationConfidence = calibrationConfidence
    }
}
