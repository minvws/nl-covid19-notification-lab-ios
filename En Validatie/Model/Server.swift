/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import ExposureNotification
import CommonCrypto

struct CodableDiagnosisKey: Codable, Equatable {
    let keyData: Data
    let rollingPeriod: ENIntervalNumber
    let rollingStartNumber: ENIntervalNumber
    let transmissionRiskLevel: ENRiskLevel
    let testId:String
    let deviceId:String
    let daysSinceOnsetOfSymptoms:Int
}

class Server {
    
    static let shared = Server()
            
    @Persisted(userDefaultsKey: "diagnosisFiles", notificationName: .init("DiagnosisFilesDidChange"), defaultValue: nil)
    var diagnosisKeyURL: URL?
    
    @Persisted(userDefaultsKey: "diagnosisKey", notificationName: .init("ServerDiagnosisKeysDidChange"), defaultValue: nil)
    var diagnosisKey: CodableDiagnosisKey?
    
    @Persisted(userDefaultsKey: "scannedDiagnosisKeys", notificationName: .init("ServerSCannedDiagnosisKeysDidChange"), defaultValue: [])
    var scannedDiagnosisKeys: [String]
    
    
    /// Stores the passed Diagnosiskey in local storage and generates and saves a binary and signature pair of files based on that locally stored diagnosis keys
    /// - Parameters:
    ///   - key: The key to be stored locally
    ///   - completion: Called when actions are complete
    func postDiagnosisKeys(_ key: CodableDiagnosisKey, completion: (Error?) -> Void) {
        
        diagnosisKey = key
        
        downloadDiagnosisKeyFile(diagnosisKey: key) { result in
            switch(result) {
            case let .success(url):
                self.diagnosisKeyURL = url
                completion(nil)
            case let .failure(error):
                print(error)
                completion(error)
            }
        }
    }
    
    func clearData() {
        scannedDiagnosisKeys = []
        diagnosisKey = nil
        diagnosisKeyURL = nil
    }
    
    /// Generates and saves a binary and signature pair of files based on `diagnosisKey`
    /// - Parameter completion: Called when action is completed, parameter contains the local URL of the downloaded diagnosis key file ('.bin') or an error when it failed
    private func downloadDiagnosisKeyFile(diagnosisKey: CodableDiagnosisKey, completion: (Result<URL, Error>) -> Void) {
        
        do {
                        
            let signatureInfo = SignatureInfo.with { signatureInfo in
                signatureInfo.verificationKeyVersion = "v1"
                signatureInfo.verificationKeyID = "204"
                signatureInfo.signatureAlgorithm = "1.2.840.10045.4.3.2"
            }
            
            // In a real implementation, the file at remoteURL would be downloaded from a server
            // This sample generates and saves a binary and signature pair of files based on the locally stored diagnosis keys
            let export = TemporaryExposureKeyExport.with { export in
                export.batchNum = 1
                export.batchSize = 1
                export.region = "204"
                export.signatureInfos = [signatureInfo]
                export.keys = [diagnosisKey].map { diagnosisKey in
                    TemporaryExposureKey.with { temporaryExposureKey in
                        temporaryExposureKey.keyData = diagnosisKey.keyData
                        temporaryExposureKey.transmissionRiskLevel = Int32(diagnosisKey.transmissionRiskLevel)
                        temporaryExposureKey.rollingStartIntervalNumber = Int32(diagnosisKey.rollingStartNumber)
                        temporaryExposureKey.rollingPeriod = Int32(diagnosisKey.rollingPeriod)
                        temporaryExposureKey.daysSinceOnsetOfSymptoms = Int32(diagnosisKey.daysSinceOnsetOfSymptoms)
                    }
                }
            }
            
            let exportData = "EK Export v1    ".data(using: .utf8)! + (try! export.serializedData())
            
            let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            
            let uuid = UUID().uuidString
            let localBinURL = cachesDirectory.appendingPathComponent(uuid + ".bin")
            try exportData.write(to: localBinURL)
                        
            completion(.success(localBinURL))
        } catch {
            completion(.failure(error))
        }
        
        
    }
        
