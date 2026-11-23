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
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: 'Timestamp: ',
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                      children: [
                        TextSpan(
                          text: res.timestamp,
                          style: AppTypography.bodyRegular,
                        ),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
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
            child: SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8.0,
                runSpacing: 8.0,
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
          ),
          const SizedBox(height: 24),

          // Section 4: Model Confidence
          _buildConfidenceCard(res.confidenceScore),
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

  Widget _buildConfidenceCard(double? confidenceScore) {
    final bool hasScore = confidenceScore != null;
    final double score = hasScore ? confidenceScore : 0.0;
    final bool isLowConfidence = hasScore && score < 70.0;

    final Color barColor = !hasScore
        ? AppColors.borderNeutral
        : (isLowConfidence ? Colors.amber.shade700 : AppColors.primaryTheme);

    final String displayScore = hasScore
        ? 'Model Confidence: ${score.toStringAsFixed(1)}%'
        : 'Model Confidence: N/A';

    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  displayScore,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (hasScore) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isLowConfidence ? AppColors.badgeAtRiskBg : AppColors.badgeHealthyBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isLowConfidence ? 'Uncertain' : 'High Certainty',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isLowConfidence ? AppColors.badgeAtRiskText : AppColors.badgeHealthyText,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: LinearProgressIndicator(
              value: hasScore ? (score / 100.0).clamp(0.0, 1.0) : 0.0,
              minHeight: 8.0,
              backgroundColor: const Color(0xFFEAEAEA),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Indicates the model's prediction certainty based on the sensor readings.",
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          if (isLowConfidence) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: Colors.amber.shade300,
                  width: 1.0,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.amber.shade900,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Low confidence score (< 70%). It is recommended to clean the sensor probes with distilled water and re-test.',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
        Expanded(
          child: Text.rich(
            TextSpan(
              text: label,
              style: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary,
              ),
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isElevated ? AppColors.badgeAtRiskText : AppColors.primaryTheme,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
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
