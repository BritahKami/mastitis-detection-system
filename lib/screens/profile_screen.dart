import 'package:flutter/material.dart';
import '../constants/theme_constants.dart';
import '../widgets/app_header.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/custom_primary_button.dart';
import 'login_screen.dart';

/// Profile tab screen
///
/// Features:
/// - White card layout with AppHeader ("Profile").
/// - Operator details, farm credentials, and system settings.
/// - Footer: BottomNavBar with "Profile" in active state.
class ProfileScreen extends StatelessWidget {
  final ValueChanged<int>? onTabSelected;
  final bool showBottomNav;

  const ProfileScreen({
    super.key,
    this.onTabSelected,
    this.showBottomNav = true,
  });

  void _handleSignOut(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSurface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.horizontalScreenMargin,
            right: AppSpacing.horizontalScreenMargin,
            top: AppSpacing.verticalScreenMargin,
            bottom: 8.0,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadii.containerBorderRadius,
              border: Border.all(
                color: AppColors.borderNeutral,
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: AppRadii.containerBorderRadius,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // AppHeader ("Profile")
                  const AppHeader(
                    title: 'Profile',
                    showBackButton: false,
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: CircleAvatar(
                              radius: 36,
                              backgroundColor: AppColors.badgeHealthyBg,
                              child: const Icon(
                                Icons.person_rounded,
                                size: 40,
                                color: AppColors.primaryTheme,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Farmer John Doe',
                            textAlign: TextAlign.center,
                            style: AppTypography.h2,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Green Valley Dairy Farm • Unit #4',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyRegular,
                          ),
                          const SizedBox(height: 24),

                          // Profile Info Card
                          Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundSurface,
                              borderRadius: AppRadii.containerBorderRadius,
                              border: Border.all(
                                color: AppColors.borderNeutral,
                                width: 1.0,
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildProfileInfoRow(
                                  label: 'Account ID',
                                  value: 'MDS-84920',
                                ),
                                const Divider(
                                  color: AppColors.borderNeutral,
                                  height: 20,
                                ),
                                _buildProfileInfoRow(
                                  label: 'Hardware Telemetry',
                                  value: 'Online (v2.4)',
                                ),
                                const Divider(
                                  color: AppColors.borderNeutral,
                                  height: 20,
                                ),
                                _buildProfileInfoRow(
                                  label: 'Registered Herd Size',
                                  value: '124 head',
                                ),
                                const Divider(
                                  color: AppColors.borderNeutral,
                                  height: 20,
                                ),
                                _buildProfileInfoRow(
                                  label: 'Last Calibration',
                                  value: '2026-09-12',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          CustomPrimaryButton(
                            label: 'Log out',
                            isSecondary: true,
                            leadingIcon: const Icon(
                              Icons.logout_rounded,
                              color: AppColors.primaryTheme,
                              size: 18,
                            ),
                            onPressed: () => _handleSignOut(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: showBottomNav
          ? BottomNavBar(
              activeIndex: 2,
              onTabSelected: onTabSelected ?? (index) {},
            )
          : null,
    );
  }

  Widget _buildProfileInfoRow({
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
