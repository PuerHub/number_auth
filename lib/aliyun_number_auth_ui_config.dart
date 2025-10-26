/// UI Configuration for One-Key Login Authorization Page
class AliyunNumberAuthUIConfig {
  /// Logo image path (asset path or network URL)
  /// Example: 'assets/images/logo.png'
  final String? logoImgPath;

  /// Slogan text displayed below the logo
  /// Example: 'Welcome to Our App'
  final String? sloganText;

  /// First privacy agreement title
  /// Example: '《Privacy Policy》'
  final String? privacyOneTitle;

  /// First privacy agreement URL
  final String? privacyOneUrl;

  /// Second privacy agreement title (optional)
  /// Example: '《Terms of Service》'
  final String? privacyTwoTitle;

  /// Second privacy agreement URL (optional)
  final String? privacyTwoUrl;

  /// Login button text
  /// Default: 'Login' or '登录'
  final String? loginButtonText;

  /// Navigation bar title
  /// Default: 'One-Key Login' or '一键登录'
  final String? navTitle;

  /// Whether to hide the navigation bar
  /// Default: true (for dialog mode)
  final bool? hideNav;

  /// Whether to hide the switch account button
  /// Default: true
  final bool? hideSwitchButton;

  /// Background color (ARGB hex string)
  /// Example: '0xFFFFFFFF' for white, '0xFF000000' for black
  final String? backgroundColor;

  /// Navigation bar background color (ARGB hex string)
  final String? navBarColor;

  /// Login button background color (ARGB hex string)
  final String? loginButtonColor;

  /// Text color for general text (ARGB hex string)
  final String? textColor;

  const AliyunNumberAuthUIConfig({
    this.logoImgPath,
    this.sloganText,
    this.privacyOneTitle,
    this.privacyOneUrl,
    this.privacyTwoTitle,
    this.privacyTwoUrl,
    this.loginButtonText,
    this.navTitle,
    this.hideNav,
    this.hideSwitchButton,
    this.backgroundColor,
    this.navBarColor,
    this.loginButtonColor,
    this.textColor,
  });

  /// Convert to map for platform channel
  Map<String, dynamic> toMap() {
    return {
      'logoImgPath': logoImgPath,
      'sloganText': sloganText,
      'privacyOneTitle': privacyOneTitle,
      'privacyOneUrl': privacyOneUrl,
      'privacyTwoTitle': privacyTwoTitle,
      'privacyTwoUrl': privacyTwoUrl,
      'loginButtonText': loginButtonText,
      'navTitle': navTitle,
      'hideNav': hideNav,
      'hideSwitchButton': hideSwitchButton,
      'backgroundColor': backgroundColor,
      'navBarColor': navBarColor,
      'loginButtonColor': loginButtonColor,
      'textColor': textColor,
    };
  }

  @override
  String toString() {
    return 'AliyunNumberAuthUIConfig('
        'logoImgPath: $logoImgPath, '
        'sloganText: $sloganText, '
        'privacyOneTitle: $privacyOneTitle, '
        'navTitle: $navTitle'
        ')';
  }
}
