//
//  VerisoulApi.swift
//  verisoul_sdk
//
//  Created by ahmed alaa on 08/02/2025.
//

import Foundation
import VerisoulSDK

/// Local error code constants matching the native SDK
private struct ErrorCodes {
    static let WEBVIEW_UNAVAILABLE = "WEBVIEW_UNAVAILABLE"
    static let SESSION_UNAVAILABLE = "SESSION_UNAVAILABLE"
    static let INVALID_ENVIRONMENT = "INVALID_ENVIRONMENT"
}

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
            throw PigeonError(
                code: ErrorCodes.INVALID_ENVIRONMENT,
                message: "Invalid environment value: \(enviromentVariable)",
                details: nil
            )
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
            } catch let error as NSError {
                // Extract error code from NSError - the native SDK throws VerisoulException which is an NSError subclass
                let errorCode = error.userInfo["errorCode"] as? String ?? ErrorCodes.SESSION_UNAVAILABLE
                completion(Result.failure(PigeonError(
                    code: errorCode,
                    message: error.localizedDescription,
                    details: nil
                )))
            }
        }
    }
}
