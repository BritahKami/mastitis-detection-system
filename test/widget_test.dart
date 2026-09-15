import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mastitis_detection_app/constants/theme_constants.dart';
import 'package:mastitis_detection_app/main.dart';
import 'package:mastitis_detection_app/models/mds_models.dart';
import 'package:mastitis_detection_app/widgets/app_header.dart';
import 'package:mastitis_detection_app/widgets/bottom_nav_bar.dart';
import 'package:mastitis_detection_app/widgets/custom_primary_button.dart';
import 'package:mastitis_detection_app/widgets/data_row_item.dart';
import 'package:mastitis_detection_app/widgets/status_badge.dart';

void main() {
  group('MDS Design System & Theme Constants', () {
    test('Colors match specifications', () {
      expect(AppColors.primaryTheme, const Color(0xFF215433));
      expect(AppColors.backgroundSurface, const Color(0xFFF9FBF9));
      expect(AppColors.textPrimary, const Color(0xFF333333));
      expect(AppColors.textSecondary, const Color(0xFF7A7A7A));
      expect(AppColors.borderNeutral, const Color(0xFFE0E5E0));

      // Semantic badge colors
      expect(AppColors.badgeHealthyBg, const Color(0xFFE2F1E5));
      expect(AppColors.badgeHealthyText, const Color(0xFF3A7D4E));
      expect(AppColors.badgeAtRiskBg, const Color(0xFFFCE4E4));
      expect(AppColors.badgeAtRiskText, const Color(0xFFC54E4E));
      expect(AppColors.badgePendingBg, const Color(0xFFF5EBD6));
      expect(AppColors.badgePendingText, const Color(0xFF8C6D33));
    });

    test('Typography and Radii match specifications', () {
      expect(AppTypography.h1.fontSize, 24);
      expect(AppTypography.h1.fontWeight, FontWeight.w600);
      expect(AppTypography.h1.color, AppColors.primaryTheme);

      expect(AppTypography.h2.fontSize, 18);
      expect(AppTypography.h2.fontWeight, FontWeight.w600);

      expect(AppRadii.container, 12.0);
      expect(AppRadii.button, 8.0);
      expect(AppRadii.navBarItem, 12.0);
      expect(AppRadii.badge, 16.0);
    });
  });

  group('MDS Atomic Components', () {
    testWidgets('StatusBadge maps semantic colors correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                StatusBadge(label: 'Healthy', statusType: StatusType.healthy),
                StatusBadge(label: 'At risk', statusType: StatusType.atRisk),
                StatusBadge(label: 'Pending', statusType: StatusType.pending),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Healthy'), findsOneWidget);
      expect(find.text('At risk'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);

      final healthyContainer = tester.widget<Container>(
        find.ancestor(
          of: find.text('Healthy'),
          matching: find.byType(Container),
        ).first,
      );
      final healthyDecoration = healthyContainer.decoration as BoxDecoration;
      expect(healthyDecoration.color, AppColors.badgeHealthyBg);
      expect(healthyDecoration.borderRadius, AppRadii.badgeBorderRadius);

      final atRiskContainer = tester.widget<Container>(
        find.ancestor(
          of: find.text('At risk'),
          matching: find.byType(Container),
        ).first,
      );
      final atRiskDecoration = atRiskContainer.decoration as BoxDecoration;
      expect(atRiskDecoration.color, AppColors.badgeAtRiskBg);

      final pendingContainer = tester.widget<Container>(
        find.ancestor(
          of: find.text('Pending'),
          matching: find.byType(Container),
        ).first,
      );
      final pendingDecoration = pendingContainer.decoration as BoxDecoration;
      expect(pendingDecoration.color, AppColors.badgePendingBg);
    });

    testWidgets('CustomPrimaryButton responds to tap and displays label',
        (tester) async {
      bool pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPrimaryButton(
              label: 'Test Button',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Test Button'), findsOneWidget);
      await tester.tap(find.text('Test Button'));
      await tester.pump();
      expect(pressed, isTrue);
    });

    testWidgets('DataRowItem renders leading text, badge, and trailing text',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DataRowItem(
              leadingText: 'Tag 101',
              badgeState: StatusType.healthy,
              trailingText: '09/01',
            ),
          ),
        ),
      );

      expect(find.text('Tag 101'), findsOneWidget);
      expect(find.text('Healthy'), findsOneWidget);
      expect(find.text('09/01'), findsOneWidget);
    });

    testWidgets('BottomNavBar highlights active tab with #215433 background',
        (tester) async {
      int selectedTab = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: BottomNavBar(
              activeIndex: 0,
              onTabSelected: (index) => selectedTab = index,
            ),
          ),
        ),
      );

      expect(find.text('Dash'), findsOneWidget);
      expect(find.text('Alerts'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      await tester.tap(find.text('Alerts'));
      await tester.pump();
      expect(selectedTab, 1);
    });
  });

  group('Full Application End-to-End Workflow & Navigation', () {
    testWidgets('Screen 1 LoginScreen loads and navigates to Dashboard',
        (tester) async {
      await tester.pumpWidget(const MastitisDetectionApp());
      await tester.pumpAndSettle();

      // Screen 1: Auth/Login UI verification
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Sign in to your MDS account'), findsOneWidget);
      expect(find.text('Phone / Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Log in'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text('Register'), findsOneWidget);

      // Tap Log in
      await tester.tap(find.text('Log in'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Screen 2: Dashboard UI verification
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('My cows'), findsOneWidget);
      expect(find.text('Tag 101'), findsOneWidget);
      expect(find.text('Tag 102'), findsOneWidget);
      expect(find.text('+ Add cow'), findsOneWidget);
      expect(find.text('Dash'), findsOneWidget);
    });

    testWidgets(
        'Screen 2 Dashboard -> Screen 3 Cow Profile -> Screen 4 Detection Result -> Return',
        (tester) async {
      await tester.pumpWidget(const MastitisDetectionApp());
      await tester.pumpAndSettle();

      // Log in to dashboard
      await tester.tap(find.text('Log in'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Tap on Tag 102 to open Cow Profile
      await tester.tap(find.text('Tag 102'));
      await tester.pumpAndSettle();

      // Screen 3: Cow Profile UI verification
      expect(find.text('Cow profile'), findsOneWidget);
      expect(find.textContaining('Tag number:'), findsOneWidget);
      expect(find.textContaining('102'), findsOneWidget);
      expect(find.text('Jersey'), findsOneWidget);
      expect(find.text('3 years'), findsOneWidget);
      expect(find.text('Select cow to test'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Mastitis present'), findsWidgets);

      // Tap "Select cow to test"
      await tester.tap(find.text('Select cow to test'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Screen 4: Detection Result UI verification
      expect(find.text('Detection result'), findsOneWidget);
      expect(find.text('Sensor readings'), findsOneWidget);
      expect(find.textContaining('Temp:'), findsOneWidget);
      expect(find.textContaining('pH:'), findsOneWidget);
      expect(find.textContaining('Cond:'), findsOneWidget);
      expect(find.text('Diagnostic Status'), findsOneWidget);
      expect(find.text('Back to dashboard'), findsOneWidget);

      // Tap "Back to dashboard"
      await tester.tap(find.text('Back to dashboard'));
      await tester.pumpAndSettle();

      // Back on Screen 2 Dashboard
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('My cows'), findsOneWidget);
    });

    testWidgets('Bottom Navigation Tabs switch between Dash and Alerts',
        (tester) async {
      await tester.pumpWidget(const MastitisDetectionApp());
      await tester.pumpAndSettle();

      // Log in
      await tester.tap(find.text('Log in'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // On Dashboard
      expect(find.text('My cows'), findsOneWidget);

      // Tap Alerts tab
      await tester.tap(find.text('Alerts'));
      await tester.pumpAndSettle();

      // On Screen 5: Alerts
      expect(find.widgetWithText(AppHeader, 'Alerts'), findsOneWidget);
      expect(find.widgetWithText(BottomNavBar, 'Alerts'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Unread'), findsWidgets);

      // Tap Dash tab to switch back
      await tester.tap(find.text('Dash'));
      await tester.pumpAndSettle();

      expect(find.text('My cows'), findsOneWidget);
    });
  });
}
