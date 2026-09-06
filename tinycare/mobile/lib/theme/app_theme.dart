import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

/// TinyCare Premium Design System
/// Premium, elegant, modern, clean - soft green / dark green palette
class AppColors {
  // Primary Palette - Soft Green / Dark Green
  static const Color primary = Color(0xFF3A7059);
  static const Color primaryLight = Color(0xFF4A8C6F);
  static const Color primaryDark = Color(0xFF2C5A47);
  static const Color primarySubtle = Color(0xFFF0F7F3);
  static const Color primaryLighter = Color(0xFFE8F4ED);
  static const Color primarySurface = Color(0xFFF0F7F3);

  // Background (light)
  static const Color bg = Color(0xFFF6F7F5);
  static const Color bgAlt = Color(0xFFEDEEF0);
  static const Color surface = Colors.white;
  static const Color surfaceElevated = Colors.white;

  // Text (light)
  static const Color text = Color(0xFF1B2A22);
  static const Color textSecondary = Color(0xFF566B5E);
  static const Color textMuted = Color(0xFF8A9B91);
  static const Color textOnPrimary = Colors.white;

  // Borders (light)
  static const Color border = Color(0xFFE2E4E0);
  static const Color borderLight = Color(0xFFEDEEEC);

  // Dark theme variants (mirror web dark palette)
  static const Color darkBg = Color(0xFF0E1510);
  static const Color darkBgAlt = Color(0xFF121B15);
  static const Color darkSurface = Color(0xFF162019);
  static const Color darkSurfaceElevated = Color(0xFF1E2A22);
  static const Color darkText = Color(0xFFE4ECE6);
  static const Color darkTextSecondary = Color(0xFF9CB0A2);
  static const Color darkTextMuted = Color(0xFF5E7569);
  static const Color darkBorder = Color(0xFF223028);
  static const Color darkBorderLight = Color(0xFF1C2820);
  static const Color darkSuccessBg = Color(0xFF152520);
  static const Color darkWarningBg = Color(0xFF252015);
  static const Color darkErrorBg = Color(0xFF251515);
  static const Color darkInfoBg = Color(0xFF152025);

  // Status Colors
  static const Color success = Color(0xFF3A7059);
  static const Color successBg = Color(0xFFEDF5F0);
  static const Color warning = Color(0xFFB8862D);
  static const Color warningBg = Color(0xFFFDF5E6);
  static const Color error = Color(0xFFB84040);
  static const Color errorBg = Color(0xFFFBE9E9);
  static const Color info = Color(0xFF3A6FA0);
  static const Color infoBg = Color(0xFFEAF1F8);

  // Shadows
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x08000000),
      blurRadius: 8,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> cardShadowElevated = [
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 12,
      offset: Offset(0, 2),
    ),
  ];
}

/// Theme-aware color resolver. Use in widgets that need to adapt to light/dark mode.
class ThemeHelper {
  static bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

  static Color bg(BuildContext context) => isDark(context) ? AppColors.darkBg : AppColors.bg;
  static Color bgAlt(BuildContext context) => isDark(context) ? AppColors.darkBgAlt : AppColors.bgAlt;
  static Color surface(BuildContext context) => isDark(context) ? AppColors.darkSurface : AppColors.surface;
  static Color surfaceElevated(BuildContext context) => isDark(context) ? AppColors.darkSurfaceElevated : AppColors.surfaceElevated;
  static Color text(BuildContext context) => isDark(context) ? AppColors.darkText : AppColors.text;
  static Color textSecondary(BuildContext context) => isDark(context) ? AppColors.darkTextSecondary : AppColors.textSecondary;
  static Color textMuted(BuildContext context) => isDark(context) ? AppColors.darkTextMuted : AppColors.textMuted;
  static Color border(BuildContext context) => isDark(context) ? AppColors.darkBorder : AppColors.border;
  static Color borderLight(BuildContext context) => isDark(context) ? AppColors.darkBorderLight : AppColors.borderLight;
  static Color successBg(BuildContext context) => isDark(context) ? AppColors.darkSuccessBg : AppColors.successBg;
  static Color warningBg(BuildContext context) => isDark(context) ? AppColors.darkWarningBg : AppColors.warningBg;
  static Color errorBg(BuildContext context) => isDark(context) ? AppColors.darkErrorBg : AppColors.errorBg;
  static Color infoBg(BuildContext context) => isDark(context) ? AppColors.darkInfoBg : AppColors.infoBg;
}

