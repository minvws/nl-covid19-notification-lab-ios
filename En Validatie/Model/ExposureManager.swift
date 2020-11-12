/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import Foundation
import ExposureNotification
import UserNotifications

class ExposureManager {
    
    static let shared = ExposureManager()
    
    let manager = ENManager()
    
    init() {
        manager.activate { _ in
            
        }
    }
    
    deinit {
        manager.invalidate()
    }
    
    func detectExposures(completion: @escaping (Result<[ENExposureWindow], Error>) -> Void) {
        
        guard let diagnosisKeyURL = Server.shared.diagnosisKeyURL else {
            return
        }
        
        // get config
        Server.shared.getV2ExposureConfiguration { result in
            
            switch result {
            case let .success(configuration):
                
                // detect exposures based on downloaded keys and configuration
                self.detectExposures(configuration: configuration, diagnosisKeyURL: diagnosisKeyURL, completion: completion)
                break;
            case let .failure(error):
                completion(.failure(error))
                return
                
            }
        }
    }
    
    
    /// Detects exposures to affected persons based on an exposure configuration and a url to a stored diagnosisKey
    /// - Parameters:
    ///   - configuration: Configuration of exposure detection
    ///   - diagnosisKeyURL: URL to a locally stored diagnosiskey
    ///   - completion: <#completion description#>
    private func detectExposures(configuration: ENExposureConfiguration, diagnosisKeyURL: URL, completion: @escaping (Result<[ENExposureWindow], Error>) -> Void) {
           
        ExposureManager.shared.manager.detectExposures(configuration: configuration, diagnosisKeyURLs: [diagnosisKeyURL]) { summary, error in
            
            // For some reason `summary` is always empty when using the v2 API
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            ExposureManager.shared.manager.getExposureWindows(summary: summary!) { (exposureWindows, error) in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                completion(.success(exposureWindows ?? []))
            }
            
            // v1 api code
//            ExposureManager.shared.manager.getExposureInfo(summary: summary!, userExplanation: "") { (info, error) in
//                if let error = error {
//                    completion(.failure(error))
//                    return
//                }
//
//                completion(.success(info))
//            }
        }
    }
    
    func getTestDiagnosisKeys(completion: @escaping (Result<[ENTemporaryExposureKey], Error>) -> Void) {
        manager.getTestDiagnosisKeys { temporaryExposureKeys, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(temporaryExposureKeys ?? []))
            }
        }
    }
}
