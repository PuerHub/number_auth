/// Result code constants for Aliyun Number Authentication
class AliyunNumberAuthCode {
  // Private constructor to prevent instantiation
  AliyunNumberAuthCode._();

  // Success codes
  /// Successful operation
  static const String success = '600000';

  /// PNS success (alternative success code)
  static const String pnsSuccess = 'PNS_SUCCESS';

  /// Authorization page displayed successfully
  static const String authPageDisplayed = '600001';

  // UI click event codes
  /// User clicked the login button
  static const String clickLogin = '700000';

  /// User clicked the switch account button
  static const String clickSwitch = '700001';

  /// User clicked the close/back button
  static const String clickClose = '700002';

  /// User clicked outside the dialog (tap mask to close)
  static const String clickMask = '700003';

  /// User clicked the privacy agreement checkbox
  static const String clickCheckbox = '700004';

  // Error codes
  /// SDK not initialized
  static const String notInitialized = 'NOT_INITIALIZED';

  /// Activity not available (Android)
  static const String noActivity = 'NO_ACTIVITY';

  /// View controller not available (iOS)
  static const String noController = 'NO_CONTROLLER';

  /// Invalid argument provided
  static const String invalidArgument = 'INVALID_ARGUMENT';

  /// Token verification error
  static const String tokenError = 'TOKEN_ERROR';

  /// Initialization error
  static const String initError = 'INIT_ERROR';

  /// Accelerate operation error
  static const String accelerateError = 'ACCELERATE_ERROR';

  /// Environment check error
  static const String envCheckError = 'ENV_CHECK_ERROR';

  /// Login error
  static const String loginError = 'LOGIN_ERROR';

  /// Quit login page error
  static const String quitError = 'QUIT_ERROR';

  /// Unknown error
  static const String unknownError = 'UNKNOWN_ERROR';

  /// Check if a code represents success
  static bool isSuccess(String code) {
    return code == success || code == pnsSuccess;
  }

  /// Check if a code represents a UI click event
  static bool isClickEvent(String code) {
    return code.startsWith('7000');
  }

  /// Check if a code represents an error
  static bool isError(String code) {
    return !isSuccess(code) && code != authPageDisplayed;
  }
}
