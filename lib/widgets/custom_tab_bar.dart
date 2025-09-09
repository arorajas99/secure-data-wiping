import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Custom TabBar widget for the mobile data security application
/// Implements security-focused tab navigation with professional trust palette
class CustomTabBar extends StatelessWidget implements PreferredSizeWidget {
  /// List of tab labels
  final List<String> tabs;

  /// Current selected index
  final int currentIndex;

  /// Callback when a tab is tapped
  final ValueChanged<int> onTap;

  /// Tab bar variant for different contexts
  final CustomTabBarVariant variant;

  /// Whether tabs are scrollable
  final bool isScrollable;

  /// Custom indicator color
  final Color? indicatorColor;

  /// Custom label color
  final Color? labelColor;

  /// Custom unselected label color
  final Color? unselectedLabelColor;

  /// Custom background color
  final Color? backgroundColor;

  /// Tab controller for advanced usage
  final TabController? controller;

  const CustomTabBar({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
    this.variant = CustomTabBarVariant.primary,
    this.isScrollable = false,
    this.indicatorColor,
    this.labelColor,
    this.unselectedLabelColor,
    this.backgroundColor,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Determine colors based on variant
    Color effectiveIndicatorColor;
    Color effectiveLabelColor;
    Color effectiveUnselectedLabelColor;
    Color effectiveBackgroundColor;

    switch (variant) {
      case CustomTabBarVariant.primary:
        effectiveIndicatorColor = indicatorColor ?? colorScheme.primary;
        effectiveLabelColor = labelColor ?? colorScheme.primary;
        effectiveUnselectedLabelColor = unselectedLabelColor ??
            (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280));
        effectiveBackgroundColor = backgroundColor ?? colorScheme.surface;
        break;
      case CustomTabBarVariant.surface:
        effectiveIndicatorColor = indicatorColor ?? colorScheme.primary;
        effectiveLabelColor = labelColor ?? colorScheme.onSurface;
        effectiveUnselectedLabelColor = unselectedLabelColor ??
            (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280));
        effectiveBackgroundColor = backgroundColor ?? colorScheme.surface;
        break;
      case CustomTabBarVariant.transparent:
        effectiveIndicatorColor = indicatorColor ?? colorScheme.primary;
        effectiveLabelColor = labelColor ?? colorScheme.onSurface;
        effectiveUnselectedLabelColor = unselectedLabelColor ??
            (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280));
        effectiveBackgroundColor = backgroundColor ?? Colors.transparent;
        break;
      case CustomTabBarVariant.accent:
        effectiveIndicatorColor = indicatorColor ??
            (isDark ? const Color(0xFFA78BFA) : const Color(0xFF8B5CF6));
        effectiveLabelColor = labelColor ??
            (isDark ? const Color(0xFFA78BFA) : const Color(0xFF8B5CF6));
        effectiveUnselectedLabelColor = unselectedLabelColor ??
            (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280));
        effectiveBackgroundColor = backgroundColor ?? colorScheme.surface;
        break;
    }

    return Container(
      color: effectiveBackgroundColor,
      child: TabBar(
        controller: controller,
        tabs: _buildTabs(context),
        onTap: onTap,
        isScrollable: isScrollable,
        indicatorColor: effectiveIndicatorColor,
        indicatorWeight: 2.0,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: effectiveLabelColor,
        unselectedLabelColor: effectiveUnselectedLabelColor,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.1,
        ),
        labelPadding:
            isScrollable ? const EdgeInsets.symmetric(horizontal: 16.0) : null,
        indicatorPadding: const EdgeInsets.symmetric(horizontal: 8.0),
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        dividerColor:
            isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
        dividerHeight: 1.0,
      ),
    );
  }

  List<Widget> _buildTabs(BuildContext context) {
    return tabs.asMap().entries.map((entry) {
      final index = entry.key;
      final label = entry.value;
      final isSelected = currentIndex == index;

      return Tab(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6.0),
            color: isSelected && variant == CustomTabBarVariant.accent
                ? (Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFA78BFA).withValues(alpha: 0.1)
                    : const Color(0xFF8B5CF6).withValues(alpha: 0.1))
                : Colors.transparent,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }).toList();
  }

  @override
  Size get preferredSize => const Size.fromHeight(48.0);

  /// Factory constructor for file type tabs
  factory CustomTabBar.fileTypes({
    Key? key,
    required int currentIndex,
    required ValueChanged<int> onTap,
    TabController? controller,
  }) {
    return CustomTabBar(
      key: key,
      tabs: const ['All Files', 'Documents', 'Images', 'Videos', 'Apps'],
      currentIndex: currentIndex,
      onTap: onTap,
      controller: controller,
      variant: CustomTabBarVariant.primary,
      isScrollable: true,
    );
  }

  /// Factory constructor for operation status tabs
  factory CustomTabBar.operationStatus({
    Key? key,
    required int currentIndex,
    required ValueChanged<int> onTap,
    TabController? controller,
  }) {
    return CustomTabBar(
      key: key,
      tabs: const ['All', 'Completed', 'Failed', 'In Progress'],
      currentIndex: currentIndex,
      onTap: onTap,
      controller: controller,
      variant: CustomTabBarVariant.surface,
      isScrollable: false,
    );
  }

  /// Factory constructor for security level tabs
  factory CustomTabBar.securityLevels({
    Key? key,
    required int currentIndex,
    required ValueChanged<int> onTap,
    TabController? controller,
  }) {
    return CustomTabBar(
      key: key,
      tabs: const ['Quick', 'Standard', 'Secure', 'Military'],
      currentIndex: currentIndex,
      onTap: onTap,
      controller: controller,
      variant: CustomTabBarVariant.accent,
      isScrollable: false,
    );
  }

  /// Factory constructor for settings categories
  factory CustomTabBar.settingsCategories({
    Key? key,
    required int currentIndex,
    required ValueChanged<int> onTap,
    TabController? controller,
  }) {
    return CustomTabBar(
      key: key,
      tabs: const ['General', 'Security', 'Privacy', 'Advanced'],
      currentIndex: currentIndex,
      onTap: onTap,
      controller: controller,
      variant: CustomTabBarVariant.surface,
      isScrollable: true,
    );
  }

  /// Factory constructor for wipe methods
  factory CustomTabBar.wipeMethods({
    Key? key,
    required int currentIndex,
    required ValueChanged<int> onTap,
    TabController? controller,
  }) {
    return CustomTabBar(
      key: key,
      tabs: const ['Single Pass', 'DoD 5220.22-M', 'Gutmann', 'Random'],
      currentIndex: currentIndex,
      onTap: onTap,
      controller: controller,
      variant: CustomTabBarVariant.primary,
      isScrollable: true,
    );
  }

  /// Factory constructor for transparent overlay tabs
  factory CustomTabBar.overlay({
    Key? key,
    required List<String> tabs,
    required int currentIndex,
    required ValueChanged<int> onTap,
    TabController? controller,
  }) {
    return CustomTabBar(
      key: key,
      tabs: tabs,
      currentIndex: currentIndex,
      onTap: onTap,
      controller: controller,
      variant: CustomTabBarVariant.transparent,
      isScrollable: tabs.length > 4,
    );
  }
}

/// Enum defining different tab bar variants for various contexts
enum CustomTabBarVariant {
  /// Primary tab bar with brand colors
  primary,

  /// Surface tab bar with subtle styling
  surface,

  /// Transparent tab bar for overlay contexts
  transparent,

  /// Accent tab bar with purple highlights
  accent,
}
