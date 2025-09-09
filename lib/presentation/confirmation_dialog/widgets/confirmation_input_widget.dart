import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class ConfirmationInputWidget extends StatefulWidget {
  final Function(bool) onConfirmationChanged;
  final Function(bool) onCheckboxChanged;

  const ConfirmationInputWidget({
    super.key,
    required this.onConfirmationChanged,
    required this.onCheckboxChanged,
  });

  @override
  State<ConfirmationInputWidget> createState() =>
      _ConfirmationInputWidgetState();
}

class _ConfirmationInputWidgetState extends State<ConfirmationInputWidget> {
  final TextEditingController _textController = TextEditingController();
  bool _isTextValid = false;
  bool _isCheckboxChecked = false;
  bool _showTextError = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_validateText);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _validateText() {
    final isValid = _textController.text.trim().toUpperCase() == 'DELETE';
    setState(() {
      _isTextValid = isValid;
      _showTextError = _textController.text.isNotEmpty && !isValid;
    });
    _updateConfirmationStatus();
  }

  void _updateConfirmationStatus() {
    final isFullyConfirmed = _isTextValid && _isCheckboxChecked;
    widget.onConfirmationChanged(isFullyConfirmed);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(2.w),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Confirmation Required',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 4.w),
          _buildTextConfirmation(context),
          SizedBox(height: 4.w),
          _buildCheckboxConfirmation(context),
        ],
      ),
    );
  }

  Widget _buildTextConfirmation(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type "DELETE" to confirm:',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 2.w),
        TextFormField(
          controller: _textController,
          decoration: InputDecoration(
            hintText: 'Type DELETE here',
            prefixIcon: Padding(
              padding: EdgeInsets.all(3.w),
              child: CustomIconWidget(
                iconName: 'keyboard',
                color: colorScheme.onSurfaceVariant,
                size: 5.w,
              ),
            ),
            suffixIcon: _isTextValid
                ? Padding(
                    padding: EdgeInsets.all(3.w),
                    child: CustomIconWidget(
                      iconName: 'check_circle',
                      color: isDark
                          ? const Color(0xFF10B981)
                          : const Color(0xFF2D7D32),
                      size: 5.w,
                    ),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(2.w),
              borderSide: BorderSide(
                color: _showTextError
                    ? (isDark
                        ? const Color(0xFFEF4444)
                        : const Color(0xFFC5282F))
                    : colorScheme.outline,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(2.w),
              borderSide: BorderSide(
                color: _showTextError
                    ? (isDark
                        ? const Color(0xFFEF4444)
                        : const Color(0xFFC5282F))
                    : colorScheme.outline,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(2.w),
              borderSide: BorderSide(
                color: _showTextError
                    ? (isDark
                        ? const Color(0xFFEF4444)
                        : const Color(0xFFC5282F))
                    : colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(2.w),
              borderSide: BorderSide(
                color:
                    isDark ? const Color(0xFFEF4444) : const Color(0xFFC5282F),
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(2.w),
              borderSide: BorderSide(
                color:
                    isDark ? const Color(0xFFEF4444) : const Color(0xFFC5282F),
                width: 2,
              ),
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.w),
          ),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
            letterSpacing: 2.0,
          ),
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z]')),
            LengthLimitingTextInputFormatter(6),
          ],
          onChanged: (value) {
            // Trigger validation on each change
          },
        ),
        _showTextError
            ? Padding(
                padding: EdgeInsets.only(top: 1.w, left: 2.w),
                child: Text(
                  'Please type "DELETE" exactly as shown',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? const Color(0xFFEF4444)
                        : const Color(0xFFC5282F),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildCheckboxConfirmation(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () {
        setState(() {
          _isCheckboxChecked = !_isCheckboxChecked;
        });
        widget.onCheckboxChanged(_isCheckboxChecked);
        _updateConfirmationStatus();
      },
      borderRadius: BorderRadius.circular(2.w),
      child: Padding(
        padding: EdgeInsets.all(2.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _isCheckboxChecked,
              onChanged: (value) {
                setState(() {
                  _isCheckboxChecked = value ?? false;
                });
                widget.onCheckboxChanged(_isCheckboxChecked);
                _updateConfirmationStatus();
              },
              activeColor: colorScheme.primary,
              checkColor: colorScheme.onPrimary,
              side: BorderSide(
                color: colorScheme.outline,
                width: 2,
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 2.w),
                child: Text(
                  'I understand that this action will permanently delete the selected data and cannot be undone. I take full responsibility for this decision.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
