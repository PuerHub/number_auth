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
}
