import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Custom AppBar widget for the mobile data security application
/// Implements security-focused design patterns with professional trust palette
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// The title to display in the app bar
  final String title;

  /// Optional subtitle for additional context
  final String? subtitle;

  /// Leading widget (typically back button or menu)
  final Widget? leading;

  /// List of action widgets to display on the right
  final List<Widget>? actions;

  /// Whether to show the back button automatically
  final bool automaticallyImplyLeading;

  /// Background color override
  final Color? backgroundColor;

  /// Foreground color override
  final Color? foregroundColor;

  /// Elevation override
  final double? elevation;

  /// Whether to center the title
  final bool centerTitle;

  /// Custom bottom widget (typically TabBar)
  final PreferredSizeWidget? bottom;

  /// App bar variant for different contexts
  final CustomAppBarVariant variant;

  const CustomAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.centerTitle = true,
    this.bottom,
    this.variant = CustomAppBarVariant.primary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Determine colors based on variant
    Color effectiveBackgroundColor;
    Color effectiveForegroundColor;
    double effectiveElevation;

    switch (variant) {
      case CustomAppBarVariant.primary:
        effectiveBackgroundColor = backgroundColor ?? colorScheme.primary;
        effectiveForegroundColor = foregroundColor ?? colorScheme.onPrimary;
        effectiveElevation = elevation ?? 2.0;
        break;
      case CustomAppBarVariant.surface:
        effectiveBackgroundColor = backgroundColor ?? colorScheme.surface;
        effectiveForegroundColor = foregroundColor ?? colorScheme.onSurface;
        effectiveElevation = elevation ?? 1.0;
        break;
      case CustomAppBarVariant.transparent:
        effectiveBackgroundColor = backgroundColor ?? Colors.transparent;
        effectiveForegroundColor = foregroundColor ?? colorScheme.onSurface;
        effectiveElevation = elevation ?? 0.0;
        break;
      case CustomAppBarVariant.warning:
        effectiveBackgroundColor = backgroundColor ??
            (isDark ? const Color(0xFFF59E0B) : const Color(0xFFE17B47));
        effectiveForegroundColor = foregroundColor ?? Colors.white;
        effectiveElevation = elevation ?? 2.0;
        break;
      case CustomAppBarVariant.error:
        effectiveBackgroundColor = backgroundColor ?? colorScheme.error;
        effectiveForegroundColor = foregroundColor ?? colorScheme.onError;
        effectiveElevation = elevation ?? 2.0;
        break;
    }

    return AppBar(
      title: _buildTitle(context, effectiveForegroundColor),
      leading: leading,
      actions: _buildActions(context),
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: effectiveBackgroundColor,
      foregroundColor: effectiveForegroundColor,
      elevation: effectiveElevation,
      centerTitle: centerTitle,
      bottom: bottom,
      shadowColor: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.08),
      surfaceTintColor: Colors.transparent,
      toolbarHeight: subtitle != null ? 72.0 : 56.0,
      titleSpacing: 16.0,
    );
  }

  Widget _buildTitle(BuildContext context, Color foregroundColor) {
    if (subtitle != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment:
            centerTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: foregroundColor,
              letterSpacing: 0.15,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: foregroundColor.withValues(alpha: 0.7),
              letterSpacing: 0.4,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }

    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: foregroundColor,
        letterSpacing: 0.15,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  List<Widget>? _buildActions(BuildContext context) {
    if (actions == null) return null;

    return actions!.map((action) {
      if (action is IconButton) {
        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: action,
        );
      }
      return action;
    }).toList();
  }

  @override
  Size get preferredSize {
    double height = 56.0;
    if (subtitle != null) height = 72.0;
    if (bottom != null) height += bottom!.preferredSize.height;
    return Size.fromHeight(height);
  }

  /// Factory constructor for main dashboard app bar
  factory CustomAppBar.dashboard({
    Key? key,
    String title = 'SecureWipe',
    VoidCallback? onMenuPressed,
    VoidCallback? onSettingsPressed,
  }) {
    return CustomAppBar(
      key: key,
      title: title,
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: onMenuPressed,
        tooltip: 'Menu',
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: onSettingsPressed ??
              () {
                // Default navigation to settings
              },
          tooltip: 'Settings',
        ),
      ],
      variant: CustomAppBarVariant.primary,
    );
  }

  /// Factory constructor for file browser app bar
  factory CustomAppBar.fileBrowser({
    Key? key,
    String title = 'File Browser',
    String? subtitle,
    VoidCallback? onBackPressed,
    VoidCallback? onSearchPressed,
    VoidCallback? onMorePressed,
  }) {
    return CustomAppBar(
      key: key,
      title: title,
      subtitle: subtitle,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onBackPressed,
        tooltip: 'Back',
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: onSearchPressed,
          tooltip: 'Search',
        ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: onMorePressed,
          tooltip: 'More options',
        ),
      ],
      variant: CustomAppBarVariant.surface,
    );
  }

  /// Factory constructor for confirmation dialog app bar
  factory CustomAppBar.confirmation({
    Key? key,
    String title = 'Confirm Action',
    VoidCallback? onBackPressed,
  }) {
    return CustomAppBar(
      key: key,
      title: title,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: onBackPressed,
        tooltip: 'Cancel',
      ),
      variant: CustomAppBarVariant.warning,
    );
  }

  /// Factory constructor for wipe progress app bar
  factory CustomAppBar.wipeProgress({
    Key? key,
    String title = 'Wiping Data',
    String? subtitle,
  }) {
    return CustomAppBar(
      key: key,
      title: title,
      subtitle: subtitle,
      automaticallyImplyLeading: false,
      variant: CustomAppBarVariant.primary,
    );
  }

  /// Factory constructor for operation history app bar
  factory CustomAppBar.history({
    Key? key,
    String title = 'Operation History',
    VoidCallback? onBackPressed,
    VoidCallback? onFilterPressed,
    VoidCallback? onExportPressed,
  }) {
    return CustomAppBar(
      key: key,
      title: title,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onBackPressed,
        tooltip: 'Back',
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: onFilterPressed,
          tooltip: 'Filter',
        ),
        IconButton(
          icon: const Icon(Icons.file_download_outlined),
          onPressed: onExportPressed,
          tooltip: 'Export',
        ),
      ],
      variant: CustomAppBarVariant.surface,
    );
  }

  /// Factory constructor for settings app bar
  factory CustomAppBar.settings({
    Key? key,
    String title = 'Settings',
    VoidCallback? onBackPressed,
  }) {
    return CustomAppBar(
      key: key,
      title: title,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onBackPressed,
        tooltip: 'Back',
      ),
      variant: CustomAppBarVariant.surface,
    );
  }
}

/// Enum defining different app bar variants for various contexts
enum CustomAppBarVariant {
  /// Primary app bar with brand colors
  primary,

  /// Surface app bar with subtle elevation
  surface,

  /// Transparent app bar for overlay contexts
  transparent,

  /// Warning app bar for caution states
  warning,

  /// Error app bar for critical alerts
  error,
}
