import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';

enum MessageType { success, error, warning, info }

class AppTheme {
  // Modern pink pastel color scheme inspired by beauty app design
  static const Color primaryPink = Color(0xFFFF6B8A);
  static const Color primaryPinkLight = Color(0xFFFFB3C1);
  static const Color primaryPinkDark = Color(0xFFE8516F);

  // Secondary colors
  static const Color secondaryRose = Color(0xFFFFF0F3);
  static const Color accentLavender = Color(0xFFE8D5FF);
  static const Color accentMint = Color(0xFFD4F4DD);

  // Neutral colors
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFFAFAFB);
  static const Color surfaceElevated = Color(0xFFF8F9FB);
  static const Color backgroundPrimary = Color(0xFFFDFDFE);
  static const Color backgroundSecondary = Color(0xFFF5F7FA);

  // Text colors
  static const Color textPrimary = Color(0xFF1A1D29);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Colors.white;

  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Border colors
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color borderMedium = Color(0xFFD1D5DB);
  static const Color borderStrong = Color(0xFF9CA3AF);

  // Typography System
  static const TextStyle headingLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    height: 1.2,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.3,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.4,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textTertiary,
    height: 1.4,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.4,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textSecondary,
    height: 1.3,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: textTertiary,
    height: 1.2,
  );

  // Updated radius values for more modern look
  static const double radiusXS = 6;
  static const double radiusSmall = 10;
  static const double radiusMedium = 14;
  static const double radiusLarge = 18;
  static const double radiusXL = 24;
  static const double radiusXXL = 32;

  // Enhanced spacing system
  static const double spacingXXS = 4;
  static const double spacingXS = 8;
  static const double spacingS = 12;
  static const double spacingM = 16;
  static const double spacingL = 20;
  static const double spacingXL = 24;
  static const double spacingXXL = 32;
  static const double spacingXXXL = 40;

  static const double controlHeight = 56;
  static const double controlHeightSmall = 40;
  static const double controlHeightLarge = 64;

  // Responsive breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;
  static const double largeDesktopBreakpoint = 1600;

  // Responsive spacing
  static double getResponsiveSpacing(
    BuildContext context, {
    double mobile = spacingM,
    double? tablet,
    double? desktop,
  }) {
    final width = MediaQuery.of(context).size.width;
    if (width >= desktopBreakpoint) {
      return desktop ?? tablet ?? mobile * 1.5;
    } else if (width >= tabletBreakpoint) {
      return tablet ?? mobile * 1.25;
    }
    return mobile;
  }

  // Responsive font size
  static double getResponsiveFontSize(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    final width = MediaQuery.of(context).size.width;
    if (width >= desktopBreakpoint) {
      return desktop ?? tablet ?? mobile * 1.2;
    } else if (width >= tabletBreakpoint) {
      return tablet ?? mobile * 1.1;
    }
    return mobile;
  }

  // Responsive padding
  static EdgeInsets getResponsivePadding(
    BuildContext context, {
    EdgeInsets? mobile,
    EdgeInsets? tablet,
    EdgeInsets? desktop,
  }) {
    final width = MediaQuery.of(context).size.width;
    if (width >= desktopBreakpoint) {
      return desktop ?? tablet ?? mobile ?? const EdgeInsets.all(spacingL);
    } else if (width >= tabletBreakpoint) {
      return tablet ?? mobile ?? const EdgeInsets.all(spacingM);
    }
    return mobile ?? const EdgeInsets.all(spacingM);
  }

  // Check screen size categories
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;
  static bool isLargeDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= largeDesktopBreakpoint;

  // Check orientation
  static bool isPortrait(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.portrait;
  static bool isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  // Get responsive column count for grid layouts
  static int getResponsiveColumns(
    BuildContext context, {
    int mobile = 1,
    int? tablet,
    int? desktop,
  }) {
    final width = MediaQuery.of(context).size.width;
    if (width >= desktopBreakpoint) {
      return desktop ?? tablet ?? mobile * 2;
    } else if (width >= tabletBreakpoint) {
      return tablet ?? mobile + 1;
    }
    return mobile;
  }

  // Get responsive max width for content
  static double getResponsiveMaxWidth(
    BuildContext context, {
    double? mobile,
    double? tablet,
    double? desktop,
  }) {
    final width = MediaQuery.of(context).size.width;
    if (width >= desktopBreakpoint) {
      return desktop ?? 1200;
    } else if (width >= tabletBreakpoint) {
      return tablet ?? 800;
    }
    return mobile ?? width;
  }

  static const Gradient primaryGradient = LinearGradient(
    colors: [primaryPink, primaryPinkDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Enhanced gradient variations
  static const Gradient softPinkGradient = LinearGradient(
    colors: [secondaryRose, surface],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const Gradient lavenderGradient = LinearGradient(
    colors: [accentLavender, surface],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Enhanced card decorations
  static BoxDecoration cardDecoration({
    Color? color,
    bool elevated = false,
    Color? borderColor,
  }) =>
      BoxDecoration(
        color: color ?? surface,
        borderRadius: BorderRadius.circular(radiusLarge),
        border: borderColor != null
            ? Border.all(color: borderColor, width: 1)
            : null,
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: primaryPink.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                  spreadRadius: 0,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
      );

  static BoxDecoration floatingCardDecoration({Color? color}) => BoxDecoration(
        color: color ?? surface,
        borderRadius: BorderRadius.circular(radiusXL),
        boxShadow: [
          BoxShadow(
            color: primaryPink.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      );

  static InputDecoration inputDecoration({
    required String label,
    IconData? prefixIcon,
    String? hintText,
    bool isError = false,
  }) =>
      InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: textSecondary, size: 20)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: borderLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: primaryPink, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: error, width: 2),
        ),
        filled: true,
        fillColor: isError ? error.withOpacity(0.05) : surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingM,
          vertical: spacingM,
        ),
        labelStyle: TextStyle(color: textSecondary, fontSize: 14),
        hintStyle: TextStyle(color: textTertiary, fontSize: 14),
      );
}

class AppWidgets {
  static Widget primaryButton({
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
    bool isSmall = false,
  }) {
    final height =
        isSmall ? AppTheme.controlHeightSmall : AppTheme.controlHeight;
    final fontSize = isSmall ? 14.0 : 16.0;
    final horizontalPadding = isSmall ? 16.0 : 24.0;

    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: onPressed != null ? AppTheme.primaryGradient : null,
        color: onPressed == null ? AppTheme.borderMedium : null,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: onPressed != null
            ? [
                BoxShadow(
                  color: AppTheme.primaryPink.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  SizedBox(
                    width: isSmall ? 16 : 20,
                    height: isSmall ? 16 : 20,
                    child: CircularProgressIndicator(
                      color: AppTheme.textOnPrimary,
                      strokeWidth: 2,
                    ),
                  )
                else if (icon != null)
                  Icon(icon,
                      color: AppTheme.textOnPrimary, size: isSmall ? 18 : 20),
                if (!isLoading && icon != null) const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: onPressed != null
                        ? AppTheme.textOnPrimary
                        : AppTheme.textTertiary,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget secondaryButton({
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isSmall = false,
  }) {
    final height =
        isSmall ? AppTheme.controlHeightSmall : AppTheme.controlHeight;
    final fontSize = isSmall ? 14.0 : 16.0;
    final horizontalPadding = isSmall ? 16.0 : 24.0;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color:
              onPressed != null ? AppTheme.borderMedium : AppTheme.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null)
                  Icon(
                    icon,
                    color: onPressed != null
                        ? AppTheme.textSecondary
                        : AppTheme.textTertiary,
                    size: isSmall ? 18 : 20,
                  ),
                if (icon != null) const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: onPressed != null
                        ? AppTheme.textSecondary
                        : AppTheme.textTertiary,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // New button styles inspired by modern beauty apps
  static Widget softButton({
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    Color? backgroundColor,
    Color? textColor,
    bool isSmall = false,
  }) {
    final height =
        isSmall ? AppTheme.controlHeightSmall : AppTheme.controlHeight;
    final fontSize = isSmall ? 14.0 : 16.0;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.secondaryRose,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.borderLight, width: 0.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isSmall ? 16 : 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null)
                  Icon(
                    icon,
                    color: textColor ?? AppTheme.primaryPink,
                    size: isSmall ? 18 : 20,
                  ),
                if (icon != null) const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: textColor ?? AppTheme.primaryPink,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget iconButton({
    required IconData icon,
    required VoidCallback? onPressed,
    Color? backgroundColor,
    Color? iconColor,
    double? size,
    bool elevated = false,
  }) {
    final buttonSize = size ?? 48.0;
    final iconSize = (size ?? 48.0) * 0.45;

    return Container(
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: AppTheme.primaryPink.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          onTap: onPressed,
          child: Center(
            child: Icon(
              icon,
              color: iconColor ?? AppTheme.textSecondary,
              size: iconSize,
            ),
          ),
        ),
      ),
    );
  }

  static Widget actionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: AppTheme.controlHeight,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                // Consumers should supply Icon+Text around this if they want custom
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingS),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPink.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: const Icon(
                  Icons.spa,
                  color: AppTheme.primaryPink,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          child,
        ],
      ),
    );
  }

  static Widget gradientHeader({
    required IconData icon,
    required String title,
    String? subtitle,
    bool fullWidth = false,
  }) {
    return Container(
      margin:
          fullWidth ? EdgeInsets.zero : const EdgeInsets.all(AppTheme.spacingL),
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment:
            fullWidth ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle,
                style: const TextStyle(fontSize: 14, color: Colors.white70)),
          ],
        ],
      ),
    );
  }

  static Widget animatedItem({
    required Widget child,
    required int index,
    Duration duration = const Duration(milliseconds: 300),
    double offsetY = 12,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration + Duration(milliseconds: (index * 20).clamp(0, 200)),
      builder: (context, value, _) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * offsetY),
            child: child,
          ),
        );
      },
    );
  }

  // Responsive wrapper widget
  static Widget responsiveWrapper({
    required Widget child,
    double? maxWidth,
    EdgeInsets? padding,
  }) {
    return Builder(
      builder: (context) {
        return Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: maxWidth ?? AppTheme.getResponsiveMaxWidth(context),
            ),
            padding: padding ?? AppTheme.getResponsivePadding(context),
            child: child,
          ),
        );
      },
    );
  }

  // Responsive grid widget
  static Widget responsiveGrid({
    required List<Widget> children,
    int? crossAxisCount,
    double? childAspectRatio,
    double? crossAxisSpacing,
    double? mainAxisSpacing,
  }) {
    return Builder(
      builder: (context) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:
                crossAxisCount ?? AppTheme.getResponsiveColumns(context),
            childAspectRatio: childAspectRatio ?? 1.0,
            crossAxisSpacing:
                crossAxisSpacing ?? AppTheme.getResponsiveSpacing(context),
            mainAxisSpacing:
                mainAxisSpacing ?? AppTheme.getResponsiveSpacing(context),
          ),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }

  // Flushbar utility function
  static void showFlushbar(
    BuildContext context,
    String message, {
    MessageType type = MessageType.info,
    Duration duration = const Duration(seconds: 3),
    FlushbarPosition position = FlushbarPosition.TOP,
  }) {
    Color backgroundColor;
    Icon icon;

    switch (type) {
      case MessageType.success:
        backgroundColor = Colors.green;
        icon = const Icon(Icons.check_circle, color: Colors.white);
        break;
      case MessageType.error:
        backgroundColor = Colors.red;
        icon = const Icon(Icons.error, color: Colors.white);
        break;
      case MessageType.warning:
        backgroundColor = Colors.orange;
        icon = const Icon(Icons.warning, color: Colors.white);
        break;
      case MessageType.info:
        backgroundColor = Colors.blue;
        icon = const Icon(Icons.info, color: Colors.white);
        break;
    }

    Flushbar(
      message: message,
      backgroundColor: backgroundColor,
      flushbarPosition: position,
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      duration: duration,
      messageColor: Colors.white,
      icon: icon,
    ).show(context);
  }

  // Modern Stats Card Widget
  static Widget statsCard({
    required String title,
    required String value,
    required IconData icon,
    Color? color,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    final cardColor = color ?? AppTheme.primaryPink;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        decoration: AppTheme.cardDecoration(elevated: true),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingS),
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Icon(
                    icon,
                    color: cardColor,
                    size: 20,
                  ),
                ),
                const Spacer(),
                if (onTap != null)
                  Icon(
                    Icons.chevron_right,
                    color: AppTheme.textTertiary,
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              value,
              style: AppTheme.headingMedium.copyWith(
                color: cardColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXS),
            Text(
              title,
              style: AppTheme.bodyMedium,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppTheme.spacingXXS),
              Text(
                subtitle,
                style: AppTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Modern List Tile
  static Widget modernListTile({
    required String title,
    String? subtitle,
    IconData? leadingIcon,
    Widget? trailing,
    VoidCallback? onTap,
    Color? backgroundColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
      decoration: AppTheme.cardDecoration(color: backgroundColor),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Row(
              children: [
                if (leadingIcon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingS),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryPink.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Icon(
                      leadingIcon,
                      color: AppTheme.primaryPink,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTheme.labelLarge),
                      if (subtitle != null) ...[
                        const SizedBox(height: AppTheme.spacingXXS),
                        Text(subtitle, style: AppTheme.bodyMedium),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: AppTheme.spacingS),
                  trailing,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Status Badge
  static Widget statusBadge({
    required String text,
    required Color color,
    bool isLarge = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? AppTheme.spacingM : AppTheme.spacingS,
        vertical: isLarge ? AppTheme.spacingS : AppTheme.spacingXS,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(
          isLarge ? AppTheme.radiusMedium : AppTheme.radiusSmall,
        ),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: (isLarge ? AppTheme.labelMedium : AppTheme.labelSmall).copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Search Field
  static Widget searchField({
    required String hintText,
    required ValueChanged<String> onChanged,
    VoidCallback? onClear,
    TextEditingController? controller,
  }) {
    return Container(
      decoration: AppTheme.cardDecoration(),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: AppTheme.inputDecoration(
          label: '',
          hintText: hintText,
          prefixIcon: Icons.search,
        ).copyWith(
          labelText: null,
          suffixIcon: onClear != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: onClear,
                  color: AppTheme.textTertiary,
                )
              : null,
        ),
      ),
    );
  }

  // Loading Shimmer Effect
  static Widget shimmerCard({
    double? height,
    double? width,
    EdgeInsets? margin,
  }) {
    return Container(
      height: height ?? 120,
      width: width,
      margin: margin ?? const EdgeInsets.only(bottom: AppTheme.spacingS),
      decoration: BoxDecoration(
        color: AppTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryPink,
          strokeWidth: 2,
        ),
      ),
    );
  }
}
