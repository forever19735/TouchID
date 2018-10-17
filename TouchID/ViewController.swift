//
//  ViewController.swift
//  TouchID
//
//  Created by john.lin on 2018/10/16.
//  Copyright © 2018年 john.lin. All rights reserved.
//

import UIKit
import LocalAuthentication
struct KeychainConfiguration {
    static let serviceName = "TouchMeIn"
    static let accessGroup: String? = nil
}

class ViewController: UIViewController {
    
    @IBAction func saveUserData(_ sender: Any) {
        saveAccountDetailsTokeychain(account: "a123", password: "a123")
    }
    @IBAction func authTouchID(_ sender: Any) {
        let root = RootViewController()
        self.present(root, animated: true, completion: nil)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        authenticateUserUsingTouchId()
    }
    
    fileprivate func authenticateUserUsingTouchId(){
        let context = LAContext()
        var authError: NSError?

        //判斷是否支援 touch ID
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError){
            self.evaulateTouchIdAuthenticity(context: context)
        } else {
            guard let error = authError else {
                return
            }
            showError(error: error as! LAError)
        }
    }
    
    func evaulateTouchIdAuthenticity(context: LAContext) {
        guard let lastAccessedUserName = UserDefaults.standard.object(forKey: "lastAccessedUserName") as? String else {
            return
        }
        //驗證 touch ID
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: lastAccessedUserName) { (success, error) in
            if success {
                self.loadPasswordFromKeychainAndAuthenticateUser(lastAccessedUserName)
            } else {
                if let error = error as? LAError {
                    self.showError(error: error)
                }
            }
        }
    }
    
    func evaluatePolicyFailErrorMessageForLA(error: LAError) -> String {
        var message = ""
        if #available(iOS 11.0, *) {
            switch error.code {
            case LAError.biometryNotAvailable:
                message = "Authentication could not start because the device does not support biometric authentication."
            case LAError.biometryLockout:
                message = "Authentication could not continue because the user has been locked out of biometric authentication, due to failing authentication too many times."
            case LAError.biometryNotEnrolled:
                message = "Authentication could not start because the user has not enrolled in biometric authentication."
            default:
                message = "Did not find error code on LAError object"
            }
        } else {
            switch error.code {
            case LAError.touchIDLockout:
                message = "Too many failed attempts."
            case LAError.touchIDNotAvailable:
                message = "TouchID is not available on the device"
            case LAError.touchIDNotEnrolled:
                message = "TouchID is not enrolled on the device"
            default:
                message = "Did not find error code on LAError object"
            }
            // Fallback on earlier versions
        }
        return message
    }
    
    func showError(error: LAError) {
        var message: String = ""
        switch error.code {
        case LAError.authenticationFailed:
            message = "The user failed to provide valid credentials"
            
        case LAError.appCancel:
            message = "Authentication was cancelled by application"
            
        case LAError.invalidContext:
            message = "The context is invalid"
            
        case LAError.notInteractive:
            message = "Not interactive"
            
        case LAError.passcodeNotSet:
            message = "Passcode is not set on the device"
            
        case LAError.systemCancel:
            message = "Authentication was cancelled by the system"
            
        case LAError.userCancel:
            message = "The user did cancel"
            
        case LAError.userFallback:
            message = "The user chose to use the fallback"

        default:
            message = evaluatePolicyFailErrorMessageForLA(error: error)
        }
        showAlertController(message)
    }
    
    fileprivate func loadPasswordFromKeychainAndAuthenticateUser(_ account: String) {
        guard !account.isEmpty else {
            return
        }
        let passwordItem = KeychainPasswordItem(service: KeychainConfiguration.serviceName, account: account, accessGroup: KeychainConfiguration.accessGroup)
        do {
            let storedPassword = try passwordItem.readPassword()
            print(storedPassword)
            let root = RootViewController()
            self.present(root, animated: true, completion: nil)
        } catch KeychainPasswordItem.KeychainError.noPassword {
            print("No saved password")
        } catch {
            print("Unhandled error")
        }
    }
    
    func showAlertController(_ message: String) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    fileprivate func saveAccountDetailsTokeychain(account: String, password: String) {
        //        guard account.isEmpty, password.isEmpty else {
        //            return
        //        }
        UserDefaults.standard.set(account, forKey: "lastAccessedUserName")
        let passwordItem = KeychainPasswordItem(service: KeychainConfiguration.serviceName, account: account, accessGroup: KeychainConfiguration.accessGroup)
        do {
            try passwordItem.savePassword(password)
        } catch {
            print("Error saving password")
        }
    }
}
