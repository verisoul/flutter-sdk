//
//  VerisoulApi.swift
//  verisoul_sdk
//
//  Created by ahmed alaa on 08/02/2025.
//

import Foundation
import VerisoulSDK

extension String: @retroactive Error {}


class VerisoulApi : VerisoulApiHostApi{
    func setAccountData(account: [String : Any?]) throws {

    }
    
    func reinitialize() throws {

        Verisoul.shared.reinitialize()
    }
    
    
    static let sdkLogLevels: [Int64: VerisoulSDK.VerisoulEnvironment] = [
       0: .dev,
       1: .prod,
       2: .sandbox,
       3: .staging
     ]
    
    
func configure(enviromentVariable: Int64, projectId: String) throws {
    guard let env = VerisoulApi.sdkLogLevels[enviromentVariable] else {
        throw "Invalid environment value: \(enviromentVariable)"
       }

       Verisoul.shared.configure(env: env, projectId: projectId)
}

func onTouchEvent(x: Double, y: Double, motionType: Int64) throws {
    
}

func getSessionId(completion: @escaping (Result<String, any Error>) -> Void) {
    Task {
          do {
            let sessionId = try await Verisoul.shared.session()
              completion(Result.success(sessionId))
          } catch {
              completion(Result.failure("Failed to retrieve session ID"))
          }
        }
}

    
    
    
}
