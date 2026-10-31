import 'package:flutter/material.dart';
import '../constants/theme_constants.dart';
import '../models/mds_models.dart';
import 'status_badge.dart';

/// Standardized list row widget for cattle lists and alert logs.
///
/// Specifications:
/// - Accepts [leadingText] (String, e.g., "Tag 101")
/// - Accepts [badgeState] (StatusType enum passed to [StatusBadge])
/// - Accepts [trailingText] (String, e.g., "09/01" or timestamps)
/// - Uses a [Row] with [MainAxisAlignment.spaceBetween]
/// - Supports [badgeLeading] mode for notification/alert rows
/// - Supports [onTap] callback for navigation
class DataRowItem extends StatelessWidget {
  final String leadingText;
  final StatusType badgeState;
  final String trailingText;
  final String? badgeLabel;
  final bool badgeLeading;
  final VoidCallback? onTap;

  const DataRowItem({
    super.key,
    required this.leadingText,
    required this.badgeState,
    required this.trailingText,
    this.badgeLabel,
    this.badgeLeading = false,
    this.onTap,
  });

  String get _resolvedBadgeLabel {
    if (badgeLabel != null && badgeLabel!.isNotEmpty) {
      return badgeLabel!;
    }
    switch (badgeState) {
      case StatusType.healthy:
        return 'Healthy';
      case StatusType.atRisk:
        return 'At risk';
      case StatusType.pending:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget badgeWidget = StatusBadge(
      label: _resolvedBadgeLabel,
      statusType: badgeState,
    );

    final Widget content = Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: badgeLeading
          // Alert layout: Badge on left, center-aligned tag ID, right-aligned timestamp
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 80.0,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: badgeWidget,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      leadingText,
                      textAlign: TextAlign.center,
                      style: AppTypography.listRowTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Text(
                  trailingText,
                  style: AppTypography.bodyRegular.copyWith(
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            )
          // Standard cattle list layout: Left column (Tag), Center fixed column (Badge), Right column (Timestamp/Status)
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Cow Tag Number (Left Column pinned to far left)
                Expanded(
                  flex: 3,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      leadingText,
                      style: AppTypography.listRowTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                // 2. Health Status Badge (Dedicated, fixed-width container with centered alignment)
                SizedBox(
                  width: 90.0,
                  child: Center(
                    child: badgeWidget,
                  ),
                ),
                // 3. Test Timestamp / Status Text (Dedicated right-aligned container pinned flush to trailing margin)
                Expanded(
                  flex: 4,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      trailingText,
                      textAlign: TextAlign.right,
                      style: AppTypography.bodyRegular.copyWith(
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: AppColors.primaryTheme.withValues(alpha: 0.08),
          highlightColor: AppColors.primaryTheme.withValues(alpha: 0.04),
          child: content,
        ),
      );
    }

    return content;
  }
}
