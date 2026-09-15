import 'package:flutter/material.dart';
import '../constants/theme_constants.dart';
import '../models/mds_models.dart';

/// Pill-shaped status badge container dynamically mapping semantic colors based on [StatusType].
///
/// Colors:
/// - healthy / absent / read: Background #E2F1E5, Text #3A7D4E
/// - atRisk / present / unread: Background #FCE4E4, Text #C54E4E
/// - pending: Background #F5EBD6, Text #8C6D33
///
/// Radius: 16px (pill shape)
class StatusBadge extends StatelessWidget {
  final String label;
  final StatusType statusType;

  const StatusBadge({
    super.key,
    required this.label,
    required this.statusType,
  });

  Color get _backgroundColor {
    switch (statusType) {
      case StatusType.healthy:
        return AppColors.badgeHealthyBg;
      case StatusType.atRisk:
        return AppColors.badgeAtRiskBg;
      case StatusType.pending:
        return AppColors.badgePendingBg;
    }
  }

  Color get _textColor {
    switch (statusType) {
      case StatusType.healthy:
        return AppColors.badgeHealthyText;
      case StatusType.atRisk:
        return AppColors.badgeAtRiskText;
      case StatusType.pending:
        return AppColors.badgePendingText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: AppRadii.badgeBorderRadius,
      ),
      child: Text(
        label,
        style: AppTypography.badgeText.copyWith(color: _textColor),
      ),
    );
  }
}
