import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'aliyun_number_auth.dart';
import 'aliyun_number_auth_method_channel.dart';

abstract class AliyunNumberAuthPlatform extends PlatformInterface {
  /// Constructs a AliyunNumberAuthPlatform.
  AliyunNumberAuthPlatform() : super(token: _token);

  static final Object _token = Object();

  static AliyunNumberAuthPlatform _instance = MethodChannelAliyunNumberAuth();

  /// The default instance of [AliyunNumberAuthPlatform] to use.
  ///
  /// Defaults to [MethodChannelAliyunNumberAuth].
  static AliyunNumberAuthPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AliyunNumberAuthPlatform] when
  /// they register themselves.
  static set instance(AliyunNumberAuthPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Initialize the SDK with secret info from Aliyun console
  Future<AliyunNumberAuthResult> initialize(String secretInfo) {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  /// Get verification token for number authentication
  Future<AliyunNumberAuthResult> getVerifyToken(int timeout) {
    throw UnimplementedError('getVerifyToken() has not been implemented.');
  }

  /// Pre-login to accelerate token retrieval
  Future<AliyunNumberAuthResult> accelerateVerify(int timeout) {
    throw UnimplementedError('accelerateVerify() has not been implemented.');
  }

  /// Check if the environment supports number authentication
  Future<AliyunNumberAuthResult> checkEnvironment() {
    throw UnimplementedError('checkEnvironment() has not been implemented.');
  }

  /// Get application signature information for Aliyun console configuration
  Future<AppSignatureInfo> getAppSignatureInfo() {
    throw UnimplementedError('getAppSignatureInfo() has not been implemented.');
  }
}
