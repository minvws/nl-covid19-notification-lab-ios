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
}

struct CodableExposureConfiguration: Codable {
    let minimumRiskScore: ENRiskScore
    let attenuationDurationThresholds: [Int]
    let attenuationLevelValues: [ENRiskLevelValue]
    let daysSinceLastExposureLevelValues: [ENRiskLevelValue]
    let durationLevelValues: [ENRiskLevelValue]
    let transmissionRiskLevelValues: [ENRiskLevelValue]
}

class Server {
    
    static let shared = Server()
    
    @Persisted(userDefaultsKey: "diagnosisFiles", notificationName: .init("DiagnosisFilesDidChange"), defaultValue: [])
    var urls: [URL]
    
    @Persisted(userDefaultsKey: "diagnosisKeys", notificationName: .init("ServerDiagnosisKeysDidChange"), defaultValue: [])
    var diagnosisKeys: [CodableDiagnosisKey]
    
    
    /// Stores the passed Diagnosiskey in local storage and generates and saves a binary and signature pair of files based on that locally stored diagnosis keys
    /// - Parameters:
    ///   - key: The key to be stored locally
    ///   - completion: Called when actions are complete
    func postDiagnosisKeys(_ key: CodableDiagnosisKey, completion: (Error?) -> Void) {
        
        diagnosisKeys = [key]
        
        downloadDiagnosisKeyFile { result in
            switch(result) {
            case let .success(urls):
                self.urls = urls
                completion(nil)
                break;
            case let .failure(error):
                print(error)
                completion(error)
                break;
            }
        }
    }
    
    /// Generates and saves a binary and signature pair of files based on `diagnosisKeys`
    /// - Parameter completion: Called when action is completed, parameter contains the local URL of the downloaded diagnosis key file ('.bin') or an error when it failed
    private func downloadDiagnosisKeyFile(completion: (Result<[URL], Error>) -> Void) {
        
        let signatureInfo = SignatureInfo.with { signatureInfo in
            signatureInfo.appBundleID = Bundle.main.bundleIdentifier!
            signatureInfo.verificationKeyVersion = "v1"
            signatureInfo.verificationKeyID = "310"
            signatureInfo.signatureAlgorithm = "SHA256withECDSA"
        }
        
        // In a real implementation, the file at remoteURL would be downloaded from a server
        // This sample generates and saves a binary and signature pair of files based on the locally stored diagnosis keys
        let export = TemporaryExposureKeyExport.with { export in
            export.batchNum = 1
            export.batchSize = 1
            export.region = "310"
            export.signatureInfos = [signatureInfo]
            export.keys = diagnosisKeys.shuffled().map { diagnosisKey in
                TemporaryExposureKey.with { temporaryExposureKey in
                    temporaryExposureKey.keyData = diagnosisKey.keyData
                    temporaryExposureKey.transmissionRiskLevel = Int32(diagnosisKey.transmissionRiskLevel)
                    temporaryExposureKey.rollingStartIntervalNumber = Int32(diagnosisKey.rollingStartNumber)
                    temporaryExposureKey.rollingPeriod = Int32(diagnosisKey.rollingPeriod)
                }
            }
        }
        
        do {
            let exportData = "EK Export v1    ".data(using: .utf8)! + (try export.serializedData())
            let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            let localBinURL = cachesDirectory.appendingPathComponent(UUID().uuidString + ".bin")
            
            try exportData.write(to: localBinURL)
            
            completion(.success([localBinURL]))
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
        completion(.success(exposureConfiguration))
    }
}
