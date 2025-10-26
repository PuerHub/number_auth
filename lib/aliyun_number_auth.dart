import 'aliyun_number_auth_platform_interface.dart';
import 'aliyun_number_auth_ui_config.dart';
import 'aliyun_number_auth_method_channel.dart';
import 'aliyun_number_auth_constants.dart';

export 'aliyun_number_auth_ui_config.dart';
export 'aliyun_number_auth_method_channel.dart' show AuthPageClickCallback;
export 'aliyun_number_auth_constants.dart';

/// Result class for number authentication operations
class AliyunNumberAuthResult {
  /// Result code from the SDK
  final String code;

  /// Result message or token
  final String message;

  /// Whether the operation was successful
  bool get isSuccess => AliyunNumberAuthCode.isSuccess(code);

  const AliyunNumberAuthResult({required this.code, required this.message});

  factory AliyunNumberAuthResult.fromMap(Map<String, dynamic> map) =>
      AliyunNumberAuthResult(
        code: map['code'] as String? ?? '',
        message: map['message'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AliyunNumberAuthResult &&
          code == other.code &&
          message == other.message;

  @override
  int get hashCode => Object.hash(code, message);

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

  const AppSignatureInfo({
    required this.packageName,
    required this.signature,
    this.appIdentifier,
  });

  factory AppSignatureInfo.fromMap(Map<String, dynamic> map) =>
      AppSignatureInfo(
        packageName: map['packageName'] as String? ?? '',
        signature: map['signature'] as String? ?? '',
        appIdentifier: map['appIdentifier'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSignatureInfo &&
          packageName == other.packageName &&
          signature == other.signature &&
          appIdentifier == other.appIdentifier;

  @override
  int get hashCode => Object.hash(packageName, signature, appIdentifier);

  @override
  String toString() => [
    'App Signature Information:',
    'Package Name: $packageName',
    'Signature: $signature',
    if (appIdentifier?.isNotEmpty ?? false) 'App Identifier: $appIdentifier',
  ].join('\n');
}

/// Main class for Aliyun Number Authentication
class AliyunNumberAuth {
  AliyunNumberAuth._();

  /// Initialize the Aliyun Number Auth SDK
  ///
  /// [secretInfo] is the authentication scheme secret key obtained from Aliyun console
  /// This should be called once when the app starts
  ///
  /// Example:
  /// ```dart
  /// await AliyunNumberAuth.initialize('your_secret_info');
  /// ```
  static Future<AliyunNumberAuthResult> initialize(String secretInfo) =>
      AliyunNumberAuthPlatform.instance.initialize(secretInfo);

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
  static Future<AliyunNumberAuthResult> getVerifyToken({int timeout = 5000}) =>
      AliyunNumberAuthPlatform.instance.getVerifyToken(timeout);

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
  }) => AliyunNumberAuthPlatform.instance.accelerateVerify(timeout);

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
  static Future<AliyunNumberAuthResult> checkEnvironment() =>
      AliyunNumberAuthPlatform.instance.checkEnvironment();

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
  static Future<AppSignatureInfo> getAppSignatureInfo() =>
      AliyunNumberAuthPlatform.instance.getAppSignatureInfo();

  /// Get login token for one-key login (displays authorization page)
  ///
  /// [timeout] is the timeout in milliseconds (default: 5000ms)
  /// [uiConfig] is optional UI configuration for customizing the authorization page
  /// Returns the login token on success
  ///
  /// This method displays an authorization page with the masked phone number.
  /// User clicks the login button to authorize and get the token.
  ///
  /// Example:
  /// ```dart
  /// // Without UI customization
  /// final result = await AliyunNumberAuth.getLoginToken(timeout: 5000);
  ///
  /// // With UI customization
  /// final config = AliyunNumberAuthUIConfig(
  ///   logoImgPath: 'assets/logo.png',
  ///   sloganText: 'Welcome to Our App',
  ///   privacyOneTitle: '《Privacy Policy》',
  ///   privacyOneUrl: 'https://example.com/privacy',
  ///   loginButtonText: 'Login',
  ///   navTitle: 'One-Key Login',
  /// );
  /// final result = await AliyunNumberAuth.getLoginToken(
  ///   timeout: 5000,
  ///   uiConfig: config,
  /// );
  ///
  /// if (result.isSuccess) {
  ///   print('Login Token: ${result.message}');
  ///   // Send token to your server for verification
  /// } else {
  ///   print('Login failed: ${result.code} - ${result.message}');
  /// }
  /// ```
  static Future<AliyunNumberAuthResult> getLoginToken({
    int timeout = 5000,
    AliyunNumberAuthUIConfig? uiConfig,
  }) => AliyunNumberAuthPlatform.instance.getLoginToken(timeout, uiConfig);

  /// Pre-login to accelerate authorization page display (optional)
  ///
  /// [timeout] is the timeout in milliseconds (default: 5000ms)
  /// This method can speed up the subsequent `getLoginToken` call
  ///
  /// Call this method 2-3 seconds before showing the login page
  /// to pre-fetch necessary parameters and accelerate authorization page display.
  ///
  /// Example:
  /// ```dart
  /// // Call on splash screen or app startup
  /// await AliyunNumberAuth.accelerateLoginPage(timeout: 5000);
  ///
  /// // Later, when showing login page
  /// await AliyunNumberAuth.getLoginToken();
  /// ```
  static Future<AliyunNumberAuthResult> accelerateLoginPage({
    int timeout = 5000,
  }) => AliyunNumberAuthPlatform.instance.accelerateLoginPage(timeout);

  /// Quit/dismiss the authorization page
  ///
  /// Call this method to manually close the authorization page.
  /// Usually called when user clicks a custom close button.
  ///
  /// Example:
  /// ```dart
  /// await AliyunNumberAuth.quitLoginPage();
  /// ```
  static Future<AliyunNumberAuthResult> quitLoginPage() =>
      AliyunNumberAuthPlatform.instance.quitLoginPage();

  /// Set callback for authorization page UI click events
  ///
  /// This callback will be triggered when user interacts with the authorization page.
  /// The [code] parameter indicates which UI element was clicked.
  /// The [jsonString] parameter contains additional information about the click event.
  ///
  /// Common click codes (see [AliyunNumberAuthCode]):
  /// - [AliyunNumberAuthCode.clickLogin]: User clicked the login button
  /// - [AliyunNumberAuthCode.clickSwitch]: User clicked the switch account button
  /// - [AliyunNumberAuthCode.clickClose]: User clicked the close/back button
  /// - [AliyunNumberAuthCode.clickMask]: User clicked outside the dialog (tap mask to close)
  /// - [AliyunNumberAuthCode.clickCheckbox]: User clicked the privacy agreement checkbox
  ///
  /// Example:
  /// ```dart
  /// AliyunNumberAuth.setAuthPageClickCallback((code, jsonString) {
  ///   print('Auth page clicked: $code');
  ///   print('Details: $jsonString');
  ///
  ///   if (code == AliyunNumberAuthCode.clickClose) {
  ///     print('User closed the auth page');
  ///   }
  /// });
  /// ```
  static void setAuthPageClickCallback(AuthPageClickCallback? callback) {
    final platform = AliyunNumberAuthPlatform.instance;
    if (platform is MethodChannelAliyunNumberAuth) {
      platform.setAuthPageClickCallback(callback);
    }
  }
}
