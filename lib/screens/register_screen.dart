import 'package:flutter/material.dart';
import '../constants/theme_constants.dart';
import '../widgets/custom_primary_button.dart';
import '../widgets/custom_text_field.dart';
import 'login_screen.dart';
import 'main_shell_screen.dart';

/// Screen 2: Auth/Register Screen
///
/// Specifications:
/// - Layout: Centered column form layout with scroll view.
/// - Header: "Create Account" (Primary Theme color: #215433).
/// - Inputs: Four CustomTextField widgets ordered sequentially:
///   1. "First Name"
///   2. "Last Name"
///   3. "Email Address"
///   4. "Password" (obscured)
/// - Actions: CustomPrimaryButton ("Register Account").
///   Add a footer TextButton ("Already have an account? Log in").
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    setState(() {
      _isLoading = true;
    });

    // Simulate account registration
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          settings: const RouteSettings(name: '/dashboard'),
          builder: (context) => const MainShellScreen(),
        ),
        (route) => false,
      );
    });
  }

  void _navigateToLogin() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSurface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.horizontalScreenMargin,
              vertical: AppSpacing.verticalScreenMargin,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Icon / Logo badge
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.badgeHealthyBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primaryTheme.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.health_and_safety_rounded,
                        size: 34,
                        color: AppColors.primaryTheme,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Header: "Create Account" (Primary Theme color)
                  const Text(
                    'Create Account',
                    textAlign: TextAlign.center,
                    style: AppTypography.h1,
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  const Text(
                    'Join the Mastitis Detection System',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Sequential Inputs: Four CustomTextField widgets
                  // 1. "First Name"
                  CustomTextField(
                    label: 'First Name',
                    controller: _firstNameController,
                    prefixIcon: const Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. "Last Name"
                  CustomTextField(
                    label: 'Last Name',
                    controller: _lastNameController,
                    prefixIcon: const Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3. "Email Address"
                  CustomTextField(
                    label: 'Email Address',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 4. "Password" (obscured)
                  CustomTextField(
                    label: 'Password',
                    controller: _passwordController,
                    obscureText: true,
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Actions: CustomPrimaryButton ("Register Account")
                  CustomPrimaryButton(
                    label: 'Register Account',
                    isLoading: _isLoading,
                    onPressed: _handleRegister,
                  ),
                  const SizedBox(height: 12),

                  // Footer TextButton ("Already have an account? Log in")
                  Center(
                    child: TextButton(
                      onPressed: _navigateToLogin,
                      child: const Text(
                        'Already have an account? Log in',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryTheme,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
