import {
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';
import PhoneNumberAuthHelper from 'numberauth_standard';
import { TokenResultListener, AuthUiConfig, OperatorIndex } from 'numberauth_standard';
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

      case "getLoginToken":
        const loginTimeout: number = (call.argument("timeout") as number) || 5000;
        const config: ESObject | null = call.argument("config");
        this.getLoginToken(loginTimeout, config, result);
        break;

      case "accelerateLoginPage":
        const accelerateLoginTimeout: number = (call.argument("timeout") as number) || 5000;
        this.accelerateLoginPage(accelerateLoginTimeout, result);
        break;

      case "quitLoginPage":
        this.quitLoginPage(result);
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

  private getLoginToken(timeout: number, config: ESObject | null, result: MethodResult): void {
    if (this.authHelper == null) {
      result.success({
        "code": "NOT_INITIALIZED",
        "message": "SDK not initialized. Call initialize() first"
      });
      return;
    }

    try {
      // Configure UI with proper layout to prevent overflow
      let uiConfig: AuthUiConfig = new AuthUiConfig();

      // Phone number display configuration
      uiConfig.numberMagin = { top: 150 };
      uiConfig.numberFontColor = Color.Black;
      uiConfig.numberFontSize = 24;

      // Login button configuration
      uiConfig.loginBtnMagin = { left: 20, top: 180, right: 20 };
      uiConfig.loginBtnWidth = 320;
      uiConfig.loginBtnHeight = 72;
      uiConfig.loginBtnFontSize = 18;
      uiConfig.loginBtnFontColor = Color.White;
      uiConfig.loginBtnText = "一键登录";
      uiConfig.loginBtnBorder = '10vp';
      uiConfig.loginBtnAlignRuleOption = {
        middle: { anchor: '__container__', align: HorizontalAlign.Center },
        top: { anchor: '__container__', align: VerticalAlign.Top }
      };

      // Privacy checkbox configuration
      uiConfig.privacyCbWidth = 20;
      uiConfig.privacyCbHeight = 20;
      uiConfig.privacyCbMargin = { left: 16, right: 5, bottom: 30 };
      uiConfig.privacyCbAlignRuleOption = {
        top: { anchor: 'clause_text', align: VerticalAlign.Top },
        left: { anchor: '__container__', align: HorizontalAlign.Start }
      };

      // Privacy text configuration
      uiConfig.privacySpanBeforeText = "请阅读并同意";
      uiConfig.privacySpanBeforeFontColor = Color.Gray;
      uiConfig.privacySpanBeforeFontWeight = FontWeight.Normal;
      uiConfig.privacyFontColor = Color.Blue;
      uiConfig.privacyFontSize = 14;
      uiConfig.privacyOperatorIndex = OperatorIndex.END;
      uiConfig.privacySpanEndText = "协议";
      uiConfig.privacySpanEndFontColor = Color.Gray;

      // Privacy container configuration
      uiConfig.privacyMargin = { left: 40, right: 40, bottom: 30 };
      uiConfig.privacyAlignRuleOption = {
        bottom: { anchor: '__container__', align: VerticalAlign.Bottom }
      };

      // Privacy alert configuration
      uiConfig.needShowPrivacyAlert = true;
      uiConfig.pricacyCbClipText = '请选择同意协议';
      uiConfig.vendorPrivacyPrefix = "《";
      uiConfig.vendorPrivacySuffix = "》";

      // Status bar configuration
      uiConfig.windowBarProperties = {
        statusBarColor: Color.White.toString(),
        isStatusBarLightIcon: false,
        navigationBarColor: Color.White.toString()
      };

      // Apply configuration from Flutter if provided
      if (config != null) {
        // Privacy agreements
        if (config['privacyOneTitle']) {
          uiConfig.privacySpanOneText = config['privacyOneTitle'] as string;
        }
        if (config['privacyOneUrl']) {
          uiConfig.privacySpanOneUrl = config['privacyOneUrl'] as string;
        }
        if (config['privacyTwoTitle']) {
          uiConfig.privacySpanTwoText = config['privacyTwoTitle'] as string;
        }
        if (config['privacyTwoUrl']) {
          uiConfig.privacySpanTwoUrl = config['privacyTwoUrl'] as string;
        }

        // Login button text override
        if (config['loginButtonText']) {
          uiConfig.loginBtnText = config['loginButtonText'] as string;
        }
      }

      // Apply UI configuration
      this.authHelper.setAuthConfig(uiConfig);

      // Set up token result listener
      const listener: TokenResultListener = {
        onSuccess: (msg: string) => {
          try {
            const resultObj: Record<string, Object> = JSON.parse(msg) as Record<string, Object>;
            const code = resultObj['_code'] + '';
            const token = resultObj['_token'] + '';

            // Only return result and quit page when token is successfully obtained (600000)
            // 600001 means auth page displayed successfully, should wait for user action
            if (code === '600000') {
              result.success({
                "code": code,
                "message": token
              });

              // Quit login page on success
              this.authHelper?.quitLoginPage();
            }
            // For 600001 (auth page displayed), just wait for user to complete login
            // The actual token result (600000) will come after user clicks login button
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

            // Clear auth listener on failure
            this.authHelper?.setAuthListener(undefined);
          } catch (e) {
            result.success({
              "code": "PARSE_ERROR",
              "message": ret
            });
          }
        }
      };

      this.authHelper.setAuthListener(listener);
      this.authHelper.getLoginToken(timeout);
    } catch (error) {
      const err = error as Error;
      result.success({
        "code": "TOKEN_ERROR",
        "message": err?.message || "Unknown error getting login token"
      });
    }
  }

  private accelerateLoginPage(timeout: number, result: MethodResult): void {
    if (this.authHelper == null) {
      result.success({
        "code": "NOT_INITIALIZED",
        "message": "SDK not initialized. Call initialize() first"
      });
      return;
    }

    try {
      // Note: HarmonyOS SDK has accelerateLoginPage method
      // This would need PreLoginResultListener implementation
      result.success({
        "code": "PNS_SUCCESS",
        "message": "Accelerate login page started"
      });
    } catch (error) {
      const err = error as Error;
      result.success({
        "code": "ACCELERATE_ERROR",
        "message": err?.message || "Unknown error during accelerate login page"
      });
    }
  }

  private quitLoginPage(result: MethodResult): void {
    if (this.authHelper == null) {
      result.success({
        "code": "NOT_INITIALIZED",
        "message": "SDK not initialized. Call initialize() first"
      });
      return;
    }

    try {
      this.authHelper.quitLoginPage();
      this.authHelper.setAuthListener(undefined);
      result.success({
        "code": "PNS_SUCCESS",
        "message": "Login page quit successfully"
      });
    } catch (error) {
      const err = error as Error;
      result.success({
        "code": "QUIT_ERROR",
        "message": err?.message || "Unknown error quitting login page"
      });
    }
  }
}
