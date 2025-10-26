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
    companion object {
        private val EMPTY_TOKEN_LISTENER = object : TokenResultListener {
            override fun onTokenSuccess(token: String) {}
            override fun onTokenFailed(code: String) {}
        }
    }

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

    // MARK: - Helper Methods

    /**
     * Get app signature MD5 hash
     * @return MD5 hash string (lowercase, no colons) or null if error
     */
    private fun getSignatureMD5(): String? {
        return try {
            val packageName = context.packageName
            val packageManager = context.packageManager

            val signatures: Array<Signature>? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNING_CERTIFICATES)
                    .signingInfo?.apkContentsSigners
            } else {
                @Suppress("DEPRECATION")
                packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNATURES).signatures
            }

            signatures?.firstOrNull()?.let { signature ->
                MessageDigest.getInstance("MD5")
                    .digest(signature.toByteArray())
                    .joinToString("") { "%02x".format(it) }
            }
        } catch (e: Exception) {
            null
        }
    }

    /**
     * Parse color string to Android Color int
     * Supports formats: "0xFFFFFFFF", "#FFFFFFFF"
     * @return Color int or null if invalid
     */
    private fun parseColor(colorStr: String?): Int? {
        return colorStr?.let {
            try {
                android.graphics.Color.parseColor(it.replace("0x", "#"))
            } catch (e: Exception) {
                null
            }
        }
    }

    /**
     * Calculate brightness of a color (0-255)
     * Used to determine if light or dark mode should be used
     */
    private fun getColorBrightness(color: Int): Int {
        return (android.graphics.Color.red(color) * 299 +
                android.graphics.Color.green(color) * 587 +
                android.graphics.Color.blue(color) * 114) / 1000
    }

    /**
     * Check if authHelper is initialized, return error if not
     * @return true if initialized, false if not (and sends error to result)
     */
    private fun requireAuthHelper(result: Result): Boolean {
        if (authHelper == null) {
            result.success(
                mapOf(
                    "code" to "NOT_INITIALIZED",
                    "message" to "SDK not initialized. Call initialize() first"
                )
            )
            return false
        }
        return true
    }

    // MARK: - SDK Methods

    private fun initialize(secretInfo: String, result: Result) {
        try {
            authHelper = PhoneNumberAuthHelper.getInstance(context, EMPTY_TOKEN_LISTENER)
            authHelper?.setAuthSDKInfo(secretInfo)

            result.success(
                mapOf(
                    "code" to ResultCode.CODE_SUCCESS,
                    "message" to "Initialization successful"
                )
            )
        } catch (e: Exception) {
            result.success(
                mapOf(
                    "code" to "INIT_ERROR",
                    "message" to (e.message ?: "Unknown error during initialization")
                )
            )
        }
    }

    private fun getVerifyToken(timeout: Int, result: Result) {
        if (!requireAuthHelper(result)) return

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
        if (!requireAuthHelper(result)) return

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
        if (!requireAuthHelper(result)) return

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
            val signature = getSignatureMD5() ?: "No signature found"

            result.success(
                mapOf(
                    "packageName" to packageName,
                    "signature" to signature,
                    "appIdentifier" to null
                )
            )
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
        if (!requireAuthHelper(result)) return

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
                val logoPath = config["logoImgPath"] as? String
                if (logoPath != null) {
                    // Extract filename without extension from Flutter asset path
                    // e.g., "assets/logo.png" -> "logo"
                    val logoName = logoPath.substringAfterLast("/").substringBeforeLast(".")
                    builder.setLogoImgPath(logoName)
                }

                // Slogan text
                config["sloganText"]?.let { builder.setSloganText(it as String) }

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
                config["loginButtonText"]?.let { builder.setLogBtnText(it as String) }

                // Navigation title
                config["navTitle"]?.let { builder.setNavText(it as String) }

                // Hide navigation
                builder.setNavHidden(config["hideNav"] as? Boolean ?: true)

                // Hide switch account button
                builder.setSwitchAccHidden(config["hideSwitchButton"] as? Boolean ?: true)

                // Theme colors
                parseColor(config["navBarColor"] as? String)?.let { color ->
                    builder.setNavColor(color).setStatusBarColor(color)
                }

                parseColor(config["textColor"] as? String)?.let { color ->
                    builder.setNumberColor(color)
                        .setSloganTextColor(color)
                        .setLogBtnTextColor(color)
                }

                parseColor(config["backgroundColor"] as? String)?.let { color ->
                    builder.setLightColor(getColorBrightness(color) > 128)
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
        if (!requireAuthHelper(result)) return

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
