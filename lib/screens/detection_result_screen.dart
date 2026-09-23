import 'package:flutter/material.dart';
import '../constants/theme_constants.dart';
import '../models/mds_models.dart';
import '../widgets/app_header.dart';
import '../widgets/custom_primary_button.dart';
import '../widgets/status_badge.dart';

/// Screen 4: Detection Result Screen
///
/// Specifications:
/// - Layout: White card layout with AppHeader ("Detection result").
/// - Sections:
///   - Timestamp: Displays date/time string (e.g., "2026-09-09 10:30").
///   - Sensor readings: Displays 3 variables vertically ->
///     "Temp: [Double] °C", "pH: [Double]", "Cond: [Double] mS/cm".
///   - Prediction: Displays a StatusBadge (e.g., label: "Mastitis present", state: atRisk).
/// - Actions: CustomPrimaryButton ("Back to dashboard").
/// - Return Routing: Tapping "Back to dashboard" on the Detection Result screen
///   calls Navigator.popUntil or pushes back to Screen 2 (Dashboard).
class DetectionResultScreen extends StatelessWidget {
  final DetectionResult result;
  final Cow? cow;

  const DetectionResultScreen({
    super.key,
    required this.result,
    this.cow,
  });

  void _handleBackToDashboard(BuildContext context) {
    // Pop back until the MainShellScreen root (Dashboard)
    Navigator.of(context).popUntil(
      (route) => route.isFirst || route.settings.name == '/dashboard',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSurface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.horizontalScreenMargin,
            vertical: AppSpacing.verticalScreenMargin,
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
                  // AppHeader ("Detection result")
                  AppHeader(
                    title: 'Detection result',
                    showBackButton: true,
                    onBackPressed: () => Navigator.of(context).pop(),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Target Cow identifier tag (if available)
                          if (cow != null) ...[
                            Text(
                              cow!.displayTag,
                              style: AppTypography.h1,
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Section 1: Timestamp
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14.0,
                              vertical: 10.0,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundSurface,
                              borderRadius: BorderRadius.circular(8.0),
                              border: Border.all(
                                color: AppColors.borderNeutral,
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.access_time_rounded,
                                  color: AppColors.textSecondary,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Timestamp: ',
                                  style: TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  result.timestamp,
                                  style: AppTypography.bodyRegular,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Section 2: Sensor readings (H2: 16px to 18px, Font Weight 600)
                          const Text(
                            'Sensor readings',
                            style: AppTypography.h2,
                          ),
                          const SizedBox(height: 12),

                          // 3 variables displayed vertically in a bordered container
                          Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: AppRadii.containerBorderRadius,
                              border: Border.all(
                                color: AppColors.borderNeutral,
                                width: 1.0,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Variable 1: "Temp: [Double] °C"
                                _buildSensorReadingRow(
                                  icon: Icons.thermostat_outlined,
                                  iconColor: Colors.orange.shade700,
                                  label: 'Temp: ',
                                  value:
                                      '${result.temperature.toStringAsFixed(1)} °C',
                                  isElevated: result.temperature >= 39.0,
                                ),
                                const Divider(
                                  color: AppColors.borderNeutral,
                                  height: 20,
                                ),

                                // Variable 2: "pH: [Double]"
                                _buildSensorReadingRow(
                                  icon: Icons.science_outlined,
                                  iconColor: Colors.purple.shade600,
                                  label: 'pH: ',
                                  value: result.pH.toStringAsFixed(2),
                                  isElevated: result.pH >= 6.8,
                                ),
                                const Divider(
                                  color: AppColors.borderNeutral,
                                  height: 20,
                                ),

                                // Variable 3: "Cond: [Double] mS/cm"
                                _buildSensorReadingRow(
                                  icon: Icons.bolt_outlined,
                                  iconColor: Colors.amber.shade800,
                                  label: 'Cond: ',
                                  value:
                                      '${result.conductivity.toStringAsFixed(2)} mS/cm',
                                  isElevated: result.conductivity >= 6.0,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Section 3: Prediction
                          const Text(
                            'Prediction',
                            style: AppTypography.h2,
                          ),
                          const SizedBox(height: 12),

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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Diagnostic Status',
                                  style: AppTypography.listRowTitle,
                                ),
                                // Displays StatusBadge (e.g., label: "Mastitis present", state: atRisk)
                                StatusBadge(
                                  label: result.predictionLabel,
                                  statusType: result.status,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Actions: CustomPrimaryButton ("Back to dashboard")
                          CustomPrimaryButton(
                            label: 'Back to dashboard',
                            leadingIcon: const Icon(
                              Icons.dashboard_outlined,
                              color: Colors.white,
                              size: 18,
                            ),
                            onPressed: () => _handleBackToDashboard(context),
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
    );
  }

  Widget _buildSensorReadingRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required bool isElevated,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isElevated ? AppColors.badgeAtRiskText : AppColors.primaryTheme,
          ),
        ),
        const Spacer(),
        if (isElevated)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.badgeAtRiskBg,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Elevated',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.badgeAtRiskText,
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.badgeHealthyBg,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Normal',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.badgeHealthyText,
              ),
            ),
          ),
      ],
    );
  }
}
