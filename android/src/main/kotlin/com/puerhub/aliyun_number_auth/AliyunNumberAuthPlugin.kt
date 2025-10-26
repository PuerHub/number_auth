package com.puerhub.aliyun_number_auth

import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.content.pm.Signature
import android.os.Build
import com.mobile.auth.gatewayauth.PhoneNumberAuthHelper
import com.mobile.auth.gatewayauth.PreLoginResultListener
import com.mobile.auth.gatewayauth.ResultCode
import com.mobile.auth.gatewayauth.TokenResultListener
import com.mobile.auth.gatewayauth.model.TokenRet
import com.mobile.auth.gatewayauth.AuthUIConfig
import com.mobile.auth.gatewayauth.AuthUIControlClickListener
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.security.MessageDigest

/** AliyunNumberAuthPlugin */
class AliyunNumberAuthPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var activity: Activity? = null
    private var authHelper: PhoneNumberAuthHelper? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "aliyun_number_auth")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initialize" -> {
                val secretInfo = call.argument<String>("secretInfo")
                if (secretInfo == null) {
                    result.error("INVALID_ARGUMENT", "secretInfo is required", null)
                    return
                }
                initialize(secretInfo, result)
            }
            "getVerifyToken" -> {
                val timeout = call.argument<Int>("timeout") ?: 5000
                getVerifyToken(timeout, result)
            }
            "accelerateVerify" -> {
                val timeout = call.argument<Int>("timeout") ?: 5000
                accelerateVerify(timeout, result)
            }
            "checkEnvironment" -> {
                checkEnvironment(result)
            }
            "getAppSignatureInfo" -> {
                getAppSignatureInfo(result)
            }
            "getLoginToken" -> {
                val timeout = call.argument<Int>("timeout") ?: 5000
                val config = call.argument<Map<String, Any?>>("config")
                getLoginToken(timeout, config, result)
            }
            "accelerateLoginPage" -> {
                val timeout = call.argument<Int>("timeout") ?: 5000
                accelerateLoginPage(timeout, result)
            }
            "quitLoginPage" -> {
                quitLoginPage(result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun initialize(secretInfo: String, result: Result) {
        try {
            // Debug: Print secret info details
            android.util.Log.d("AliyunNumberAuth", "Initializing with secret info length: ${secretInfo.length}")
            android.util.Log.d("AliyunNumberAuth", "Secret info starts with: ${secretInfo.take(20)}...")

            // Debug: Print current app signature
            try {
                val packageName = context.packageName
                val packageManager = context.packageManager
                val signatures: Array<Signature>? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    val packageInfo = packageManager.getPackageInfo(
                        packageName,
                        PackageManager.GET_SIGNING_CERTIFICATES
                    )
                    packageInfo.signingInfo?.apkContentsSigners
                } else {
                    @Suppress("DEPRECATION")
                    val packageInfo = packageManager.getPackageInfo(
                        packageName,
                        PackageManager.GET_SIGNATURES
                    )
                    @Suppress("DEPRECATION")
                    packageInfo.signatures
                }

                if (signatures != null && signatures.isNotEmpty()) {
                    val signature = signatures[0]
                    val md = MessageDigest.getInstance("MD5")
                    md.update(signature.toByteArray())
                    val digest = md.digest()
                    val hexString = StringBuilder()
                    for (byte in digest) {
                        val hex = Integer.toHexString(0xFF and byte.toInt())
                        if (hex.length == 1) {
                            hexString.append('0')
                        }
                        hexString.append(hex)
                    }
                    android.util.Log.d("AliyunNumberAuth", "Current app signature (MD5): ${hexString.toString()}")
                }
            } catch (e: Exception) {
                android.util.Log.e("AliyunNumberAuth", "Failed to get signature for debug: ${e.message}")
            }

            authHelper = PhoneNumberAuthHelper.getInstance(context, object : TokenResultListener {
                override fun onTokenSuccess(token: String) {
                    // This callback is for getVerifyToken, not initialize
                }

                override fun onTokenFailed(code: String) {
                    // This callback is for getVerifyToken, not initialize
                }
            })

            authHelper?.setAuthSDKInfo(secretInfo)

            result.success(
                mapOf(
                    "code" to ResultCode.CODE_SUCCESS,
                    "message" to "Initialization successful"
                )
            )
        } catch (e: Exception) {
            android.util.Log.e("AliyunNumberAuth", "Initialization error: ${e.message}", e)
            result.success(
                mapOf(
                    "code" to "INIT_ERROR",
                    "message" to (e.message ?: "Unknown error during initialization")
                )
            )
        }
    }

    private fun getVerifyToken(timeout: Int, result: Result) {
        if (authHelper == null) {
            result.success(
                mapOf(
                    "code" to "NOT_INITIALIZED",
                    "message" to "SDK not initialized. Call initialize() first"
                )
            )
            return
        }

        try {
            authHelper?.setAuthListener(object : TokenResultListener {
                override fun onTokenSuccess(token: String) {
                    result.success(
                        mapOf(
                            "code" to ResultCode.CODE_SUCCESS,
                            "message" to token
                        )
                    )
                }

                override fun onTokenFailed(code: String) {
                    result.success(
                        mapOf(
                            "code" to code,
                            "message" to "Token verification failed"
                        )
                    )
                }
            })

            authHelper?.getVerifyToken(timeout)
        } catch (e: Exception) {
            result.success(
                mapOf(
                    "code" to "TOKEN_ERROR",
                    "message" to (e.message ?: "Unknown error getting token")
                )
            )
        }
    }

    private fun accelerateVerify(timeout: Int, result: Result) {
        if (authHelper == null) {
            result.success(
                mapOf(
                    "code" to "NOT_INITIALIZED",
                    "message" to "SDK not initialized. Call initialize() first"
                )
            )
            return
        }

        try {
            authHelper?.accelerateVerify(timeout, object : PreLoginResultListener {
                override fun onTokenSuccess(vendorName: String) {
                    result.success(
                        mapOf(
                            "code" to ResultCode.CODE_SUCCESS,
                            "message" to "Accelerate verify successful: $vendorName"
                        )
                    )
                }

                override fun onTokenFailed(vendorName: String, code: String) {
                    result.success(
                        mapOf(
                            "code" to code,
                            "message" to "$vendorName: Accelerate verify failed"
                        )
                    )
                }
            })
        } catch (e: Exception) {
            result.success(
                mapOf(
                    "code" to "ACCELERATE_ERROR",
                    "message" to (e.message ?: "Unknown error during accelerate verify")
                )
            )
        }
    }

    private fun checkEnvironment(result: Result) {
        if (authHelper == null) {
            result.success(
                mapOf(
                    "code" to "NOT_INITIALIZED",
                    "message" to "SDK not initialized. Call initialize() first"
                )
            )
            return
        }

        try {
            authHelper?.checkEnvAvailable(PhoneNumberAuthHelper.SERVICE_TYPE_AUTH)

            result.success(
                mapOf(
                    "code" to ResultCode.CODE_SUCCESS,
                    "message" to "Environment check initiated"
                )
            )
        } catch (e: Exception) {
            result.success(
                mapOf(
                    "code" to "ENV_CHECK_ERROR",
                    "message" to (e.message ?: "Unknown error checking environment")
                )
            )
        }
    }

    private fun getAppSignatureInfo(result: Result) {
        try {
            val packageName = context.packageName
            val packageManager = context.packageManager

            val signatures: Array<Signature>? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                val packageInfo = packageManager.getPackageInfo(
                    packageName,
                    PackageManager.GET_SIGNING_CERTIFICATES
                )
                packageInfo.signingInfo?.apkContentsSigners
            } else {
                @Suppress("DEPRECATION")
                val packageInfo = packageManager.getPackageInfo(
                    packageName,
                    PackageManager.GET_SIGNATURES
                )
                @Suppress("DEPRECATION")
                packageInfo.signatures
            }

            if (signatures != null && signatures.isNotEmpty()) {
                val signature = signatures[0]
                val md = MessageDigest.getInstance("MD5")
                md.update(signature.toByteArray())
                val digest = md.digest()

                // Convert to hex string (lowercase, without colons)
                val hexString = StringBuilder()
                for (byte in digest) {
                    val hex = Integer.toHexString(0xFF and byte.toInt())
                    if (hex.length == 1) {
                        hexString.append('0')
                    }
                    hexString.append(hex)
                }

                result.success(
                    mapOf(
                        "packageName" to packageName,
                        "signature" to hexString.toString(),
                        "appIdentifier" to null
                    )
                )
            } else {
                result.success(
                    mapOf(
                        "packageName" to packageName,
                        "signature" to "No signature found",
                        "appIdentifier" to null
                    )
                )
            }
        } catch (e: Exception) {
            result.success(
                mapOf(
                    "packageName" to "ERROR",
                    "signature" to (e.message ?: "Unknown error getting app signature"),
                    "appIdentifier" to null
                )
            )
        }
    }

    private fun getLoginToken(timeout: Int, config: Map<String, Any?>?, result: Result) {
        if (authHelper == null) {
            result.success(
                mapOf(
                    "code" to "NOT_INITIALIZED",
                    "message" to "SDK not initialized. Call initialize() first"
                )
            )
            return
        }

        if (activity == null) {
            result.success(
                mapOf(
                    "code" to "NO_ACTIVITY",
                    "message" to "Activity not available"
                )
            )
            return
        }

        try {
            // Get screen dimensions
            val displayMetrics = context.resources.displayMetrics
            val screenWidthDp = displayMetrics.widthPixels / displayMetrics.density
            val screenHeightDp = displayMetrics.heightPixels / displayMetrics.density

            // Dialog mode configuration (80% width, 65% height)
            val dialogWidth = (screenWidthDp * 0.8f).toInt()
            val dialogHeight = (screenHeightDp * 0.65f).toInt()

            // Configure dialog mode UI
            val builder = AuthUIConfig.Builder()
                // Dialog mode settings (setting width/height > 0 enables dialog mode)
                .setDialogWidth(dialogWidth)
                .setDialogHeight(dialogHeight)
                .setDialogBottom(false)  // Center position, not bottom
                .setDialogOffsetX(0)
                .setDialogOffsetY(0)
                // Interaction settings
                .setTapAuthPageMaskClosePage(true)  // Click outside to close

            // Apply custom UI configuration if provided
            if (config != null) {
                // Logo image path
                // Convert Flutter asset path to Android drawable resource name
                val logoPath = config["logoImgPath"] as? String
                if (logoPath != null) {
                    // Extract filename without extension from Flutter asset path
                    // e.g., "assets/logo.png" -> "logo"
                    val logoName = logoPath.substringAfterLast("/").substringBeforeLast(".")
                    builder.setLogoImgPath(logoName)
                }

                // Slogan text
                val sloganText = config["sloganText"] as? String
                if (sloganText != null) {
                    builder.setSloganText(sloganText)
                }

                // Privacy agreement one
                val privacyOneTitle = config["privacyOneTitle"] as? String
                val privacyOneUrl = config["privacyOneUrl"] as? String
                if (privacyOneTitle != null && privacyOneUrl != null) {
                    builder.setAppPrivacyOne(privacyOneTitle, privacyOneUrl)
                }

                // Privacy agreement two
                val privacyTwoTitle = config["privacyTwoTitle"] as? String
                val privacyTwoUrl = config["privacyTwoUrl"] as? String
                if (privacyTwoTitle != null && privacyTwoUrl != null) {
                    builder.setAppPrivacyTwo(privacyTwoTitle, privacyTwoUrl)
                }

                // Login button text
                val loginButtonText = config["loginButtonText"] as? String
                if (loginButtonText != null) {
                    builder.setLogBtnText(loginButtonText)
                }

                // Navigation title
                val navTitle = config["navTitle"] as? String
                if (navTitle != null) {
                    builder.setNavText(navTitle)
                }

                // Hide navigation
                val hideNav = config["hideNav"] as? Boolean
                builder.setNavHidden(hideNav ?: true)

                // Hide switch account button
                val hideSwitchButton = config["hideSwitchButton"] as? Boolean
                builder.setSwitchAccHidden(hideSwitchButton ?: true)

                // Theme colors
                // Navigation bar color
                val navBarColor = config["navBarColor"] as? String
                if (navBarColor != null) {
                    try {
                        val color = android.graphics.Color.parseColor(
                            navBarColor.replace("0x", "#")
                        )
                        builder.setNavColor(color)
                        builder.setStatusBarColor(color)
                    } catch (e: Exception) {
                        // Ignore invalid color
                    }
                }

                // Text colors
                val textColor = config["textColor"] as? String
                if (textColor != null) {
                    try {
                        val color = android.graphics.Color.parseColor(
                            textColor.replace("0x", "#")
                        )
                        builder.setNumberColor(color)
                        builder.setSloganTextColor(color)
                        builder.setLogBtnTextColor(color)
                    } catch (e: Exception) {
                        // Ignore invalid color
                    }
                }

                // Login button color
                val loginButtonColor = config["loginButtonColor"] as? String
                if (loginButtonColor != null) {
                    try {
                        val color = android.graphics.Color.parseColor(
                            loginButtonColor.replace("0x", "#")
                        )
                        builder.setLogBtnBackgroundPath("authsdk_dialog_login_btn_bg")
                    } catch (e: Exception) {
                        // Ignore invalid color
                    }
                }

                // Background color - using light/dark mode indicator
                val backgroundColor = config["backgroundColor"] as? String
                if (backgroundColor != null) {
                    try {
                        val colorValue = backgroundColor.replace("0x", "#")
                        val color = android.graphics.Color.parseColor(colorValue)
                        // Set light color mode based on background brightness
                        val brightness = (android.graphics.Color.red(color) * 299 +
                                android.graphics.Color.green(color) * 587 +
                                android.graphics.Color.blue(color) * 114) / 1000
                        builder.setLightColor(brightness > 128)
                    } catch (e: Exception) {
                        // Ignore invalid color
                    }
                }
            } else {
                // No custom config provided, use defaults
                builder.setNavHidden(true)
                builder.setSwitchAccHidden(true)
            }

            val uiConfig = builder.create()
            authHelper?.setAuthUIConfig(uiConfig)

            // Set UI click listener to capture user interactions on auth page
            authHelper?.setUIClickListener(object : AuthUIControlClickListener {
                override fun onClick(code: String, context: Context, jsonString: String) {
                    // Send callback to Flutter with code and jsonString
                    activity?.runOnUiThread {
                        channel.invokeMethod("onAuthPageClick", mapOf(
                            "code" to code,
                            "jsonString" to jsonString
                        ))
                    }
                }
            })

            authHelper?.setAuthListener(object : TokenResultListener {
                override fun onTokenSuccess(token: String) {
                    // Parse the token result
                    // The token parameter could be:
                    // 1. A TokenRet JSON string with code field (e.g., {"code":"600001"} for page displayed)
                    // 2. The actual token string (when code is 600000)

                    try {
                        // Try to parse as JSON to check if it contains a code
                        val tokenRet = TokenRet.fromJson(token)

                        if (tokenRet.code == "600001") {
                            // Authorization page displayed successfully - don't close it yet
                            // User needs to click the login button
                            return
                        }

                        // For other success codes (like 600000 - token obtained)
                        // Close the authorization page
                        authHelper?.quitLoginPage()

                        result.success(
                            mapOf(
                                "code" to (tokenRet.code ?: ResultCode.CODE_SUCCESS),
                                "message" to (tokenRet.token ?: token)
                            )
                        )
                    } catch (e: Exception) {
                        // If parsing fails, assume it's the token string itself
                        authHelper?.quitLoginPage()

                        result.success(
                            mapOf(
                                "code" to ResultCode.CODE_SUCCESS,
                                "message" to token
                            )
                        )
                    }
                }

                override fun onTokenFailed(code: String) {
                    // Close the authorization page on failure
                    authHelper?.quitLoginPage()

                    result.success(
                        mapOf(
                            "code" to code,
                            "message" to "Login failed"
                        )
                    )
                }
            })

            authHelper?.getLoginToken(activity, timeout)
        } catch (e: Exception) {
            result.success(
                mapOf(
                    "code" to "LOGIN_ERROR",
                    "message" to (e.message ?: "Unknown error getting login token")
                )
            )
        }
    }

    private fun accelerateLoginPage(timeout: Int, result: Result) {
        if (authHelper == null) {
            result.success(
                mapOf(
                    "code" to "NOT_INITIALIZED",
                    "message" to "SDK not initialized. Call initialize() first"
                )
            )
            return
        }

        try {
            authHelper?.accelerateLoginPage(timeout, object : PreLoginResultListener {
                override fun onTokenSuccess(vendorName: String) {
                    result.success(
                        mapOf(
                            "code" to ResultCode.CODE_SUCCESS,
                            "message" to "Accelerate login page successful: $vendorName"
                        )
                    )
                }

                override fun onTokenFailed(vendorName: String, code: String) {
                    result.success(
                        mapOf(
                            "code" to code,
                            "message" to "$vendorName: Accelerate login page failed"
                        )
                    )
                }
            })
        } catch (e: Exception) {
            result.success(
                mapOf(
                    "code" to "ACCELERATE_ERROR",
                    "message" to (e.message ?: "Unknown error during accelerate login page")
                )
            )
        }
    }

    private fun quitLoginPage(result: Result) {
        try {
            authHelper?.quitLoginPage()
            result.success(
                mapOf(
                    "code" to ResultCode.CODE_SUCCESS,
                    "message" to "Login page dismissed"
                )
            )
        } catch (e: Exception) {
            result.success(
                mapOf(
                    "code" to "QUIT_ERROR",
                    "message" to (e.message ?: "Unknown error quitting login page")
                )
            )
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        authHelper?.setAuthListener(null)
        authHelper = null
    }
}
