import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Custom BottomNavigationBar widget for the mobile data security application
/// Implements security-focused navigation with professional trust palette
class CustomBottomBar extends StatelessWidget {
  /// Current selected index
  final int currentIndex;

  /// Callback when a tab is tapped
  final ValueChanged<int> onTap;

  /// Bottom bar variant for different contexts
  final CustomBottomBarVariant variant;

  /// Whether to show labels
  final bool showLabels;

  /// Custom background color
  final Color? backgroundColor;

  /// Custom selected item color
  final Color? selectedItemColor;

  /// Custom unselected item color
  final Color? unselectedItemColor;

  const CustomBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.variant = CustomBottomBarVariant.primary,
    this.showLabels = true,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Determine colors based on variant
    Color effectiveBackgroundColor;
    Color effectiveSelectedColor;
    Color effectiveUnselectedColor;

    switch (variant) {
      case CustomBottomBarVariant.primary:
        effectiveBackgroundColor = backgroundColor ?? colorScheme.surface;
        effectiveSelectedColor = selectedItemColor ?? colorScheme.primary;
        effectiveUnselectedColor = unselectedItemColor ??
            (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280));
        break;
      case CustomBottomBarVariant.elevated:
        effectiveBackgroundColor = backgroundColor ?? colorScheme.surface;
        effectiveSelectedColor = selectedItemColor ?? colorScheme.primary;
        effectiveUnselectedColor = unselectedItemColor ??
            (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280));
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        boxShadow: variant == CustomBottomBarVariant.elevated
            ? [
                BoxShadow(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.08),
                  offset: const Offset(0, -2),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ]
            : null,
        border: variant == CustomBottomBarVariant.primary
            ? Border(
                top: BorderSide(
                  color: isDark
                      ? const Color(0xFF374151)
                      : const Color(0xFFE5E7EB),
                  width: 1.0,
                ),
              )
            : null,
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: _handleTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          selectedItemColor: effectiveSelectedColor,
          unselectedItemColor: effectiveUnselectedColor,
          elevation: 0,
          showSelectedLabels: showLabels,
          showUnselectedLabels: showLabels,
          selectedLabelStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.4,
          ),
          items: _buildNavigationItems(context),
        ),
      ),
    );
  }

  List<BottomNavigationBarItem> _buildNavigationItems(BuildContext context) {
    return [
      BottomNavigationBarItem(
        icon: _buildIcon(Icons.dashboard_outlined, Icons.dashboard, 0),
        label: 'Dashboard',
        tooltip: 'Main Dashboard',
      ),
      BottomNavigationBarItem(
        icon: _buildIcon(Icons.folder_outlined, Icons.folder, 1),
        label: 'Files',
        tooltip: 'File Browser',
      ),
      BottomNavigationBarItem(
        icon: _buildIcon(Icons.history_outlined, Icons.history, 2),
        label: 'History',
        tooltip: 'Operation History',
      ),
      BottomNavigationBarItem(
        icon: _buildIcon(Icons.settings_outlined, Icons.settings, 3),
        label: 'Settings',
        tooltip: 'Settings',
      ),
    ];
  }

  Widget _buildIcon(IconData outlinedIcon, IconData filledIcon, int index) {
    final isSelected = currentIndex == index;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: animation,
          child: child,
        );
      },
      child: Icon(
        isSelected ? filledIcon : outlinedIcon,
        key: ValueKey(isSelected),
        size: 24,
      ),
    );
  }

  void _handleTap(int index) {
    if (index == currentIndex) return;

    // Navigate to appropriate route based on index
    onTap(index);

    // Handle navigation based on index
    final context = navigatorKey.currentContext;
    if (context != null) {
      switch (index) {
        case 0:
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/main-dashboard',
            (route) => false,
          );
          break;
        case 1:
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/file-browser',
            (route) => false,
          );
          break;
        case 2:
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/operation-history',
            (route) => false,
          );
          break;
        case 3:
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/settings',
            (route) => false,
          );
          break;
      }
    }
  }

  /// Factory constructor for main navigation
  factory CustomBottomBar.main({
    Key? key,
    required int currentIndex,
    required ValueChanged<int> onTap,
  }) {
    return CustomBottomBar(
      key: key,
      currentIndex: currentIndex,
      onTap: onTap,
      variant: CustomBottomBarVariant.primary,
      showLabels: true,
    );
  }

  /// Factory constructor for elevated navigation
  factory CustomBottomBar.elevated({
    Key? key,
    required int currentIndex,
    required ValueChanged<int> onTap,
  }) {
    return CustomBottomBar(
      key: key,
      currentIndex: currentIndex,
      onTap: onTap,
      variant: CustomBottomBarVariant.elevated,
      showLabels: true,
    );
  }

  /// Factory constructor for compact navigation (no labels)
  factory CustomBottomBar.compact({
    Key? key,
    required int currentIndex,
    required ValueChanged<int> onTap,
  }) {
    return CustomBottomBar(
      key: key,
      currentIndex: currentIndex,
      onTap: onTap,
      variant: CustomBottomBarVariant.primary,
      showLabels: false,
    );
  }
}

/// Enum defining different bottom bar variants
enum CustomBottomBarVariant {
  /// Primary bottom bar with border
  primary,

  /// Elevated bottom bar with shadow
  elevated,
}

/// Global navigator key for navigation from static contexts
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
