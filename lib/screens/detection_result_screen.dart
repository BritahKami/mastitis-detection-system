import 'package:flutter/material.dart';
import '../constants/theme_constants.dart';
import '../models/mds_models.dart';
import '../services/api_service.dart';
import '../widgets/app_header.dart';
import '../widgets/custom_primary_button.dart';
import '../widgets/status_badge.dart';

/// Screen 4: Detection Result Screen
///
/// Dynamically renders the real-time sensor readings and ML diagnosis
/// received from ApiService.getLatestResult() or passed directly.
class DetectionResultScreen extends StatefulWidget {
  final DetectionResult? result;
  final Cow? cow;
  final String? cowId;

  const DetectionResultScreen({
    super.key,
    this.result,
    this.cow,
    this.cowId,
  });

  @override
  State<DetectionResultScreen> createState() => _DetectionResultScreenState();
}

class _DetectionResultScreenState extends State<DetectionResultScreen> {
  DetectionResult? _result;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _result = widget.result;
    if (_result == null) {
      final targetCowId = widget.cowId ?? widget.cow?.id;
      if (targetCowId != null && targetCowId.isNotEmpty) {
        _fetchLatestResult(targetCowId);
      }
    }
  }

  Future<void> _fetchLatestResult(String cowId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final liveResult = await ApiService().getLatestResult(cowId);
      if (mounted) {
        setState(() {
          _result = liveResult;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('ApiException: ', '').replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _handleBackToDashboard(BuildContext context) {
    // Pop back until the MainShellScreen root (Dashboard)
    Navigator.of(context).popUntil(
      (route) => route.isFirst || route.settings.name == '/dashboard',
    );
  }

  @override
  Widget build(BuildContext context) {
    final targetCowId = widget.cowId ?? widget.cow?.id;
    final displayTag = widget.cow?.displayTag ??
        (_result != null && _result!.tagNumber.isNotEmpty ? _result!.tagNumber : '');

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
                    child: _buildBody(context, displayTag, targetCowId),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, String displayTag, String? targetCowId) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primaryTheme),
            SizedBox(height: 16),
            Text(
              'Loading latest detection result...',
              style: AppTypography.bodyRegular,
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 48),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: AppTypography.bodyRegular,
              ),
              const SizedBox(height: 16),
              if (targetCowId != null)
                CustomPrimaryButton(
                  label: 'Retry',
                  onPressed: () => _fetchLatestResult(targetCowId),
                ),
            ],
          ),
        ),
      );
    }

    final res = _result;
    if (res == null) {
      return const Center(
        child: Text(
          'No test result available.',
          style: AppTypography.bodyRegular,
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Target Cow identifier tag (dynamically from Cow or DetectionResult tagNumber)
          if (displayTag.isNotEmpty) ...[
            Text(
              displayTag,
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
                  res.timestamp,
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
                  value: '${res.temperature.toStringAsFixed(1)} °C',
                  isElevated: res.temperature >= 39.0,
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
                  value: res.pH.toStringAsFixed(2),
                  isElevated: res.pH >= 6.8,
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
                  value: '${res.conductivity.toStringAsFixed(2)} mS/cm',
                  isElevated: res.conductivity >= 6.0,
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
                // Displays StatusBadge dynamically mapped from DetectionResult
                StatusBadge(
                  label: res.predictionLabel,
                  statusType: res.status,
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
