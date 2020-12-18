/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import XCTest
@testable import EN_Validatie

class TestResultExporterTests: XCTestCase {

    private var sut: TestResultExporter!
    
    override func setUpWithError() throws {
        sut = TestResultExporter()
    }
    
    func test_shouldCreateExportTestResult() {
        let windowDate = Date()
        let scanTestResult = ScanTestResult(id: "id", scannedTek: "scannedTek", scanningDeviceId: "scanningDeviceId", scannedDeviceId: "scannedDeviceId", testId: "testId", timestamp: 20, exposureWindows: [
            .init(date: windowDate, scanInstances: [
                .init(minimumAttenuation: 20, typicalAttenuation: 30, secondsSinceLastScan: 40)
            ], calibrationConfidence: 8)
        ])
        
        let result = sut.generateExportTestResults(from: scanTestResult)
        
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, "id")
        XCTAssertEqual(result.first?.test, "testId")
        XCTAssertEqual(result.first?.scanningDevice, "scanningDeviceId")
        XCTAssertEqual(result.first?.scannedDevice, "scannedDeviceId")
        XCTAssertEqual(result.first?.scannedTEK, "scannedTek")
        XCTAssertEqual(result.first?.timestamp, 20)
        XCTAssertTrue(result.first?.exposureWindowID?.isEmpty == false)
        XCTAssertEqual(result.first?.exposureWindowTimestamp, windowDate.timeIntervalSince1970)
        XCTAssertEqual(result.first?.calibrationConfidence, 8)
        XCTAssertTrue(result.first?.scanInstanceId?.isEmpty == false)
        XCTAssertEqual(result.first?.minAttenuation, 20)
        XCTAssertEqual(result.first?.typicalAttenuation, 30)
        XCTAssertEqual(result.first?.secondsSinceLastScan, 40)
    }
    
    func test_shouldDeDuplicateTestResultsWithMatchingCharacteristics() {
        
        let exportTestResultA = ExportTestResult(
            id: "id",
            test: "test",
            scanningDevice: "scanningDevice",
            scannedDevice: "scannedDevice",
            scannedTEK: "scannedTEK",
            timestamp: 20,
            exposureWindowID: "exposureWindowID",
            exposureWindowTimestamp: 30,
            calibrationConfidence: 40,
            scanInstanceId: "scanInstanceId",
            minAttenuation: 1,
            typicalAttenuation: 2,
            secondsSinceLastScan: 3
        )
        
        let exportTestResultB = ExportTestResult(
            id: "idB",
            test: "test",
            scanningDevice: "scanningDeviceB",
            scannedDevice: "scannedDeviceB",
            scannedTEK: "scannedTEKB",
            timestamp: 20,
            exposureWindowID: "exposureWindowIDB",
            exposureWindowTimestamp: 30,
            calibrationConfidence: 40,
            scanInstanceId: "scanInstanceIdB",
            minAttenuation: 1,
            typicalAttenuation: 2,
            secondsSinceLastScan: 3
        )
                
        let result = sut.deduplicate(testResults: [exportTestResultA, exportTestResultB])
        
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, "id")
    }
    
    func test_shouldNotDeDuplicateTestResultsWithMatchingCharacteristics() {
        
        let exportTestResultA = ExportTestResult(
            id: "id",
            test: "test",
            scanningDevice: "scanningDevice",
            scannedDevice: "scannedDevice",
            scannedTEK: "scannedTEK",
            timestamp: 20,
            exposureWindowID: "exposureWindowID",
            exposureWindowTimestamp: 30,
            calibrationConfidence: 40,
            scanInstanceId: "scanInstanceId",
            minAttenuation: 1,
            typicalAttenuation: 2,
            secondsSinceLastScan: 3
        )
        
        let exportTestResultB = ExportTestResult(
            id: "idB",
            test: "test",
            scanningDevice: "scanningDeviceB",
            scannedDevice: "scannedDeviceB",
            scannedTEK: "scannedTEKB",
            timestamp: 20,
            exposureWindowID: "exposureWindowIDB",
            exposureWindowTimestamp: 30,
            calibrationConfidence: 40,
            scanInstanceId: "scanInstanceIdB",
            minAttenuation: 1,
            typicalAttenuation: 2,
            secondsSinceLastScan: 20 // Different than testresult A
        )
                
        let result = sut.deduplicate(testResults: [exportTestResultA, exportTestResultB])
        
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.first?.id, "id")
        XCTAssertEqual(result.last?.id, "idB")
    }
}
