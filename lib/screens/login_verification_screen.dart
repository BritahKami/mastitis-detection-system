import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/theme_constants.dart';
import '../services/api_service.dart';
import '../widgets/custom_primary_button.dart';
import 'main_shell_screen.dart';

/// Screen for Two-Factor Login Verification (2FA Step 2)
class LoginVerificationScreen extends StatefulWidget {
  final String email;
  final String? password; // Optional, used for instant resend if available

  const LoginVerificationScreen({
    super.key,
    required this.email,
    this.password,
  });

  @override
  State<LoginVerificationScreen> createState() => _LoginVerificationScreenState();
}

class _LoginVerificationScreenState extends State<LoginVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final code = _codeController.text.trim();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the complete 6-digit verification code.'),
          backgroundColor: AppColors.badgeAtRiskText,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ApiService().loginStep2(widget.email, code);
      if (!mounted) return;

      // Navigate to Dashboard clearing auth navigation stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          settings: const RouteSettings(name: '/dashboard'),
          builder: (context) => const MainShellScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('ApiException: ', '')),
          backgroundColor: AppColors.badgeAtRiskText,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleResendCode() async {
    setState(() {
      _isResending = true;
    });

    try {
      if (widget.password != null && widget.password!.isNotEmpty) {
        await ApiService().loginStep1(widget.email, widget.password!);
      } else {
        // Fallback to sending OTP via forgotPassword/login resend if password not stored
        await ApiService().forgotPassword(widget.email);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A fresh verification code has been dispatched to your email.'),
          backgroundColor: AppColors.badgeHealthyText,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('ApiException: ', '')),
          backgroundColor: AppColors.badgeAtRiskText,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSurface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
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
                  // App Icon / Security badge
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
                        Icons.mark_email_read_rounded,
                        size: 34,
                        color: AppColors.primaryTheme,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Header H1: 24px, 600 Semi-bold, #215433
                  const Text(
                    'Two-Factor Verification',
                    textAlign: TextAlign.center,
                    style: AppTypography.h1,
                  ),
                  const SizedBox(height: 8),

                  // Subtitle showing user email
                  Text(
                    'A 6-digit verification code has been sent to\n${widget.email}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // OTP Container
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppRadii.containerBorderRadius,
                      border: Border.all(
                        color: AppColors.borderNeutral,
                        width: 1.0,
                      ),
                    ),
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Enter 6-Digit Code',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 6,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          style: const TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 12,
                            color: AppColors.primaryTheme,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: '000000',
                            hintStyle: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 12,
                              color: AppColors.textSecondary.withValues(alpha: 0.3),
                            ),
                            filled: true,
                            fillColor: AppColors.backgroundSurface,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: const BorderSide(
                                color: AppColors.borderNeutral,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: const BorderSide(
                                color: AppColors.borderNeutral,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: const BorderSide(
                                color: AppColors.primaryTheme,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Actions: Verify Button
                  CustomPrimaryButton(
                    label: 'Verify & Log in',
                    isLoading: _isLoading,
                    onPressed: _handleVerify,
                  ),
                  const SizedBox(height: 12),

                  // Resend Code Option
                  Center(
                    child: TextButton.icon(
                      onPressed: _isResending ? null : _handleResendCode,
                      icon: _isResending
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryTheme,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.refresh_rounded,
                              size: 18,
                              color: AppColors.primaryTheme,
                            ),
                      label: Text(
                        _isResending ? 'Sending...' : 'Resend Code',
                        style: const TextStyle(
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
