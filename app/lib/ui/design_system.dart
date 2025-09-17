import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';

enum MessageType { success, error, warning, info }

class AppTheme {
  static const Color primaryStart = Color(0xFF667eea);
  static const Color primaryEnd = Color(0xFF764ba2);

  static const Color surface = Colors.white;
  static const Color surfaceAlt = Color(0xFFF7F7FA);
  static const Color textPrimary = Colors.black;
  static const Color textSecondary = Colors.black54;

  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 16;

  static const double spacingXS = 8;
  static const double spacingS = 12;
  static const double spacingM = 16;
  static const double spacingL = 20;
  static const double spacingXL = 24;

  static const double controlHeight = 56;

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
    colors: [primaryStart, primaryEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static BoxDecoration cardDecoration({Color? color}) => BoxDecoration(
        color: color ?? surface,
        borderRadius: BorderRadius.circular(radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      );

  static InputDecoration inputDecoration({
    required String label,
    IconData? prefixIcon,
  }) =>
      InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: primaryStart, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      );
}

class AppWidgets {
  static Widget primaryButton({
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
  }) {
    return Container(
      height: AppTheme.controlHeight,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryStart.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                else if (icon != null)
                  Icon(icon, color: Colors.white, size: 20),
                if (!isLoading && icon != null) const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
  }) {
    return Container(
      height: AppTheme.controlHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) Icon(icon, color: Colors.grey[600], size: 20),
                if (icon != null) const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
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
                  color: AppTheme.primaryStart.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: const Icon(
                  Icons.spa,
                  color: AppTheme.primaryStart,
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
}
