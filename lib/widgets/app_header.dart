import 'package:flutter/material.dart';
import '../constants/theme_constants.dart';

/// Reusable container matching the top section of interior screens.
///
/// Features:
/// - Parameters: [title] (String), optional [showBackButton], optional [onBackPressed], optional [trailing]
/// - Solid background #215433
/// - White text (16px, Semi-bold)
/// - Top-left and top-right border radii (12px)
/// - Bottom padding
class AppHeader extends StatelessWidget {
  final String title;
  final bool? showBackButton;
  final VoidCallback? onBackPressed;
  final Widget? trailing;

  const AppHeader({
    super.key,
    required this.title,
    this.showBackButton,
    this.onBackPressed,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final bool canPop = showBackButton ?? Navigator.of(context).canPop();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 14.0,
        bottom: 14.0,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primaryTheme,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppRadii.container),
          topRight: Radius.circular(AppRadii.container),
        ),
      ),
      child: Row(
        children: [
          if (canPop) ...[
            GestureDetector(
              onTap: onBackPressed ?? () => Navigator.of(context).maybePop(),
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.only(right: 10.0),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
          Expanded(
            child: Text(
              title,
              style: AppTypography.appHeaderTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
