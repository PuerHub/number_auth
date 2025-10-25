import {
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';
import PhoneNumberAuthHelper from 'numberauth_standard';
import { TokenResultListener } from 'numberauth_standard';
import { common, bundleManager } from '@kit.AbilityKit';

/** AliyunNumberAuthPlugin **/
export default class AliyunNumberAuthPlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;
  private context: common.UIAbilityContext | null = null;
  private authHelper: PhoneNumberAuthHelper | null = null;

  constructor() {
  }

  getUniqueClassName(): string {
    return "AliyunNumberAuthPlugin"
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), "aliyun_number_auth");
    this.channel.setMethodCallHandler(this);
    this.context = binding.getApplicationContext() as common.UIAbilityContext;
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null);
    }
    if (this.authHelper != null) {
      this.authHelper.clearAuthListener();
      this.authHelper = null;
    }
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    switch (call.method) {
      case "initialize":
        const secretInfo: string | null = call.argument("secretInfo");
        if (!secretInfo) {
          result.error("INVALID_ARGUMENT", "secretInfo is required", null);
          return;
        }
        this.initialize(secretInfo as string, result);
        break;

      case "getVerifyToken":
        const timeout: number = (call.argument("timeout") as number) || 5000;
        this.getVerifyToken(timeout, result);
        break;

      case "accelerateVerify":
        const accelerateTimeout: number = (call.argument("timeout") as number) || 5000;
        this.accelerateVerify(accelerateTimeout, result);
        break;

      case "checkEnvironment":
        this.checkEnvironment(result);
        break;

      case "getAppSignatureInfo":
        this.getAppSignatureInfo(result);
        break;

      default:
        result.notImplemented();
    }
  }

  private initialize(secretInfo: string, result: MethodResult): void {
    try {
      if (this.context == null) {
        result.success({
          "code": "CONTEXT_ERROR",
          "message": "Application context not available"
        });
        return;
      }

      const listener: TokenResultListener = {
        onSuccess: (msg: string) => {
          // This callback is for getVerifyToken, not initialize
        },
        onFailure: (ret: string) => {
          // This callback is for getVerifyToken, not initialize
        }
      };

      this.authHelper = PhoneNumberAuthHelper.getInstance(this.context, listener);
      this.authHelper.setAuthSDKInfo(secretInfo);

      result.success({
        "code": "PNS_SUCCESS",
        "message": "Initialization successful"
      });
    } catch (error) {
      const err = error as Error;
      result.success({
        "code": "INIT_ERROR",
        "message": err?.message || "Unknown error during initialization"
      });
    }
  }

  private getVerifyToken(timeout: number, result: MethodResult): void {
    if (this.authHelper == null) {
      result.success({
        "code": "NOT_INITIALIZED",
        "message": "SDK not initialized. Call initialize() first"
      });
      return;
    }

    try {
      const listener: TokenResultListener = {
        onSuccess: (msg: string) => {
          try {
            const resultObj: Record<string, Object> = JSON.parse(msg) as Record<string, Object>;
            const code = resultObj['_code'] + '';
            const token = resultObj['_token'] + '';
            result.success({
              "code": code,
              "message": token
            });
          } catch (e) {
            result.success({
              "code": "PARSE_ERROR",
              "message": msg
            });
          }
        },
        onFailure: (ret: string) => {
          try {
            const resultObj: Record<string, Object> = JSON.parse(ret) as Record<string, Object>;
            const code = resultObj['_code'] + '';
            const message = resultObj['_msg'] + '';
            result.success({
              "code": code,
              "message": message
            });
          } catch (e) {
            result.success({
              "code": "PARSE_ERROR",
              "message": ret
            });
          }
        }
      };

      this.authHelper.setAuthListener(listener);
      this.authHelper.getVerifyToken(timeout);
    } catch (error) {
      const err = error as Error;
      result.success({
        "code": "TOKEN_ERROR",
        "message": err?.message || "Unknown error getting token"
      });
    }
  }

  private accelerateVerify(timeout: number, result: MethodResult): void {
    if (this.authHelper == null) {
      result.success({
        "code": "NOT_INITIALIZED",
        "message": "SDK not initialized. Call initialize() first"
      });
      return;
    }

    try {
      // Note: Harmony SDK might not have accelerateVerify method
      // This is a placeholder implementation
      result.success({
        "code": "PNS_SUCCESS",
        "message": "Accelerate verify not supported on HarmonyOS"
      });
    } catch (error) {
      const err = error as Error;
      result.success({
        "code": "ACCELERATE_ERROR",
        "message": err?.message || "Unknown error during accelerate verify"
      });
    }
  }

  private checkEnvironment(result: MethodResult): void {
    if (this.authHelper == null) {
      result.success({
        "code": "NOT_INITIALIZED",
        "message": "SDK not initialized. Call initialize() first"
      });
      return;
    }

    try {
      // Note: Harmony SDK might not have checkEnvironment method
      // This is a placeholder implementation
      result.success({
        "code": "PNS_SUCCESS",
        "message": "Environment check not supported on HarmonyOS"
      });
    } catch (error) {
      const err = error as Error;
      result.success({
        "code": "ENV_CHECK_ERROR",
        "message": err?.message || "Unknown error checking environment"
      });
    }
  }

  private getAppSignatureInfo(result: MethodResult): void {
    try {
      bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_SIGNATURE_INFO)
        .then((bundleInfo) => {
          const packageName = bundleInfo.name;
          const signature = bundleInfo.signatureInfo.fingerprint;
          const appIdentifier = bundleInfo.signatureInfo.appIdentifier;

          result.success({
            "packageName": packageName,
            "signature": signature,
            "appIdentifier": appIdentifier
          });
        })
        .catch((error: Error) => {
          result.success({
            "packageName": "ERROR",
            "signature": error?.message || "Failed to get bundle info",
            "appIdentifier": ""
          });
        });
    } catch (error) {
      const err = error as Error;
      result.success({
        "packageName": "ERROR",
        "signature": err?.message || "Unknown error getting app signature info",
        "appIdentifier": ""
      });
    }
  }
}
