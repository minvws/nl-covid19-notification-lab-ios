/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import UIKit

class TestResultExporter {
    
    func generateExportTestResults(from testResult: ScanTestResult) -> [ExportTestResult] {
        
        var newTestResults = [ExportTestResult]()
        
        if testResult.exposureWindows.isEmpty {
            newTestResults.append(ExportTestResult(
                id: testResult.id,
                test: testResult.testId,
                scanningDevice: UIDevice.current.name,
                scannedDevice: testResult.scannedDeviceId,
                scannedTEK: testResult.scannedTek,
                timestamp: testResult.timestamp,
                exposureWindowID: nil,
                exposureWindowTimestamp: nil,
                calibrationConfidence: nil,
                scanInstanceId: nil,
                minAttenuation: nil,
                typicalAttenuation: nil,
                secondsSinceLastScan: nil
            ))
        }
        
        testResult.exposureWindows.forEach { (window) in
            
            let windowID = UUID()
            
            if window.scanInstances.isEmpty {
                newTestResults.append(ExportTestResult(
                    id: testResult.id,
                    test: testResult.testId,
                    scanningDevice: testResult.scanningDeviceId,
                    scannedDevice: testResult.scannedDeviceId,
                    scannedTEK: testResult.scannedTek,
                    timestamp: testResult.timestamp,
                    exposureWindowID: windowID.uuidString,
                    exposureWindowTimestamp: window.date.timeIntervalSince1970,
                    calibrationConfidence: Int(window.calibrationConfidence),
                    scanInstanceId: nil,
                    minAttenuation: nil,
                    typicalAttenuation: nil,
                    secondsSinceLastScan: nil
                ))
            }
            
            window.scanInstances.forEach { (scan) in
                
                newTestResults.append(ExportTestResult(
                    id: testResult.id,
                    test: testResult.testId,
                    scanningDevice: testResult.scanningDeviceId,
                    scannedDevice: testResult.scannedDeviceId,
                    scannedTEK: testResult.scannedTek,
                    timestamp: testResult.timestamp,
                    exposureWindowID: windowID.uuidString,
                    exposureWindowTimestamp: window.date.timeIntervalSince1970,
                    calibrationConfidence: Int(window.calibrationConfidence),
                    scanInstanceId: UUID().uuidString,
                    minAttenuation: scan.minimumAttenuation,
                    typicalAttenuation: scan.typicalAttenuation,
                    secondsSinceLastScan: scan.secondsSinceLastScan
                ))
            }
        }
        
        return newTestResults
    }
    
    /// Testresults are considered duplicates if the testid, minAttenuation, typicalAttenuation and secondsSinceLastScan are identical
    /// In this case we deduplicate the list by only using the first instance of such a result
    func deduplicate(testResults: [ExportTestResult]) -> [ExportTestResult] {
        var deduplicatedResults = [ExportTestResult]()
        
        var foundResults = [String]()
        
        testResults.forEach { (testResult) in
            
            if let minAttenuation = testResult.minAttenuation,
               let typicalAttenuation = testResult.typicalAttenuation,
               let secondsSinceLastScan = testResult.secondsSinceLastScan {
                
                let resultId = "\(testResult.test)\(minAttenuation)\(typicalAttenuation)\(secondsSinceLastScan)"
             
                if !foundResults.contains(resultId) {
                    deduplicatedResults.append(testResult)
                    foundResults.append(resultId)
                }
                
            } else {
                deduplicatedResults.append(testResult)
            }
        }
        
        
        
        return deduplicatedResults
    }
}
