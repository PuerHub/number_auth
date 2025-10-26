import Flutter
import UIKit
import ATAuthSDK

public class AliyunNumberAuthPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "aliyun_number_auth", binaryMessenger: registrar.messenger())
        let instance = AliyunNumberAuthPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            guard let args = call.arguments as? [String: Any],
                  let secretInfo = args["secretInfo"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "secretInfo is required", details: nil))
                return
            }
            initialize(secretInfo: secretInfo, result: result)

        case "getVerifyToken":
            let args = call.arguments as? [String: Any]
            let timeout = args?["timeout"] as? Int ?? 5000
            getVerifyToken(timeout: timeout, result: result)

        case "accelerateVerify":
            let args = call.arguments as? [String: Any]
            let timeout = args?["timeout"] as? Int ?? 5000
            accelerateVerify(timeout: timeout, result: result)

        case "checkEnvironment":
            checkEnvironment(result: result)

        case "getAppSignatureInfo":
            getAppSignatureInfo(result: result)

        case "getLoginToken":
            let args = call.arguments as? [String: Any]
            let timeout = args?["timeout"] as? Int ?? 5000
            let config = args?["config"] as? [String: Any]
            getLoginToken(timeout: timeout, config: config, result: result)

        case "accelerateLoginPage":
            let args = call.arguments as? [String: Any]
            let timeout = args?["timeout"] as? Int ?? 5000
            accelerateLoginPage(timeout: timeout, result: result)

        case "quitLoginPage":
            quitLoginPage(result: result)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func initialize(secretInfo: String, result: @escaping FlutterResult) {
        TXCommonHandler.sharedInstance().setAuthSDKInfo(secretInfo) { resultCode, msg in
            let response: [String: Any] = [
                "code": resultCode,
                "message": msg ?? "Initialization completed"
            ]
            result(response)
        }
    }

    private func getVerifyToken(timeout: Int, result: @escaping FlutterResult) {
        TXCommonHandler.sharedInstance().getVerifyToken(withTimeout: timeout) { resultCode, msg in
            if resultCode == "600000" {
                // Success - msg contains the token
                let response: [String: Any] = [
                    "code": resultCode,
                    "message": msg ?? ""
                ]
                result(response)
            } else {
                // Failed
                let response: [String: Any] = [
                    "code": resultCode,
                    "message": msg ?? "Unknown error"
                ]
                result(response)
            }
        }
    }

    private func accelerateVerify(timeout: Int, result: @escaping FlutterResult) {
        TXCommonHandler.sharedInstance().accelerateVerify(withTimeout: timeout) { resultCode, msg in
            let response: [String: Any] = [
                "code": resultCode,
                "message": msg ?? "Accelerate verify completed"
            ]
            result(response)
        }
    }

    private func checkEnvironment(result: @escaping FlutterResult) {
        TXCommonHandler.sharedInstance().checkEnvAvailable(with: PNSAuthType.loginToken) { resultCode, msg in
            let response: [String: Any] = [
                "code": resultCode,
                "message": msg ?? "Environment check completed"
            ]
            result(response)
        }
    }

    private func getAppSignatureInfo(result: @escaping FlutterResult) {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            let response: [String: Any] = [
                "packageName": "ERROR",
                "signature": "Unable to get Bundle ID",
                "appIdentifier": NSNull()
            ]
            result(response)
            return
        }

        // Get app version and build number as additional info
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"

        let signatureInfo = "Version: \(appVersion), Build: \(buildNumber)"

        let response: [String: Any] = [
            "packageName": bundleIdentifier,
            "signature": signatureInfo,
            "appIdentifier": NSNull()
        ]
        result(response)
    }

    private func getLoginToken(timeout: Int, config: [String: Any]?, result: @escaping FlutterResult) {
        guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else {
            let response: [String: Any] = [
                "code": "NO_CONTROLLER",
                "message": "Unable to get root view controller"
            ]
            result(response)
            return
        }

        // Create authorization page UI model
        let model = TXCustomModel()

        // Default configuration
        model.navColor = UIColor(red: 0.0, green: 110.0/255.0, blue: 210.0/255.0, alpha: 1.0)

        // Apply custom UI configuration if provided
        if let config = config {
            // Logo image path
            if let logoPath = config["logoImgPath"] as? String {
                model.logoImgPath = logoPath
            }

            // Slogan text
            if let sloganText = config["sloganText"] as? String {
                model.sloganText = NSAttributedString(string: sloganText)
            }

            // Privacy agreements
            if let privacyOneTitle = config["privacyOneTitle"] as? String,
               let privacyOneUrl = config["privacyOneUrl"] as? String {
                model.privacyOne = [privacyOneTitle, privacyOneUrl]
            }

            if let privacyTwoTitle = config["privacyTwoTitle"] as? String,
               let privacyTwoUrl = config["privacyTwoUrl"] as? String {
                model.privacyTwo = [privacyTwoTitle, privacyTwoUrl]
            }

            // Login button text
            if let loginButtonText = config["loginButtonText"] as? String {
                model.loginBtnText = NSAttributedString(string: loginButtonText, attributes: [
                    .foregroundColor: UIColor.white,
                    .font: UIFont.systemFont(ofSize: 18, weight: .medium)
                ])
            } else {
                // Default login button text
                model.loginBtnText = NSAttributedString(string: "Login", attributes: [
                    .foregroundColor: UIColor.white,
                    .font: UIFont.systemFont(ofSize: 18, weight: .medium)
                ])
            }

            // Navigation title
            if let navTitle = config["navTitle"] as? String {
                model.navTitle = NSAttributedString(string: navTitle)
            } else {
                model.navTitle = NSAttributedString(string: "One-Key Login")
            }

            // Hide navigation (iOS uses navIsHidden)
            if let hideNav = config["hideNav"] as? Bool {
                model.navIsHidden = hideNav
            }

            // Hide switch account button
            if let hideSwitchButton = config["hideSwitchButton"] as? Bool {
                model.changeBtnIsHidden = hideSwitchButton
            }

            // Theme colors
            if let backgroundColorStr = config["backgroundColor"] as? String {
                if let color = hexStringToUIColor(hex: backgroundColorStr) {
                    model.authPageBackgroundImage = nil
                    // Note: SDK may require custom background image for color
                }
            }

            if let navBarColorStr = config["navBarColor"] as? String {
                if let color = hexStringToUIColor(hex: navBarColorStr) {
                    model.navColor = color
                }
            }

            if let loginButtonColorStr = config["loginButtonColor"] as? String {
                if let color = hexStringToUIColor(hex: loginButtonColorStr) {
                    model.loginBtnBgImgs = nil
                    // Note: SDK may require custom button images for color
                }
            }

            if let textColorStr = config["textColor"] as? String {
                if let color = hexStringToUIColor(hex: textColorStr) {
                    model.numberColor = color
                    // Update slogan text color
                    if let sloganText = model.sloganText?.string {
                        model.sloganText = NSAttributedString(string: sloganText, attributes: [
                            .foregroundColor: color
                        ])
                    }
                }
            }
        } else {
            // No custom config provided, use defaults
            model.navTitle = NSAttributedString(string: "One-Key Login")
            model.loginBtnText = NSAttributedString(string: "Login", attributes: [
                .foregroundColor: UIColor.white,
                .font: UIFont.systemFont(ofSize: 18, weight: .medium)
            ])
        }

        TXCommonHandler.sharedInstance().getLoginToken(withTimeout: timeout, controller: rootViewController, model: model) { resultCode, msg in
            if resultCode == "600000" {
                // Success - got token
                let response: [String: Any] = [
                    "code": resultCode,
                    "message": msg ?? ""
                ]
                result(response)
            } else {
                // Handle different result codes
                let response: [String: Any] = [
                    "code": resultCode,
                    "message": msg ?? "Login failed"
                ]
                result(response)
            }
        }
    }

    private func accelerateLoginPage(timeout: Int, result: @escaping FlutterResult) {
        TXCommonHandler.sharedInstance().accelerateLoginPage(withTimeout: timeout) { resultCode, msg in
            let response: [String: Any] = [
                "code": resultCode,
                "message": msg ?? "Accelerate login page completed"
            ]
            result(response)
        }
    }

    private func quitLoginPage(result: @escaping FlutterResult) {
        TXCommonHandler.sharedInstance().cancelLoginVC(animated: true) { resultCode, msg in
            let response: [String: Any] = [
                "code": resultCode,
                "message": msg ?? "Login page dismissed"
            ]
            result(response)
        }
    }

    /// Helper function to convert hex string to UIColor
    /// Supports formats: "0xFFFFFFFF", "#FFFFFFFF", "FFFFFFFF"
    private func hexStringToUIColor(hex: String) -> UIColor? {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "0x", with: "")
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }

        let length = hexSanitized.count
        let r, g, b, a: CGFloat

        if length == 8 {
            // ARGB format
            a = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            r = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x000000FF) / 255.0
        } else if length == 6 {
            // RGB format (assume full opacity)
            a = 1.0
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0
        } else {
            return nil
        }

        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}
