import 'package:flutter/material.dart';
import '../constants/theme_constants.dart';

/// Full-width action button.
///
/// Specifications:
/// - Accepts [label] (String) and [onPressed] (VoidCallback? / Function?)
/// - Background #215433 (or outline if [isSecondary] is true)
/// - White text centered (or green text if [isSecondary])
/// - 8px border radius
/// - 48px height
class CustomPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isSecondary;
  final Widget? leadingIcon;
  final bool isLoading;

  const CustomPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isSecondary = false,
    this.leadingIcon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48.0,
      child: Material(
        color: isSecondary ? Colors.white : AppColors.primaryTheme,
        borderRadius: AppRadii.buttonBorderRadius,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: AppRadii.buttonBorderRadius,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: AppRadii.buttonBorderRadius,
              border: isSecondary
                  ? Border.all(color: AppColors.primaryTheme, width: 1.5)
                  : null,
            ),
            alignment: Alignment.center,
            child: isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isSecondary ? AppColors.primaryTheme : Colors.white,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (leadingIcon != null) ...[
                        leadingIcon!,
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: AppTypography.buttonText.copyWith(
                          color: isSecondary
                              ? AppColors.primaryTheme
                              : Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