class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;

  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
  static BorderRadius get xlAll => BorderRadius.circular(xl);
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
}

class AppTypography {
  static const String fontFamily = 'Inter';

  static const TextStyle h1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
    letterSpacing: -0.02,
    height: 1.3,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
    letterSpacing: -0.01,
    height: 1.3,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
    height: 1.3,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.text,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    height: 1.4,
  );

  static const TextStyle label = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
    letterSpacing: 0.05,
    height: 1.4,
  );

  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle amount = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    height: 1.3,
  );

  static const TextStyle amountLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: AppColors.text,
    letterSpacing: 0.02,
    height: 1.3,
  );
}

class AppTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: AppColors.primary,
    scaffoldBackgroundColor: AppColors.bg,
    fontFamily: AppTypography.fontFamily,

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),

    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.lgAll,
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdAll,
        ),
        textStyle: AppTypography.button,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdAll,
        ),
        textStyle: AppTypography.button,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: const TextStyle(color: AppColors.textMuted),
      hintStyle: const TextStyle(color: AppColors.textMuted),
    ),

    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 1,
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: AppColors.primary,
    scaffoldBackgroundColor: AppColors.darkBg,
    fontFamily: AppTypography.fontFamily,

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),

    cardTheme: CardThemeData(
      color: AppColors.darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.lgAll,
        side: const BorderSide(color: AppColors.darkBorder, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdAll,
        ),
        textStyle: AppTypography.button,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.darkBorder),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdAll,
        ),
        textStyle: AppTypography.button,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurface,
      border: OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: const TextStyle(color: AppColors.darkTextMuted),
      hintStyle: const TextStyle(color: AppColors.darkTextMuted),
    ),

    dividerTheme: const DividerThemeData(
      color: AppColors.darkBorder,
      thickness: 1,
      space: 1,
    ),

    popupMenuTheme: const PopupMenuThemeData(
      color: AppColors.darkSurface,
    ),

    dropdownMenuTheme: const DropdownMenuThemeData(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
      ),
    ),
  );
}

// =============================================================================
// REUSABLE WIDGETS
// =============================================================================

/// Common widget builders for consistent UI
class AppWidgets {
  // ===========================================================================
  // STATUS BADGES
  // ===========================================================================

