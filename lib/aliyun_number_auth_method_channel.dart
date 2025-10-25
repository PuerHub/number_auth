import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'aliyun_number_auth.dart';
import 'aliyun_number_auth_platform_interface.dart';

/// An implementation of [AliyunNumberAuthPlatform] that uses method channels.
class MethodChannelAliyunNumberAuth extends AliyunNumberAuthPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('aliyun_number_auth');

  @override
  Future<AliyunNumberAuthResult> initialize(String secretInfo) async {
    try {
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
        'initialize',
        {'secretInfo': secretInfo},
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
  Future<AliyunNumberAuthResult> getVerifyToken(int timeout) async {
    try {
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
        'getVerifyToken',
        {'timeout': timeout},
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
  Future<AliyunNumberAuthResult> accelerateVerify(int timeout) async {
    try {
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
        'accelerateVerify',
        {'timeout': timeout},
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
  Future<AliyunNumberAuthResult> checkEnvironment() async {
    try {
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
        'checkEnvironment',
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
      return AliyunNumberAuthResult(
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
      return AppSignatureInfo(
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
}
