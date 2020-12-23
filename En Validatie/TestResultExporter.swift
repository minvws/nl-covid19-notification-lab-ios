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
    
    func generateCSV(scanResults: [ScanTestResult], sanitizedTestResults: [ExportTestResult]) -> URL? {
        var lines = ["Id,Test,Scanning Device,Scanned device,Scanned TEK,Timestamp,Exposure window id,Exposure window timestamp,Calibration confidence,Scan instance id,Min attenuation,Typical attenuation,Seconds since last scan"]
        
        scanResults.sortedNewToOld.forEach { (scanResult) in
            let resultsForScan = sanitizedTestResults.filter { (tr) -> Bool in
                tr.id == scanResult.id
            }.reversed()
            
            if resultsForScan.isEmpty {
                lines.append("\(scanResult.id),\(scanResult.testId),\(scanResult.scanningDeviceId),\(scanResult.scannedDeviceId),\(scanResult.scannedTek),\(scanResult.timestamp),,0,0,,0,0,0")
            }
            
            resultsForScan.forEach { (result) in
                let scanInstanceId = result.scanInstanceId != nil ? "\(result.scanInstanceId ?? "")" : ""
                let minAttenuation = result.minAttenuation != nil ? "\(result.minAttenuation ?? 0)" : ""
                let typicalAttenuation = result.typicalAttenuation != nil ? "\(result.typicalAttenuation ?? 0)" : ""
                let secondsSinceLastScan = result.secondsSinceLastScan != nil ? "\(result.secondsSinceLastScan ?? 0)" : ""
                let exposureWindowID = result.exposureWindowID != nil ? "\(result.exposureWindowID ?? "")" : ""
                let exposureWindowTimestamp = result.exposureWindowTimestamp != nil ? "\(result.exposureWindowTimestamp ?? 0)" : ""
                let calibrationConfidence = result.calibrationConfidence != nil ? "\(result.calibrationConfidence ?? 0)" : ""
                
                lines.append("\(result.id),\(result.test),\(result.scanningDevice),\(result.scannedDevice),\(result.scannedTEK),\(result.timestamp),\(exposureWindowID),\(exposureWindowTimestamp),\(calibrationConfidence),\(scanInstanceId),\(minAttenuation),\(typicalAttenuation),\(secondsSinceLastScan)")
            }
        }
                
        
        let fileManager = FileManager.default
        do {
            let path = try fileManager.url(for: .documentDirectory, in: .allDomainsMask, appropriateFor: nil, create: false)
            let fileURL = path.appendingPathComponent("labapp_export_\(UIDevice.current.name).csv")
            try lines.joined(separator: "\n").write(to: fileURL, atomically: true, encoding: .utf8)
            
            return fileURL
        } catch {
            return nil
        }
    }
}
