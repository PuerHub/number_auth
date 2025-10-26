import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'aliyun_number_auth.dart';
import 'aliyun_number_auth_ui_config.dart';
import 'aliyun_number_auth_platform_interface.dart';

/// Callback type for auth page UI click events
typedef AuthPageClickCallback = void Function(String code, String jsonString);

/// An implementation of [AliyunNumberAuthPlatform] that uses method channels.
class MethodChannelAliyunNumberAuth extends AliyunNumberAuthPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('aliyun_number_auth');

  /// Callback for auth page UI click events
  AuthPageClickCallback? _authPageClickCallback;

  MethodChannelAliyunNumberAuth() {
    // Set up method call handler for callbacks from native side
    methodChannel.setMethodCallHandler(_handleMethodCall);
  }

  /// Handle method calls from native platform
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onAuthPageClick':
        final arguments = call.arguments as Map<Object?, Object?>;
        final code = arguments['code'] as String? ?? '';
        final jsonString = arguments['jsonString'] as String? ?? '';
        _authPageClickCallback?.call(code, jsonString);
        break;
      default:
        break;
    }
  }

  /// Set callback for auth page UI click events
  void setAuthPageClickCallback(AuthPageClickCallback? callback) {
    _authPageClickCallback = callback;
  }

  /// Common method to invoke platform methods and handle errors
  Future<AliyunNumberAuthResult> _invokeMethod(
    String method, [
    Map<String, dynamic>? arguments,
  ]) async {
    try {
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
        method,
        arguments,
      );
      return _parseResult(result);
    } on PlatformException catch (e) {
      return AliyunNumberAuthResult(
        code: e.code,
        message: e.message ?? 'Unknown error',
      );
    }
  }

  @override
  Future<AliyunNumberAuthResult> initialize(String secretInfo) =>
      _invokeMethod('initialize', {'secretInfo': secretInfo});

  @override
  Future<AliyunNumberAuthResult> getVerifyToken(int timeout) =>
      _invokeMethod('getVerifyToken', {'timeout': timeout});

  @override
  Future<AliyunNumberAuthResult> accelerateVerify(int timeout) =>
      _invokeMethod('accelerateVerify', {'timeout': timeout});

  @override
  Future<AliyunNumberAuthResult> checkEnvironment() =>
      _invokeMethod('checkEnvironment');

  @override
  Future<AliyunNumberAuthResult> accelerateLoginPage(int timeout) =>
      _invokeMethod('accelerateLoginPage', {'timeout': timeout});

  @override
  Future<AliyunNumberAuthResult> quitLoginPage() =>
      _invokeMethod('quitLoginPage');

  @override
  Future<AppSignatureInfo> getAppSignatureInfo() async {
    try {
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
        'getAppSignatureInfo',
      );
      return _parseSignatureInfo(result);
    } on PlatformException catch (e) {
      return AppSignatureInfo(
        packageName: 'Error: ${e.code}',
        signature: e.message ?? 'Unknown error',
      );
    }
  }

  AliyunNumberAuthResult _parseResult(Map<Object?, Object?>? result) {
    if (result == null) {
      return const AliyunNumberAuthResult(
        code: 'UNKNOWN_ERROR',
        message: 'No result returned',
      );
    }

    final code = result['code'] as String? ?? 'UNKNOWN_ERROR';
    final message = result['message'] as String? ?? '';

    return AliyunNumberAuthResult(code: code, message: message);
  }

  AppSignatureInfo _parseSignatureInfo(Map<Object?, Object?>? result) {
    if (result == null) {
      return const AppSignatureInfo(
        packageName: 'ERROR',
        signature: 'No result returned',
      );
    }

    return AppSignatureInfo(
      packageName: result['packageName'] as String? ?? '',
      signature: result['signature'] as String? ?? '',
      appIdentifier: result['appIdentifier'] as String?,
    );
  }

  @override
  Future<AliyunNumberAuthResult> getLoginToken(
    int timeout,
    AliyunNumberAuthUIConfig? config,
  ) async {
    try {
      final arguments = <String, dynamic>{
        'timeout': timeout,
        if (config != null) 'config': config.toMap(),
      };

      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
        'getLoginToken',
        arguments,
      );
      return _parseResult(result);
    } on PlatformException catch (e) {
      return AliyunNumberAuthResult(
        code: e.code,
        message: e.message ?? 'Unknown error',
      );
    }
  }
}