    func getExposureConfiguration(completion: (Result<ENExposureConfiguration, Error>) -> Void) {
        
        let SEQUENTIAL_WEIGHTS :[NSNumber] = [1,2,3,4,5,6,7,8]
        let EQUAL_WEIGHTS :[NSNumber] = [1,1,1,1,1,1,1,1]
        
        let exposureConfiguration = ENExposureConfiguration()
        exposureConfiguration.minimumRiskScore = 1
        exposureConfiguration.attenuationLevelValues = SEQUENTIAL_WEIGHTS
        exposureConfiguration.daysSinceLastExposureLevelValues = EQUAL_WEIGHTS
        exposureConfiguration.durationLevelValues = EQUAL_WEIGHTS
        exposureConfiguration.transmissionRiskLevelValues = EQUAL_WEIGHTS
        exposureConfiguration.metadata = ["attenuationDurationThresholds": [42, 56]]
        exposureConfiguration.infectiousnessForDaysSinceOnsetOfSymptoms = [
            -14: NSNumber(value: ENInfectiousness.high.rawValue),
            -13: NSNumber(value: ENInfectiousness.high.rawValue),
            -12: NSNumber(value: ENInfectiousness.high.rawValue),
            -11: NSNumber(value: ENInfectiousness.high.rawValue),
            -10: NSNumber(value: ENInfectiousness.high.rawValue),
            -9: NSNumber(value: ENInfectiousness.high.rawValue),
            -8: NSNumber(value: ENInfectiousness.high.rawValue),
            -7: NSNumber(value: ENInfectiousness.high.rawValue),
            -6: NSNumber(value: ENInfectiousness.high.rawValue),
            -5: NSNumber(value: ENInfectiousness.high.rawValue),
            -4: NSNumber(value: ENInfectiousness.high.rawValue),
            -3: NSNumber(value: ENInfectiousness.high.rawValue),
            -2: NSNumber(value: ENInfectiousness.high.rawValue),
            -1: NSNumber(value: ENInfectiousness.high.rawValue),
            0: NSNumber(value: ENInfectiousness.high.rawValue),
            1: NSNumber(value: ENInfectiousness.high.rawValue),
            2: NSNumber(value: ENInfectiousness.high.rawValue),
            3: NSNumber(value: ENInfectiousness.high.rawValue),
            4: NSNumber(value: ENInfectiousness.high.rawValue),
            5: NSNumber(value: ENInfectiousness.high.rawValue),
            6: NSNumber(value: ENInfectiousness.high.rawValue),
            7: NSNumber(value: ENInfectiousness.high.rawValue),
            8: NSNumber(value: ENInfectiousness.high.rawValue),
            9: NSNumber(value: ENInfectiousness.high.rawValue),
            10: NSNumber(value: ENInfectiousness.high.rawValue),
            11: NSNumber(value: ENInfectiousness.high.rawValue),
            12: NSNumber(value: ENInfectiousness.high.rawValue),
            13: NSNumber(value: ENInfectiousness.high.rawValue),
            14: NSNumber(value: ENInfectiousness.high.rawValue)
        ]
        
        // Suggested by apple to get v2 to work properly:
        // "please make sure you’ve set reportTypeNoneMap in the configuration object to something appropriate. If the keys you are downloading have been uploaded by an app using v1 APIs, they don’t have a reportType, so the reportTypeNoneMap value is used to determine how to treat those keys, and the default is .unknown which would cause those keys to be dropped."
        exposureConfiguration.reportTypeNoneMap = .confirmedTest
        
        completion(.success(exposureConfiguration))

        // We tried setting the following properties too but it had no effect
//        exposureConfiguration.immediateDurationWeight = 100
//        exposureConfiguration.nearDurationWeight = 100
//        exposureConfiguration.mediumDurationWeight = 100
//        exposureConfiguration.otherDurationWeight = 100
//        
//        exposureConfiguration.infectiousnessStandardWeight = 100
//        exposureConfiguration.infectiousnessHighWeight = 100
//        
//        exposureConfiguration.reportTypeConfirmedTestWeight = 100
//        exposureConfiguration.reportTypeConfirmedClinicalDiagnosisWeight = 100
//        exposureConfiguration.reportTypeSelfReportedWeight = 100
//        exposureConfiguration.reportTypeRecursiveWeight = 100
//        
//        exposureConfiguration.reportTypeNoneMap = .confirmedTest
    }
}
