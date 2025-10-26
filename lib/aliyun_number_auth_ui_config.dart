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
  /// Only includes non-null values to reduce data transfer
  Map<String, dynamic> toMap() => {
    if (logoImgPath != null) 'logoImgPath': logoImgPath,
    if (sloganText != null) 'sloganText': sloganText,
    if (privacyOneTitle != null) 'privacyOneTitle': privacyOneTitle,
    if (privacyOneUrl != null) 'privacyOneUrl': privacyOneUrl,
    if (privacyTwoTitle != null) 'privacyTwoTitle': privacyTwoTitle,
    if (privacyTwoUrl != null) 'privacyTwoUrl': privacyTwoUrl,
    if (loginButtonText != null) 'loginButtonText': loginButtonText,
    if (navTitle != null) 'navTitle': navTitle,
    if (hideNav != null) 'hideNav': hideNav,
    if (hideSwitchButton != null) 'hideSwitchButton': hideSwitchButton,
    if (backgroundColor != null) 'backgroundColor': backgroundColor,
    if (navBarColor != null) 'navBarColor': navBarColor,
    if (loginButtonColor != null) 'loginButtonColor': loginButtonColor,
    if (textColor != null) 'textColor': textColor,
  };

  @override
  String toString() =>
      'AliyunNumberAuthUIConfig('
      'logoImgPath: $logoImgPath, '
      'sloganText: $sloganText, '
      'privacyOneTitle: $privacyOneTitle, '
      'navTitle: $navTitle'
      ')';
}
