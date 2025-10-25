package com.puerhub.aliyun_number_auth

import android.content.Context
import android.content.pm.PackageManager
import android.content.pm.Signature
import android.os.Build
import com.mobile.auth.gatewayauth.PhoneNumberAuthHelper
import com.mobile.auth.gatewayauth.PreLoginResultListener
import com.mobile.auth.gatewayauth.ResultCode
import com.mobile.auth.gatewayauth.TokenResultListener
import com.mobile.auth.gatewayauth.model.TokenRet
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.security.MessageDigest

/** AliyunNumberAuthPlugin */
class AliyunNumberAuthPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
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
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun initialize(secretInfo: String, result: Result) {
        try {
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
                    val msg = TokenRet.fromCode(code)?.msg ?: "Unknown error"
                    result.success(
                        mapOf(
                            "code" to code,
                            "message" to msg
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
                    val msg = TokenRet.fromCode(code)?.msg ?: "Unknown error"
                    result.success(
                        mapOf(
                            "code" to code,
                            "message" to "$vendorName: $msg"
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

            val signatures: Array<Signature> = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                val packageInfo = packageManager.getPackageInfo(
                    packageName,
                    PackageManager.GET_SIGNING_CERTIFICATES
                )
                packageInfo.signingInfo.apkContentsSigners
            } else {
                @Suppress("DEPRECATION")
                val packageInfo = packageManager.getPackageInfo(
                    packageName,
                    PackageManager.GET_SIGNATURES
                )
                @Suppress("DEPRECATION")
                packageInfo.signatures
            }

            if (signatures.isNotEmpty()) {
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

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        authHelper?.clearAuthListener()
        authHelper = null
    }
}
