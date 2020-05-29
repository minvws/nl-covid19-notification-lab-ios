/*
* Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
*  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
*
*  SPDX-License-Identifier: EUPL-1.2
*/

import UIKit
import Foundation

public enum Config {
  private static let infoDictionary: [String: Any] = {
    guard let dict = Bundle.main.infoDictionary else {
      fatalError("File not found")
    }
    return dict
  }()

  static let appCenterApiKey: String = {
    guard let apiKey = Config.infoDictionary["APPCENTER_API_KEY"] as? String else {
      fatalError("Not set")
    }
    return apiKey
  }()
}
