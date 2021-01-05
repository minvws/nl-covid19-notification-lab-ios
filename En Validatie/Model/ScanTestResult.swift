/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation

struct ScanTestResult: Codable {
    let id: String
    let scannedTek: String
    let scanningDeviceId: String
    let scannedDeviceId: String
    let testId: String
    let timestamp: TimeInterval
    let exposureWindows: [CodableExposureWindow]
    
    var allScanInstances: [CodableExposureWindow.CodableScanInstance] { exposureWindows.flatMap({ $0.scanInstances }) }    
    var minAttenuation: Int { !allScanInstances.isEmpty ? allScanInstances.reduce(Int.max, { min($0, $1.minimumAttenuation) }) : 0 }
    var averageAttenuation: Int { allScanInstances.map({ $0.typicalAttenuation }).average() }
    var duration: Int {allScanInstances.reduce(0, { $0 + $1.secondsSinceLastScan }) }
}
