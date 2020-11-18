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
    
    func getExposureWindows(completion: @escaping (Result<[ENExposureWindow], Error>) -> Void) {
        
        guard let diagnosisKeyURL = Server.shared.diagnosisKeyURL else {
            return
        }
        
        // get config
        Server.shared.getExposureConfiguration { result in
            
            switch result {
            case let .success(configuration):
                
                ExposureManager.shared.manager.detectExposures(configuration: configuration, diagnosisKeyURLs: [diagnosisKeyURL]) { summary, error in
                    
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
                }
                
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    /// Gets special testdiagnosiskeys from the EN framework. These keys are special because they do not require a 24 hour waiting period to be released.
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
