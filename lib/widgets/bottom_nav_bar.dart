import 'package:flutter/material.dart';
import '../constants/theme_constants.dart';

enum MDSNavTab {
  dash,
  alerts,
  profile,
}

/// A persistent navigation row containing three rounded rectangular elements:
/// "Dash", "Alerts", and "Profile".
///
/// Specifications:
/// - Active State: Background #215433, Text #FFFFFF
/// - Inactive State: Background #FFFFFF, Border 1px solid #E0E5E0, Text #215433
/// - 12px border radius for items
class BottomNavBar extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onTabSelected;

  const BottomNavBar({
    super.key,
    required this.activeIndex,
    required this.onTabSelected,
  });

  static const List<String> tabLabels = ['Dash', 'Alerts', 'Profile'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: AppColors.borderNeutral, width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(tabLabels.length, (index) {
            final bool isActive = activeIndex == index;
            final String label = tabLabels[index];

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 0 : 6.0,
                  right: index == tabLabels.length - 1 ? 0 : 6.0,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onTabSelected(index),
                    borderRadius: AppRadii.navBarBorderRadius,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeInOut,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.primaryTheme : Colors.white,
                        borderRadius: AppRadii.navBarBorderRadius,
                        border: isActive
                            ? null
                            : Border.all(
                                color: AppColors.borderNeutral,
                                width: 1.0,
                              ),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isActive ? Colors.white : AppColors.primaryTheme,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
