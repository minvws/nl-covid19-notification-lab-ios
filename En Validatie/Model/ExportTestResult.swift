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
