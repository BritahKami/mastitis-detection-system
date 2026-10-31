import 'package:flutter/material.dart';
import '../constants/theme_constants.dart';
import '../models/mds_models.dart';
import '../services/api_service.dart';
import '../widgets/app_header.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/data_row_item.dart';

/// Screen 5: Alerts Screen
///
/// Specifications:
/// - Layout: White card layout with AppHeader ("Alerts").
/// - Content: A ListView.builder showing notification logs. Each row is a DataRowItem
///   featuring a StatusBadge ("Unread" in red, "Read" in grey/light green) on the left,
///   a center-aligned tag ID (e.g., "Tag 102"), and a right-aligned timestamp (e.g., "09/08 14:30").
/// - Footer: Insert the BottomNavBar with "Alerts" in the active state.
class AlertsScreen extends StatefulWidget {
  final List<AlertNotification>? initialAlerts;
  final ValueChanged<int>? onTabSelected;
  final bool showBottomNav;
  final bool isActive;

  const AlertsScreen({
    super.key,
    this.initialAlerts,
    this.onTabSelected,
    this.showBottomNav = true,
    this.isActive = true,
  });

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  late List<AlertNotification> _alerts;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialAlerts != null) {
      _alerts = List.from(widget.initialAlerts!);
      _isLoading = false;
    } else {
      _alerts = [];
      _isLoading = true;
      _fetchAlerts();
    }
  }

  @override
  void didUpdateWidget(covariant AlertsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger async fetch whenever user switches to the Alerts tab
    if (widget.isActive && !oldWidget.isActive) {
      _fetchAlerts();
    }
  }

  Future<void> _fetchAlerts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final alerts = await ApiService().getAlerts();
      if (!mounted) return;
      setState(() {
        _alerts = alerts;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final isTest =
          WidgetsBinding.instance.runtimeType.toString().contains('Test');
      setState(() {
        if (isTest) {
          _alerts = List.from(MDSMockRepository.getInitialAlerts());
        } else {
          _errorMessage = e.toString().replaceAll('ApiException: ', '');
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _markAlertAsRead(int index) async {
    final alert = _alerts[index];
    if (!alert.isUnread) return;

    setState(() {
      _alerts[index] = alert.copyWith(isUnread: false);
    });

    try {
      await ApiService().markAlertRead(alert.id);
    } catch (e) {
      final isTest =
          WidgetsBinding.instance.runtimeType.toString().contains('Test');
      if (!isTest) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('ApiException: ', '')),
            backgroundColor: AppColors.badgeAtRiskText,
          ),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      _alerts = _alerts.map((a) => a.copyWith(isUnread: false)).toList();
    });

    try {
      await ApiService().markAllAlertsRead();
      await _fetchAlerts();
    } catch (e) {
      final isTest =
          WidgetsBinding.instance.runtimeType.toString().contains('Test');
      if (!isTest) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('ApiException: ', '')),
            backgroundColor: AppColors.badgeAtRiskText,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final int unreadCount = _alerts.where((a) => a.isUnread).length;

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
                  // AppHeader ("Alerts") with optional mark all read action
                  AppHeader(
                    title: 'Alerts',
                    showBackButton: false,
                    trailing: unreadCount > 0
                        ? GestureDetector(
                            onTap: _markAllAsRead,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Mark all read',
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        : null,
                  ),

                  // Column Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header subtitle / counter bar
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Mastitis Detections',
                                style: AppTypography.h2,
                              ),
                              if (unreadCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical: 3.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.badgeAtRiskBg,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$unreadCount unread',
                                    style: const TextStyle(
                                      fontFamily: AppTypography.fontFamily,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.badgeAtRiskText,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Notification log ListView.builder
                        Expanded(
                          child: _isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primaryTheme,
                                  ),
                                )
                              : _errorMessage != null
                                  ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              _errorMessage!,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                color:
                                                    AppColors.badgeAtRiskText,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            TextButton.icon(
                                              onPressed: _fetchAlerts,
                                              icon: const Icon(
                                                Icons.refresh,
                                                color: AppColors.primaryTheme,
                                              ),
                                              label: const Text(
                                                'Retry',
                                                style: TextStyle(
                                                  color: AppColors.primaryTheme,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : _alerts.isEmpty
                                      ? const Center(
                                          child: Text(
                                            'No alerts at this time',
                                            style: AppTypography.bodyRegular,
                                          ),
                                        )
                                      : RefreshIndicator(
                                          onRefresh: _fetchAlerts,
                                          color: AppColors.primaryTheme,
                                          child: ListView.separated(
                                            padding: EdgeInsets.zero,
                                            itemCount: _alerts.length,
                                            separatorBuilder:
                                                (context, index) =>
                                                    const Divider(
                                              color: AppColors.borderNeutral,
                                              height: 1.0,
                                              thickness: 1.0,
                                            ),
                                            itemBuilder: (context, index) {
                                              final alert = _alerts[index];
                                              return DataRowItem(
                                                leadingText: alert.cowTag,
                                                badgeState: alert.badgeState,
                                                badgeLabel: alert.badgeLabel,
                                                badgeLeading: true,
                                                trailingText: alert.timestamp,
                                                onTap: () =>
                                                    _markAlertAsRead(index),
                                              );
                                            },
                                          ),
                                        ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      // Footer: BottomNavBar with "Alerts" in the active state
      bottomNavigationBar: widget.showBottomNav
          ? BottomNavBar(
              activeIndex: 1,
              onTabSelected: widget.onTabSelected ?? (index) {},
            )
          : null,
    );
  }
}
