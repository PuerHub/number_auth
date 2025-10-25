import 'aliyun_number_auth_platform_interface.dart';

/// Result class for number authentication operations
class AliyunNumberAuthResult {
  /// Result code from the SDK
  final String code;

  /// Result message or token
  final String message;

  /// Whether the operation was successful
  bool get isSuccess => code == '600000' || code == 'PNS_SUCCESS';

  AliyunNumberAuthResult({required this.code, required this.message});

  factory AliyunNumberAuthResult.fromMap(Map<String, dynamic> map) {
    return AliyunNumberAuthResult(
      code: map['code'] as String? ?? '',
      message: map['message'] as String? ?? '',
    );
  }

  @override
  String toString() => 'AliyunNumberAuthResult(code: $code, message: $message)';
}

/// Application signature information for Aliyun console configuration
class AppSignatureInfo {
  /// Package name or Bundle ID
  final String packageName;

  /// Signature fingerprint (MD5 for Android, SHA256 for Harmony, or certificate info for iOS)
  final String signature;

  /// Additional identifier (App ID for Harmony, empty for others)
  final String? appIdentifier;

  AppSignatureInfo({
    required this.packageName,
    required this.signature,
    this.appIdentifier,
  });

  factory AppSignatureInfo.fromMap(Map<String, dynamic> map) {
    return AppSignatureInfo(
      packageName: map['packageName'] as String? ?? '',
      signature: map['signature'] as String? ?? '',
      appIdentifier: map['appIdentifier'] as String?,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('App Signature Information:');
    buffer.writeln('Package Name: $packageName');
    buffer.writeln('Signature: $signature');
    if (appIdentifier != null && appIdentifier!.isNotEmpty) {
      buffer.writeln('App Identifier: $appIdentifier');
    }
    return buffer.toString();
  }
}

/// Main class for Aliyun Number Authentication
class AliyunNumberAuth {
  /// Initialize the Aliyun Number Auth SDK
  ///
  /// [secretInfo] is the authentication scheme secret key obtained from Aliyun console
  /// This should be called once when the app starts
  ///
  /// Example:
  /// ```dart
  /// await AliyunNumberAuth.initialize('your_secret_info');
  /// ```
  static Future<AliyunNumberAuthResult> initialize(String secretInfo) async {
    return AliyunNumberAuthPlatform.instance.initialize(secretInfo);
  }

  /// Get verification token for the current phone number
  ///
  /// [timeout] is the timeout in milliseconds (default: 5000ms)
  /// Returns the verification token on success
  ///
  /// Example:
  /// ```dart
  /// final result = await AliyunNumberAuth.getVerifyToken(timeout: 5000);
  /// if (result.isSuccess) {
  ///   print('Token: ${result.message}');
  ///   // Send token to your server for verification
  /// } else {
  ///   print('Error: ${result.code} - ${result.message}');
  /// }
  /// ```
  static Future<AliyunNumberAuthResult> getVerifyToken({
    int timeout = 5000,
  }) async {
    return AliyunNumberAuthPlatform.instance.getVerifyToken(timeout);
  }

  /// Pre-login to accelerate token retrieval (optional)
  ///
  /// [timeout] is the timeout in milliseconds (default: 5000ms)
  /// This method can speed up the subsequent `getVerifyToken` call
  ///
  /// Example:
  /// ```dart
  /// await AliyunNumberAuth.accelerateVerify(timeout: 5000);
  /// // Later, when you need the token, call getVerifyToken()
  /// ```
  static Future<AliyunNumberAuthResult> accelerateVerify({
    int timeout = 5000,
  }) async {
    return AliyunNumberAuthPlatform.instance.accelerateVerify(timeout);
  }

  /// Check if number authentication environment is available
  ///
  /// Returns a result indicating whether the device supports number auth
  ///
  /// Example:
  /// ```dart
  /// final result = await AliyunNumberAuth.checkEnvironment();
  /// if (result.isSuccess) {
  ///   print('Number auth is supported');
  /// } else {
  ///   print('Number auth not supported: ${result.message}');
  /// }
  /// ```
  static Future<AliyunNumberAuthResult> checkEnvironment() async {
    return AliyunNumberAuthPlatform.instance.checkEnvironment();
  }

  /// Get application signature information for Aliyun console configuration
  ///
  /// This method retrieves the app's package name and signature information
  /// that you need to configure in the Aliyun Number Authentication console.
  ///
  /// Returns [AppSignatureInfo] containing:
  /// - Android: Package name + MD5 signature (without colons, lowercase)
  /// - iOS: Bundle ID + Certificate information
  /// - Harmony: Package name + Signature fingerprint + App Identifier
  ///
  /// Example:
  /// ```dart
  /// final info = await AliyunNumberAuth.getAppSignatureInfo();
  /// print('Package Name: ${info.packageName}');
  /// print('Signature: ${info.signature}');
  /// if (info.appIdentifier != null) {
  ///   print('App Identifier: ${info.appIdentifier}');
  /// }
  /// ```
  static Future<AppSignatureInfo> getAppSignatureInfo() async {
    return AliyunNumberAuthPlatform.instance.getAppSignatureInfo();
  }
}
