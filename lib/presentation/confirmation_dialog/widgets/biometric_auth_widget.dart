import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class BiometricAuthWidget extends StatefulWidget {
  final Function(bool) onAuthenticationResult;
  final bool isEnabled;

  const BiometricAuthWidget({
    super.key,
    required this.onAuthenticationResult,
    required this.isEnabled,
  });

  @override
  State<BiometricAuthWidget> createState() => _BiometricAuthWidgetState();
}

class _BiometricAuthWidgetState extends State<BiometricAuthWidget> {
  bool _isAuthenticating = false;
  bool _isAuthenticated = false;
  String _authStatus = 'Tap to authenticate';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedOpacity(
      opacity: widget.isEnabled ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 300),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: _isAuthenticated
              ? (isDark ? const Color(0xFF10B981) : const Color(0xFF2D7D32))
                  .withValues(alpha: 0.1)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(2.w),
          border: Border.all(
            color: _isAuthenticated
                ? (isDark ? const Color(0xFF10B981) : const Color(0xFF2D7D32))
                : colorScheme.outline.withValues(alpha: 0.3),
            width: _isAuthenticated ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CustomIconWidget(
                  iconName: _isAuthenticated ? 'verified_user' : 'fingerprint',
                  color: _isAuthenticated
                      ? (isDark
                          ? const Color(0xFF10B981)
                          : const Color(0xFF2D7D32))
                      : colorScheme.primary,
                  size: 6.w,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Biometric Authentication',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        _isAuthenticated
                            ? 'Authenticated'
                            : 'Required for secure deletion',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _isAuthenticated
                              ? (isDark
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF2D7D32))
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _isAuthenticated
                    ? CustomIconWidget(
                        iconName: 'check_circle',
                        color: isDark
                            ? const Color(0xFF10B981)
                            : const Color(0xFF2D7D32),
                        size: 6.w,
                      )
                    : const SizedBox.shrink(),
              ],
            ),
            SizedBox(height: 3.w),
            widget.isEnabled
                ? _buildAuthButton(context)
                : _buildDisabledMessage(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthButton(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (_isAuthenticated) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: (isDark ? const Color(0xFF10B981) : const Color(0xFF2D7D32))
              .withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(1.5.w),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'check',
              color: isDark ? const Color(0xFF10B981) : const Color(0xFF2D7D32),
              size: 5.w,
            ),
            SizedBox(width: 2.w),
            Text(
              'Authentication Successful',
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    isDark ? const Color(0xFF10B981) : const Color(0xFF2D7D32),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return ElevatedButton(
      onPressed: _isAuthenticating ? null : _authenticateWithBiometrics,
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        padding: EdgeInsets.symmetric(vertical: 3.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2.w),
        ),
        elevation: 2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _isAuthenticating
              ? SizedBox(
                  width: 5.w,
                  height: 5.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                  ),
                )
              : CustomIconWidget(
                  iconName: 'fingerprint',
                  color: colorScheme.onPrimary,
                  size: 5.w,
                ),
          SizedBox(width: 3.w),
          Text(
            _isAuthenticating ? 'Authenticating...' : _authStatus,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisabledMessage(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(1.5.w),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: 'info',
            color: colorScheme.onSurfaceVariant,
            size: 4.w,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              'Complete text confirmation first',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _authenticateWithBiometrics() async {
    if (!widget.isEnabled) return;

    setState(() {
      _isAuthenticating = true;
      _authStatus = 'Authenticating...';
    });

    try {
      // Simulate biometric authentication
      await Future.delayed(const Duration(seconds: 2));

      // Simulate successful authentication (in real app, use local_auth package)
      final isAuthenticated = true; // This would be the actual biometric result

      setState(() {
        _isAuthenticated = isAuthenticated;
        _isAuthenticating = false;
        _authStatus = isAuthenticated
            ? 'Authentication successful'
            : 'Authentication failed';
      });

      widget.onAuthenticationResult(isAuthenticated);

      if (isAuthenticated) {
        // Provide haptic feedback for successful authentication
        HapticFeedback.lightImpact();
      } else {
        HapticFeedback.vibrate();
      }
    } catch (e) {
      setState(() {
        _isAuthenticated = false;
        _isAuthenticating = false;
        _authStatus = 'Authentication failed. Try again.';
      });

      widget.onAuthenticationResult(false);
      HapticFeedback.vibrate();
    }
  }
}
