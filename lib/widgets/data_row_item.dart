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
                badgeWidget,
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
          // Standard cattle list layout: Leading text on left, badge + trailing date on right
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  leadingText,
                  style: AppTypography.listRowTitle,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    badgeWidget,
                    const SizedBox(width: 12.0),
                    Text(
                      trailingText,
                      style: AppTypography.bodyRegular,
                    ),
                  ],
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
