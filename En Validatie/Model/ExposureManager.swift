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
            if ENManager.authorizationStatus == .authorized && !self.manager.exposureNotificationEnabled {
                self.manager.setExposureNotificationEnabled(true) { _ in
                    // No error handling for attempts to enable on launch
                }
            }
        }
    }
    
    deinit {
        manager.invalidate()
    }
    
    func detectExposures(completion: @escaping (Result<[ENExposureInfo]?, Error>) -> Void) {
        
        let urls = Server.shared.urls
        // get config
        Server.shared.getExposureConfiguration { result in
            
            switch result {
            case let .success(configuration):
                
                // detect exposures based on downloaded keys and configuration
                self.detectExposures(configuration: configuration, urls: urls, completion: completion)
                break;
            case let .failure(error):
                completion(.failure(error))
                return
                
            }
        }
    }
    
    private func detectExposures(configuration: ENExposureConfiguration, urls: [URL], completion: @escaping (Result<[ENExposureInfo]?, Error>) -> Void) {
        ExposureManager.shared.manager.detectExposures(configuration: configuration, diagnosisKeyURLs: urls) { summary, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            ExposureManager.shared.manager.getExposureInfo(summary: summary!, userExplanation: "") { (info, error) in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                completion(.success(info))
            }
        }
    }
    
    func getAndPostDiagnosisKeys(completion: @escaping (Result<[ENTemporaryExposureKey], Error>) -> Void) {
        manager.getTestDiagnosisKeys { temporaryExposureKeys, error in
            if let error = error {
                completion(.failure(error))
            } else {
                guard let keys = temporaryExposureKeys else {
                    return
                }
                completion(.success(keys))
            }
        }
    }
}
