//
//  TestResult.swift
//  En Validatie
//
//  Created by Roel Spruit on 18/11/2020.
//  Copyright © 2020 Rijksoverheid. All rights reserved.
//

import Foundation
import ExposureNotification

struct TestResult: Codable {
    let id: String
    let test: String
    let scannedDevice: String
    let scannedTEK: String
    let timestamp: Double
    let exposureWindowID: String?
    let exposureWindowTimestamp: Double?
    let calibrationConfidence: Int?
    let scanInstanceId: String?
    let minAttenuation: ENAttenuation?
    let typicalAttenuation: ENAttenuation?
    let secondsSinceLastScan: Int?
}