  /// Standard status badge for invoice/payment/user status
  static Widget statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Status badge with icon prefix
  static Widget statusBadgeWithIcon(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Small dot badge (for notifications)
  static Widget dotBadge({Color color = AppColors.error, int? count}) {
    if (count != null && count == 0) return const SizedBox.shrink();
    return Container(
      width: count != null && count > 9 ? 20 : 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: count != null
          ? Text(
              count > 99 ? '99+' : '$count',
              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
            )
          : const SizedBox(width: 6, height: 6),
    );
  }

  // ===========================================================================
  // BUTTONS
  // ===========================================================================

  /// Primary filled button
  static Widget primaryButton({
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
    bool fullWidth = true,
    IconData? icon,
    double? height,
  }) {
    final btn = icon != null
        ? ElevatedButton.icon(
            onPressed: onPressed,
            icon: isLoading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Icon(icon, size: 18),
            label: Text(label),
          )
        : ElevatedButton(
            onPressed: onPressed,
            child: isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(label),
          );

    if (!fullWidth) return btn;
    return SizedBox(width: double.infinity, height: height ?? 48, child: btn);
  }

  /// Secondary / outlined button
  static Widget secondaryButton({
    required String label,
    required VoidCallback? onPressed,
    bool fullWidth = true,
    IconData? icon,
    Color? color,
  }) {
    final btn = icon != null
        ? OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 18),
            label: Text(label),
            style: OutlinedButton.styleFrom(
              foregroundColor: color ?? AppColors.primary,
              side: BorderSide(color: color ?? AppColors.border),
            ),
          )
        : OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: color ?? AppColors.primary,
              side: BorderSide(color: color ?? AppColors.border),
            ),
            child: Text(label),
          );

    if (!fullWidth) return btn;
    return SizedBox(width: double.infinity, child: btn);
  }

  /// Danger / destructive button
  static Widget dangerButton({
    required String label,
    required VoidCallback? onPressed,
    bool fullWidth = true,
    IconData? icon,
  }) {
    final btn = icon != null
        ? OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 18),
            label: Text(label),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
            ),
          )
        : OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
            ),
            child: Text(label),
          );

    if (!fullWidth) return btn;
    return SizedBox(width: double.infinity, child: btn);
  }

  /// Text-only button (for links and secondary actions)
  static Widget textButton({
    required String label,
    required VoidCallback? onPressed,
    Color? color,
  }) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          color: color ?? AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Icon button with optional badge
  static Widget iconButton({
    required IconData icon,
    required VoidCallback? onPressed,
    int? badgeCount,
    Color? badgeColor,
    String? tooltip,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
          tooltip: tooltip,
        ),
        if (badgeCount != null && badgeCount > 0)
          Positioned(
            top: 4,
            right: 4,
            child: dotBadge(color: badgeColor ?? AppColors.error, count: badgeCount),
          ),
      ],
    );
  }

  // ===========================================================================
  // CARDS
  // ===========================================================================

  /// Standard card container
  static Widget card({
    required Widget child,
    VoidCallback? onTap,
    EdgeInsets? padding,
    Color? color,
    BuildContext? context,
  }) {
    final surfaceColor = context != null ? ThemeHelper.surface(context) : AppColors.surface;
    final borderColor = context != null ? ThemeHelper.border(context) : AppColors.border;
    final container = Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color ?? surfaceColor,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: borderColor),
        boxShadow: AppColors.cardShadow,
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: container,
      );
    }
    return container;
  }

  /// Info card with icon, title, and value (for dashboards)
  static Widget statCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    VoidCallback? onTap,
    BuildContext? context,
  }) {
    final surfaceColor = context != null ? ThemeHelper.surface(context) : AppColors.surface;
    final borderColor = context != null ? ThemeHelper.border(context) : AppColors.border;
    final container = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: borderColor),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(label.toUpperCase(), style: AppTypography.label),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: color, height: 1),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: container);
    }
    return container;
  }

  /// Highlighted gradient card (for revenue, totals, etc.)
  static Widget highlightCard({
    required String title,
    required String value,
    required LinearGradient gradient,
    IconData? icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(gradient: gradient, borderRadius: AppRadius.lgAll),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: AppRadius.smAll,
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // AVATARS
  // ===========================================================================

  /// Circle avatar with initial letter
  static Widget avatar({
    required String name,
    double size = 48,
    Color? backgroundColor,
    Color? textColor,
    double fontSize = 18,
  }) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primaryLighter,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: textColor ?? AppColors.primary,
          ),
        ),
      ),
    );
  }

  /// Avatar with online/status dot
  static Widget avatarWithStatus({
    required String name,
    double size = 48,
    Color? statusColor,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar(name: name, size: size),
        if (statusColor != null)
          Positioned(
            bottom: 0, right: 0,
            child: Container(
              width: size * 0.3, height: size * 0.3,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  /// Square avatar (for children cards)
  static Widget squareAvatar({
    required String name,
    double size = 56,
    Color? backgroundColor,
    Color? textColor,
  }) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primaryLighter,
        borderRadius: AppRadius.mdAll,
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: size * 0.38,
            fontWeight: FontWeight.w700,
            color: textColor ?? AppColors.primary,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // INFO ROWS
  // ===========================================================================

  /// Info row for detail pages
  static Widget infoRow(String label, String value, {bool isTotal = false, bool isMuted = false, BuildContext? context}) {
    final mutedColor = context != null ? ThemeHelper.textMuted(context) : AppColors.textMuted;
    final textColor = context != null ? ThemeHelper.text(context) : AppColors.text;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: mutedColor)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: isTotal ? 15 : 13,
                fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
                color: isMuted ? mutedColor : (isTotal ? AppColors.primary : textColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Info row with icon prefix
  static Widget infoRowIcon({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
    BuildContext? context,
  }) {
    final mutedColor = context != null ? ThemeHelper.textMuted(context) : AppColors.textMuted;
    final textColor = context != null ? ThemeHelper.text(context) : AppColors.text;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor ?? mutedColor),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(fontSize: 13, color: mutedColor)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ALERT BOXES
  // ===========================================================================

  /// Error alert box
  static Widget errorAlert(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: AppRadius.smAll,
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(color: AppColors.error, fontSize: 13))),
        ],
      ),
    );
  }

  /// Success alert box
  static Widget successAlert(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.successBg,
        borderRadius: AppRadius.smAll,
        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(color: AppColors.success, fontSize: 13))),
        ],
      ),
    );
  }

  /// Warning alert box
  static Widget warningAlert(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: AppRadius.smAll,
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_outlined, color: AppColors.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(color: AppColors.warning, fontSize: 13))),
        ],
      ),
    );
  }

  /// Info alert box
  static Widget infoAlert(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.infoBg,
        borderRadius: AppRadius.smAll,
        border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.info, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(color: AppColors.info, fontSize: 13))),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION HEADERS & DIVIDERS
  // ===========================================================================

  /// Section header with optional action button
  static Widget sectionHeader(String title, {VoidCallback? onAction, String? actionLabel, BuildContext? context}) {
    final textColor = context != null ? ThemeHelper.text(context) : AppColors.text;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTypography.h3.copyWith(color: textColor)),
        if (onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel ?? 'Lihat Semua',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
            ),
          ),
      ],
    );
  }

  /// Divider with label
  static Widget labeledDivider(String label, {BuildContext? context}) {
    final mutedColor = context != null ? ThemeHelper.textMuted(context) : AppColors.textMuted;
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(label, style: TextStyle(fontSize: 12, color: mutedColor)),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }

  // ===========================================================================
  // MENU ITEMS
  // ===========================================================================

  /// Menu item for settings/list screens
  static Widget menuItem({
    required String label,
    required IconData icon,
    VoidCallback? onTap,
    String? subtitle,
    Widget? trailing,
    Color? iconColor,
    BuildContext? context,
  }) {
    final textColor = context != null ? ThemeHelper.text(context) : AppColors.text;
    final mutedColor = context != null ? ThemeHelper.textMuted(context) : AppColors.textMuted;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
          borderRadius: AppRadius.smAll,
        ),
        child: Icon(icon, color: iconColor ?? AppColors.primary, size: 20),
      ),
      title: Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textColor)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 12, color: mutedColor)) : null,
      trailing: trailing ?? Icon(Icons.chevron_right, color: mutedColor, size: 20),
    );
  }

  /// Grouped menu items in a card container
  /// Each item is a map with keys: 'label', 'icon', 'onTap', 'subtitle' (optional), 'iconColor' (optional)
  static Widget menuGroup(List<Map<String, dynamic>> items, {BuildContext? context}) {
    final surfaceColor = context != null ? ThemeHelper.surface(context) : AppColors.surface;
    final borderColor = context != null ? ThemeHelper.border(context) : AppColors.border;
    final borderLightColor = context != null ? ThemeHelper.borderLight(context) : AppColors.borderLight;
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: borderColor),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isLast = index == items.length - 1;
          return Column(
            children: [
              menuItem(
                label: item['label'] as String,
                icon: item['icon'] as IconData,
                onTap: item['onTap'] as VoidCallback?,
                subtitle: item['subtitle'] as String?,
                iconColor: item['iconColor'] as Color?,
                context: context,
              ),
              if (!isLast)
                Divider(height: 1, indent: 72, endIndent: 18, color: borderLightColor),
            ],
          );
        }),
      ),
    );
  }

  // ===========================================================================
  // FORM WIDGETS
  // ===========================================================================

  /// Labeled form section
  static Widget formSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.label),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  /// Form field with label and helper text
  static Widget formField({
    required TextEditingController controller,
    required String label,
    String? helperText,
    String? hintText,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    Widget? prefixIcon,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          maxLines: maxLines,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            labelText: label,
            hintText: hintText,
            suffixIcon: suffixIcon,
            prefixIcon: prefixIcon,
            alignLabelWithHint: maxLines > 1,
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(helperText, style: AppTypography.caption),
          ),
        ],
      ],
    );
  }

  // ===========================================================================
  // EXISTING WIDGETS (kept for backward compatibility)
  // ===========================================================================

  /// Empty state widget
  static Widget emptyState({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? action,
    BuildContext? context,
  }) {
    final bgColor = context != null ? ThemeHelper.bgAlt(context) : AppColors.bgAlt;
    final mutedColor = context != null ? ThemeHelper.textMuted(context) : AppColors.textMuted;
    final textColor = context != null ? ThemeHelper.text(context) : AppColors.text;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: AppRadius.lgAll,
              ),
              child: Icon(icon, color: mutedColor, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(fontSize: 12, color: mutedColor), textAlign: TextAlign.center),
            ],
            if (action != null) ...[
              const SizedBox(height: 16),
              action,
            ],
          ],
        ),
      ),
    );
  }

  /// Error state widget
  static Widget errorState({
    required String message,
    required VoidCallback onRetry,
    BuildContext? context,
  }) {
    final bgColor = context != null ? ThemeHelper.errorBg(context) : AppColors.errorBg;
    final textColor = context != null ? ThemeHelper.text(context) : AppColors.text;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: AppRadius.lgAll,
              ),
              child: const Icon(Icons.error_outline, color: AppColors.error, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  /// Loading indicator
  static Widget loadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }

  /// Loading overlay
  static Widget loadingOverlay({String? message, BuildContext? context}) {
    final surfaceColor = context != null ? ThemeHelper.surface(context) : AppColors.surface;
    final mutedColor = context != null ? ThemeHelper.textMuted(context) : AppColors.textMuted;
    return Container(
      color: Colors.black.withValues(alpha: 0.3),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: AppRadius.lgAll,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(message, style: TextStyle(fontSize: 13, color: mutedColor)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Snackbar helper
  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
    );
  }

  /// Confirm dialog
  static Future<bool> confirmDialog(
    BuildContext context, {
    required String title,
    required String content,
    String confirmLabel = 'Ya',
    String cancelLabel = 'Batal',
    Color? confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(cancelLabel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: confirmColor ?? AppColors.primary),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

// =============================================================================
// SHARED THEME SWITCHER WIDGET
// =============================================================================

/// Reusable dark/light mode toggle widget used by both Admin and Parent.
class ThemeSwitcher extends StatelessWidget {
  const ThemeSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final surfaceColor = ThemeHelper.surface(context);
    final borderColor = ThemeHelper.border(context);
    final textColor = ThemeHelper.text(context);
    final mutedColor = ThemeHelper.textMuted(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: borderColor),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: AppRadius.smAll,
            ),
            child: Icon(
              isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mode Tampilan', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: textColor)),
                const SizedBox(height: 2),
                Text(
                  isDark ? 'Mode Gelap' : 'Mode Terang',
                  style: TextStyle(fontSize: 12, color: mutedColor),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              themeProvider.setThemeMode(
                isDark ? ThemeModeOption.light : ThemeModeOption.dark,
              );
            },
            child: Container(
              width: 52, height: 28,
              decoration: BoxDecoration(
                color: isDark ? AppColors.primary : ThemeHelper.border(context),
                borderRadius: BorderRadius.circular(14),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 22, height: 22,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      isDark ? Icons.dark_mode : Icons.light_mode,
                      size: 12,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

