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
  final String firstName;
  final String lastName;
  final String email;
  final int cowsRegistered;
  final ValueChanged<int>? onTabSelected;
  final bool showBottomNav;

  const ProfileScreen({
    super.key,
    this.firstName = 'John',
    this.lastName = 'Doe',
    this.email = 'farmer@dairyfarm.com',
    this.cowsRegistered = 5,
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
                          // Header Area: Centered circular avatar icon (light green background, dark green user icon)
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

                          // Farmer's full name (e.g., "Farmer John Doe").
                          // CRITICAL: Do not include a subtitle string below the name.
                          Text(
                            'Farmer $firstName $lastName',
                            textAlign: TextAlign.center,
                            style: AppTypography.h2,
                          ),
                          const SizedBox(height: 24),

                          // Data Card: Bordered container (#E0E5E0) with rounded edges containing four data rows
                          Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundSurface,
                              borderRadius: AppRadii.containerBorderRadius,
                              border: Border.all(
                                color: const Color(0xFFE0E5E0),
                                width: 1.0,
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildProfileInfoRow(
                                  label: 'First Name',
                                  value: firstName,
                                ),
                                const Divider(
                                  color: Color(0xFFE0E5E0),
                                  height: 24,
                                  thickness: 1.0,
                                ),
                                _buildProfileInfoRow(
                                  label: 'Last Name',
                                  value: lastName,
                                ),
                                const Divider(
                                  color: Color(0xFFE0E5E0),
                                  height: 24,
                                  thickness: 1.0,
                                ),
                                _buildProfileInfoRow(
                                  label: 'Email Address',
                                  value: email,
                                ),
                                const Divider(
                                  color: Color(0xFFE0E5E0),
                                  height: 24,
                                  thickness: 1.0,
                                ),
                                _buildProfileInfoRow(
                                  label: 'Cows Registered',
                                  value: cowsRegistered.toString(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Actions: A full-width outlined button with an exit icon and the label "Log out"
                          CustomPrimaryButton(
                            label: 'Log out',
                            isSecondary: true,
                            leadingIcon: const Icon(
                              Icons.exit_to_app_rounded,
                              color: AppColors.primaryTheme,
                              size: 20,
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
      // Footer: BottomNavBar with "Profile" active
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
        // Left side holds the label (grey text)
        Text(
          label,
          style: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
        ),
        // Right side holds the dynamic value (dark text, bolded)
        Text(
          value,
          style: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
