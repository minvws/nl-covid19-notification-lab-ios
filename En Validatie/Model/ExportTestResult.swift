/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

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

extension Collection where Element == ExportTestResult {
    var minAttenuation: Int {
        !self.isEmpty ? self.reduce(Int.max, { Swift.min($0, $1.minAttenuation ?? 0) }) : 0
    }
    
    var averageAttenuation: Int {
        self.map({ $0.typicalAttenuation ?? 0 }).average()
    }
    
    var duration: Int {
        self.reduce(0, { $0 + ($1.secondsSinceLastScan ?? 0) })
    }
}
