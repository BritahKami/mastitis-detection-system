import 'package:flutter/material.dart';
import '../constants/theme_constants.dart';

/// Reusable input text field designed for the MDS Design System.
///
/// Specifications:
/// - Supports [label] or [labelText], [hintText], [controller], [validator].
/// - 12px container border radius.
/// - Border: #E0E5E0 (Neutral Border), Focused Border: #215433 (Primary Theme).
/// - White background surface with [AppTypography.bodyRegularDark] text style.
/// - Obscure text toggle built-in when [obscureText] is true.
class CustomTextField extends StatefulWidget {
  final String? label;
  final String? labelText;
  final String? hintText;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final VoidCallback? onTap;
  final int maxLines;

  const CustomTextField({
    super.key,
    this.label,
    this.labelText,
    this.hintText,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.readOnly = false,
    this.onTap,
    this.maxLines = 1,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  void didUpdateWidget(covariant CustomTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.obscureText != widget.obscureText) {
      _obscureText = widget.obscureText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String displayLabel = widget.label ?? widget.labelText ?? '';

    Widget? effectiveSuffixIcon = widget.suffixIcon;
    if (effectiveSuffixIcon == null && widget.obscureText) {
      effectiveSuffixIcon = IconButton(
        icon: Icon(
          _obscureText
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: AppColors.textSecondary,
          size: 20,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      );
    }

    return TextFormField(
      controller: widget.controller,
      obscureText: _obscureText,
      keyboardType: widget.keyboardType,
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      onChanged: widget.onChanged,
      validator: widget.validator,
      maxLines: widget.maxLines,
      style: AppTypography.bodyRegularDark,
      decoration: InputDecoration(
        labelText: displayLabel.isNotEmpty ? displayLabel : null,
        labelStyle: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
        floatingLabelStyle: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.primaryTheme,
        ),
        hintText: widget.hintText ?? (displayLabel.isNotEmpty ? 'Enter $displayLabel' : null),
        hintStyle: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
        prefixIcon: widget.prefixIcon,
        suffixIcon: effectiveSuffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadii.containerBorderRadius,
          borderSide: const BorderSide(
            color: AppColors.borderNeutral,
            width: 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.containerBorderRadius,
          borderSide: const BorderSide(
            color: AppColors.borderNeutral,
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.containerBorderRadius,
          borderSide: const BorderSide(
            color: AppColors.primaryTheme,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadii.containerBorderRadius,
          borderSide: const BorderSide(
            color: AppColors.badgeAtRiskText,
            width: 1.0,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadii.containerBorderRadius,
          borderSide: const BorderSide(
            color: AppColors.badgeAtRiskText,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
