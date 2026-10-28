import 'package:flutter/material.dart';
import '../constants/theme_constants.dart';
import '../models/mds_models.dart';
import '../widgets/app_header.dart';
import '../widgets/custom_primary_button.dart';
import 'detection_result_screen.dart';
import '../services/api_service.dart';

/// Screen 3: Cow Profile Screen
///
/// Displays cow metadata, enables diagnostic test initiation,
/// and renders the full, untruncated historical test records with sensor telemetry.
class CowProfileScreen extends StatefulWidget {
  final Cow cow;

  const CowProfileScreen({
    super.key,
    required this.cow,
  });

  @override
  State<CowProfileScreen> createState() => _CowProfileScreenState();
}

class _CowProfileScreenState extends State<CowProfileScreen> {
  late Cow _cow;
  bool _isTesting = false;
  bool _isLoadingDetails = false;

  @override
  void initState() {
    super.initState();
    _cow = widget.cow;
    _loadCowDetails();
  }

  Future<void> _loadCowDetails() async {
    setState(() {
      _isLoadingDetails = true;
    });

    try {
      final updatedCow = await ApiService().getCowDetails(widget.cow.id);
      if (mounted) {
        setState(() {
          _cow = updatedCow;
          _isLoadingDetails = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingDetails = false;
        });
      }
    }
  }

  Future<void> _runDiagnosticTest() async {
    setState(() {
      _isTesting = true;
    });

    try {
      // 1. Trigger active 3-minute test session lock on FastAPI via ApiService
      await ApiService().initiateTest(_cow.id);

      // 2. Prompt user to submerge sensors
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test session active. Please submerge sensors into milk sample.'),
          duration: Duration(seconds: 4),
          backgroundColor: AppColors.primaryTheme,
        ),
      );

      // 3. Poll for live reading
      DetectionResult? liveResult;
      const int maxPollAttempts = 15; // Poll up to ~30 seconds
      for (int i = 0; i < maxPollAttempts; i++) {
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        try {
          liveResult = await ApiService().getLatestResult(_cow.id);
          break;
        } on ApiException catch (e) {
          if (e.message.toLowerCase().contains('pending')) {
            continue;
          }
          if (i == maxPollAttempts - 1) rethrow;
        }
      }

      if (liveResult == null) {
        throw Exception('No recent reading received from ESP32 within test window.');
      }

      if (!mounted) return;

      // 4. Navigate to Detection Result Screen
      await Navigator.of(context).push(
        MaterialPageRoute(
          settings: const RouteSettings(name: '/detection_result'),
          builder: (context) => DetectionResultScreen(
            result: liveResult,
            cow: _cow,
            cowId: _cow.id,
          ),
        ),
      );

      // 5. Automatically refresh test history and status upon returning
      if (mounted) {
        _loadCowDetails();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Diagnostic Error: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isTesting = false;
        });
      }
    }
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
                  AppHeader(
                    title: 'Cow profile',
                    showBackButton: true,
                    onBackPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _loadCowDetails,
                      color: AppColors.primaryTheme,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Metadata Card
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'Tag number: ',
                                        style: AppTypography.h2,
                                      ),
                                      Text(
                                        _cow.rawTagId,
                                        style: AppTypography.h2.copyWith(
                                          color: AppColors.primaryTheme,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      const Text(
                                        'Breed: ',
                                        style: TextStyle(
                                          fontFamily: AppTypography.fontFamily,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        _cow.breed,
                                        style: AppTypography.bodyRegularDark,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Text(
                                        'Age: ',
                                        style: TextStyle(
                                          fontFamily: AppTypography.fontFamily,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        '${_cow.age} years',
                                        style: AppTypography.bodyRegularDark,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Actions: CustomPrimaryButton ("Select cow to test")
                            CustomPrimaryButton(
                              label: _isTesting ? 'Awaiting Sensor Data...' : 'Select cow to test',
                              isLoading: _isTesting,
                              leadingIcon: const Icon(
                                Icons.biotech_outlined,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: _isTesting ? null : _runDiagnosticTest,
                            ),
                            const SizedBox(height: 24),

                            // Section Header: "History"
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'History',
                                  style: AppTypography.h2,
                                ),
                                if (_isLoadingDetails)
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primaryTheme,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Full History List: Rendering date, time, diagnosis, and sensor metrics
                            if (_cow.history.isEmpty && !_isLoadingDetails)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24.0),
                                child: Center(
                                  child: Text(
                                    'No test history available',
                                    style: AppTypography.bodyRegular,
                                  ),
                                ),
                              )
                            else if (_cow.history.isNotEmpty)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: AppRadii.containerBorderRadius,
                                  border: Border.all(
                                    color: AppColors.borderNeutral,
                                    width: 1.0,
                                  ),
                                ),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _cow.history.length,
                                  separatorBuilder: (context, index) => const Divider(
                                    color: AppColors.borderNeutral,
                                    height: 1.0,
                                    thickness: 1.0,
                                  ),
                                  itemBuilder: (context, index) {
                                    final record = _cow.history[index];
                                    final isAtRisk = record.mastitisPresent;
                                    final statusColor = isAtRisk
                                        ? AppColors.badgeAtRiskText
                                        : AppColors.badgeHealthyText;
                                    final statusBg = isAtRisk
                                        ? AppColors.badgeAtRiskBg
                                        : AppColors.badgeHealthyBg;

                                    final String timeDisplay = record.formattedTime.isNotEmpty
                                        ? '${record.date}  ${record.formattedTime}'
                                        : record.date;

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                        vertical: 12.0,
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.calendar_today_outlined,
                                                    size: 14,
                                                    color: AppColors.textSecondary,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    timeDisplay,
                                                    style: const TextStyle(
                                                      fontFamily: AppTypography.fontFamily,
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w600,
                                                      color: AppColors.textPrimary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10.0,
                                                  vertical: 4.0,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: statusBg,
                                                  borderRadius: AppRadii.badgeBorderRadius,
                                                ),
                                                child: Text(
                                                  record.label,
                                                  style: AppTypography.badgeText.copyWith(
                                                    color: statusColor,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (record.temperature > 0 || record.pH > 0 || record.electricalConductivity > 0) ...[
                                            const SizedBox(height: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 10.0,
                                                vertical: 6.0,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.backgroundSurface,
                                                borderRadius: BorderRadius.circular(6.0),
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    'Temp: ${record.temperature.toStringAsFixed(1)} °C',
                                                    style: const TextStyle(
                                                      fontFamily: AppTypography.fontFamily,
                                                      fontSize: 12,
                                                      color: AppColors.textPrimary,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                  Text(
                                                    'pH: ${record.pH.toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                      fontFamily: AppTypography.fontFamily,
                                                      fontSize: 12,
                                                      color: AppColors.textPrimary,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Cond: ${record.electricalConductivity.toStringAsFixed(2)} mS/cm',
                                                    style: const TextStyle(
                                                      fontFamily: AppTypography.fontFamily,
                                                      fontSize: 12,
                                                      color: AppColors.textPrimary,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
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
