//
//  ExportTestResult.swift
//  En Validatie
//
//  Created by Roel Spruit on 18/11/2020.
//  Copyright © 2020 Rijksoverheid. All rights reserved.
//

import Foundation
import ExposureNotification

struct ExportTestResult: Codable {
    let id: String
    let test: String
    let scanningDevice: String
    let scannedDevice: String
    let scannedTEK: String
    let timestamp: Double
    let exposureWindowID: String?
    let exposureWindowTimestamp: Double?
    let calibrationConfidence: Int?
    let scanInstanceId: String?
    let minAttenuation: Int?
    let typicalAttenuation: Int?
    let secondsSinceLastScan: Int?
}
