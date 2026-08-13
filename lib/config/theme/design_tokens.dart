import 'package:flutter/material.dart';

/// Design tokens de l'application.
///
/// Inspiré des Apple Human Interface Guidelines et de Material Design 3 :
/// toutes les constantes d'un UI plat, moderne et sobre. Aucun widget ne doit
/// coder en dur une taille, un rayon ou une durée d'animation.
class DesignTokens {
  DesignTokens._();

  // ==================== SPACING ====================
  /// Échelle d'espacement sur une grille de 4px.
  static const double spaceXs = 4.0;
  static const double spaceS = 8.0;
  static const double spaceM = 12.0;
  static const double spaceL = 16.0;
  static const double spaceXl = 20.0;
  static const double spaceXxl = 24.0;
  static const double spaceXxxl = 32.0;
  static const double space4xl = 40.0;
  static const double space5xl = 48.0;

  // ==================== BORDER RADIUS ====================
  static const double radiusXs = 4.0;
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusXxl = 24.0;
  static const double radiusPill = 999.0;

  static BorderRadius get borderRadiusXs => BorderRadius.circular(radiusXs);
  static BorderRadius get borderRadiusS => BorderRadius.circular(radiusS);
  static BorderRadius get borderRadiusM => BorderRadius.circular(radiusM);
  static BorderRadius get borderRadiusL => BorderRadius.circular(radiusL);
  static BorderRadius get borderRadiusXl => BorderRadius.circular(radiusXl);
  static BorderRadius get borderRadiusXxl => BorderRadius.circular(radiusXxl);
  static BorderRadius get borderRadiusPill => BorderRadius.circular(radiusPill);

  // ==================== BORDER WIDTH ====================
  static const double borderWidthThin = 0.5;
  static const double borderWidthRegular = 1.0;
  static const double borderWidthThick = 2.0;
  static const double borderWidthFocus = 2.0;

  // ==================== ICON SIZES ====================
  static const double iconXs = 16.0;
  static const double iconS = 20.0;
  static const double iconM = 24.0;
  static const double iconL = 32.0;
  static const double iconXl = 40.0;
  static const double iconXxl = 48.0;
  static const double iconXxxl = 64.0;
  static const double iconEmpty = 80.0; // états vides
  static const double iconEmptyLarge = 100.0;

  // ==================== COMPONENT HEIGHTS ====================
  static const double heightButton = 48.0;
  static const double heightButtonSmall = 36.0;
  static const double heightButtonLarge = 56.0;
  static const double heightTextField = 48.0;
  static const double heightSearchBar = 44.0;
  static const double heightAppBar = 56.0;
  static const double heightBottomNav = 60.0;
  static const double heightListItem = 56.0;
  static const double heightListItemSmall = 48.0;

  // ==================== NAVIGATION RAIL (desktop) ====================
  /// Largeur du rail latéral replié (icône + libellé sous l'icône).
  static const double railWidth = 88.0;

  /// Largeur du rail étendu (icône + libellé à droite).
  static const double railWidthExtended = 232.0;

  // ==================== AVATAR & CIRCLE SIZES ====================
  static const double avatarS = 32.0;
  static const double avatarM = 40.0;
  static const double avatarL = 48.0;
  static const double avatarXl = 64.0;
  static const double avatarXxl = 80.0;

  // ==================== ELEVATION & SHADOWS ====================
  /// Ombres minimales — le design est plat par défaut.
  static List<BoxShadow> get shadowNone => [];

  static List<BoxShadow> shadowLow(bool isDarkMode) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.05),
      blurRadius: 4.0,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> shadowMedium(bool isDarkMode) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.08),
      blurRadius: 8.0,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> shadowHigh(bool isDarkMode) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: isDarkMode ? 0.4 : 0.12),
      blurRadius: 16.0,
      offset: const Offset(0, 4),
    ),
  ];

  // ==================== OPACITY LEVELS ====================
  static const double opacityDisabled = 0.3;
  static const double opacitySubtle = 0.5;
  static const double opacityMedium = 0.6;
  static const double opacityHigh = 0.7;
  static const double opacityAlmostFull = 0.9;
  static const double opacityFull = 1.0;

  static const double opacityBackground5 = 0.05;
  static const double opacityBackground8 = 0.08;
  static const double opacityBackground10 = 0.10;
  static const double opacityBackground15 = 0.15;
  static const double opacityBackground20 = 0.20;

  // ==================== ASPECT RATIOS ====================
  static const double aspectRatioSquare = 1.0;
  static const double aspectRatioVideo = 16.0 / 9.0;
  static const double aspectRatioCard = 3.0 / 2.0;
  static const double aspectRatioPortrait = 3.0 / 4.0;

  // ==================== ANIMATIONS ====================
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 250);
  static const Duration durationSlow = Duration(milliseconds: 350);
  static const Duration durationVerySlow = Duration(milliseconds: 500);

  static const Curve curveDefault = Curves.easeInOut;
  static const Curve curveEmphasized = Curves.easeOutCubic;
  static const Curve curveDecelerate = Curves.easeOut;

  // ==================== DIVIDER ====================
  static const double dividerThickness = 1.0;
  static const double dividerIndent = 16.0;

  // ==================== BADGE & CHIP ====================
  static const double badgeHeight = 24.0;
  static const double chipHeight = 32.0;
  static const EdgeInsets badgePadding = EdgeInsets.symmetric(
    horizontal: 12.0,
    vertical: 6.0,
  );
  static const EdgeInsets chipPadding = EdgeInsets.symmetric(
    horizontal: 12.0,
    vertical: 8.0,
  );

  // ==================== GRID SPACING ====================
  static const double gridSpacingSmall = 8.0;
  static const double gridSpacingMedium = 12.0;
  static const double gridSpacingLarge = 16.0;

  // ==================== DRAWER ====================
  static const double drawerWidth = 300.0;
  static const double drawerWidthPercent = 0.85;

  // ==================== BOTTOM SHEET ====================
  static const double bottomSheetHandleWidth = 40.0;
  static const double bottomSheetHandleHeight = 4.0;

  // ==================== HELPERS ====================

  /// Couleur de bordure selon le thème.
  ///
  /// Le défaut volontairement très bas (0.06) donne un hairline discret en mode
  /// clair au lieu d'un contour noir marqué. Les widgets qui ont besoin d'une
  /// bordure plus visible passent une `opacity` explicite.
  static Color getBorderColor(bool isDarkMode, {double opacity = 0.06}) {
    return (isDarkMode ? Colors.white : Colors.black).withValues(
      alpha: opacity,
    );
  }

  static Color getSubtleBackground(
    BuildContext context, {
    double opacity = 0.05,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return (isDarkMode ? Colors.white : Colors.black).withValues(
      alpha: opacity,
    );
  }

  static Color getTextColorWithOpacity(BuildContext context, double opacity) {
    final theme = Theme.of(context);
    final baseColor = theme.brightness == Brightness.dark
        ? Colors.white
        : Colors.black;
    return baseColor.withValues(alpha: opacity);
  }

  static const EdgeInsets pagePadding = EdgeInsets.all(spaceL);
  static const EdgeInsets pagePaddingLarge = EdgeInsets.all(spaceXxl);

  static const EdgeInsets cardPadding = EdgeInsets.all(spaceL);
  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(spaceXl);

  static const double sectionSpacing = spaceXxl;
  static const double sectionSpacingLarge = spaceXxxl;

  static const double contentSpacing = spaceM;
  static const double contentSpacingLarge = spaceL;
}
