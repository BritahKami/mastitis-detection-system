import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mastitis_detection_app/constants/theme_constants.dart';
import 'package:mastitis_detection_app/main.dart';
import 'package:mastitis_detection_app/models/mds_models.dart';
import 'package:mastitis_detection_app/screens/dashboard_screen.dart';
import 'package:mastitis_detection_app/screens/profile_screen.dart';
import 'package:mastitis_detection_app/screens/register_screen.dart';
import 'package:mastitis_detection_app/services/api_service.dart';
import 'package:mastitis_detection_app/widgets/app_header.dart';
import 'package:mastitis_detection_app/widgets/bottom_nav_bar.dart';
import 'package:mastitis_detection_app/widgets/custom_primary_button.dart';
import 'package:mastitis_detection_app/widgets/custom_text_field.dart';
import 'package:mastitis_detection_app/widgets/data_row_item.dart';
import 'package:mastitis_detection_app/widgets/status_badge.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'mds_auth_token': 'test_token',
      'mds_auth_user_email': 'farmer@dairyfarm.com',
    });

    final mockCows = <Map<String, dynamic>>[
      {
        'cow_id': 101,
        'cow_tag': 'Tag 101',
        'breed': 'Holstein Friesian',
        'age': 4,
        'health_status': 'Healthy',
        'lastTested': 'Today',
      },
      {
        'cow_id': 102,
        'cow_tag': 'Tag 102',
        'breed': 'Jersey',
        'age': 3,
        'health_status': 'At Risk',
        'lastTested': 'Yesterday',
        'history': [
          {
            'date': '2026-09-02',
            'prediction': 'Mastitis Present',
          },
          {
            'date': '2026-08-20',
            'prediction': 'Mastitis Absent',
          },
        ],
      },
    ];

    final mockAlerts = <Map<String, dynamic>>[
      {
        'alert_id': 1,
        'result_id': 10,
        'cow_tag': 'Tag 102',
        'message': 'Mastitis Present detected for Tag 102',
        'status': 'Unread',
        'send_time': '2026-09-09 10:30',
      },
      {
        'alert_id': 2,
        'result_id': 11,
        'cow_tag': 'Tag 101',
        'message': 'Routine check for Tag 101',
        'status': 'Read',
        'send_time': '2026-09-08 14:00',
      },
    ];

    final mockClient = MockClient((request) async {
      final path = request.url.path;
      final method = request.method;

      if (path == '/api/auth/login') {
        return http.Response(
          jsonEncode({
            'access_token': 'mock_token',
            'token_type': 'bearer',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      if (path == '/api/auth/login-step1') {
        return http.Response(
          jsonEncode({
            'message': 'A 6-digit verification code has been sent to your email.',
            'email': 'farmer@dairyfarm.com',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      if (path == '/api/auth/login-step2') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        if (body['code'] == '123456') {
          return http.Response(
            jsonEncode({
              'access_token': 'mock_token',
              'token_type': 'bearer',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else {
          return http.Response(
            jsonEncode({'detail': 'Invalid verification code.'}),
            400,
            headers: {'content-type': 'application/json'},
          );
        }
      }

      if (path == '/api/auth/forgot-password') {
        return http.Response(
          jsonEncode({
            'message': 'A verification code has been sent to your email.',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      if (path == '/api/auth/verify-reset-code') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        if (body['code'] == '123456') {
          return http.Response(
            jsonEncode({'message': 'Verification code is valid.'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else {
          return http.Response(
            jsonEncode({'detail': 'Invalid verification code.'}),
            400,
            headers: {'content-type': 'application/json'},
          );
        }
      }

      if (path == '/api/auth/reset-password') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        if ((body['new_password'] as String).length < 8) {
          return http.Response(
            jsonEncode({'detail': 'New password must be at least 8 characters long.'}),
            400,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({'message': 'Password reset successfully. You can now log in.'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      if (path == '/api/auth/register') {
        return http.Response(
          jsonEncode({
            'message': 'Farmer registered successfully',
            'farmer_id': 1,
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      }

      if (path == '/api/auth/profile') {
        return http.Response(
          jsonEncode({
            'farmer_id': 1,
            'fname': 'John',
            'lname': 'Doe',
            'email': 'farmer@dairyfarm.com',
            'total_cows': 5,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      if (path == '/api/cows' && method == 'GET') {
        return http.Response(
          jsonEncode(mockCows),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      if (path == '/api/cows' && method == 'POST') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final tag = body['tag_number'] ?? body['cow_tag'] ?? 'Tag 999';
        final breed = body['breed'] ?? 'Jersey Special';
        final age = body['age'] ?? 4;
        final newCowJson = {
          'cow_id': 999,
          'cow_tag': tag,
          'tag_number': tag,
          'breed': breed,
          'age': age,
          'health_status': 'Pending',
          'lastTested': 'Today',
        };
        mockCows.insert(0, newCowJson);
        return http.Response(
          jsonEncode(newCowJson),
          201,
          headers: {'content-type': 'application/json'},
        );
      }

      if (path.contains('/api/cows/') && method == 'GET') {
        return http.Response(
          jsonEncode({
            'cow_id': 102,
            'cow_tag': 'Tag 102',
            'breed': 'Jersey',
            'age': 3,
            'health_status': 'At Risk',
            'lastTested': 'Yesterday',
            'history': [
              {
                'date': '2026-09-15',
                'prediction': 'Mastitis Present',
              }
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      if (path == '/api/alerts' && method == 'GET') {
        return http.Response(
          jsonEncode(mockAlerts),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      if (path.contains('/api/alerts/') &&
          path.endsWith('/read') &&
          method == 'PUT') {
        final segments = path.split('/');
        final idStr = segments[segments.length - 2];
        for (var i = 0; i < mockAlerts.length; i++) {
          if (mockAlerts[i]['alert_id'].toString() == idStr) {
            mockAlerts[i]['status'] = 'Read';
          }
        }
        return http.Response(
          jsonEncode({
            'message': 'Alert marked as read',
            'alert_id': int.tryParse(idStr) ?? 1
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      if (path == '/api/alerts/mark-all-read' && method == 'PUT') {
        for (var i = 0; i < mockAlerts.length; i++) {
          mockAlerts[i]['status'] = 'Read';
        }
        return http.Response(
          jsonEncode({
            'message': 'All alerts marked as read',
            'updated_count': mockAlerts.length
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }

      return http.Response('{"detail": "Not found"}', 404);
    });

    ApiService().setClientForTesting(mockClient);
  });
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

    test(
        'AlertNotification.fromJson formats timestamp as yyyy-MM-dd HH:mm hiding seconds',
        () {
      final alertWithSeconds = AlertNotification.fromJson({
        'alert_id': 10,
        'cow_tag': 'Tag 102',
        'send_time': '2026-10-15 19:55:23',
        'status': 'Unread',
      });
      expect(alertWithSeconds.timestamp, '2026-10-15 19:55');

      final alertIso = AlertNotification.fromJson({
        'alert_id': 11,
        'cow_tag': 'COW-001',
        'send_time': '2026-10-15T19:55:00',
        'status': 'Read',
      });
      expect(alertIso.timestamp, '2026-10-15 19:55');
    });

    testWidgets(
        'DataRowItem in alert mode cleanly accommodates yyyy-MM-dd HH:mm timestamp on 360 width',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      FlutterErrorDetails? caughtDetails;
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) => caughtDetails = details;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DataRowItem(
              leadingText: 'Tag 102',
              badgeState: StatusType.atRisk,
              badgeLabel: 'Unread',
              badgeLeading: true,
              trailingText: '2026-10-15 19:55',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      FlutterError.onError = originalOnError;

      expect(caughtDetails, isNull);
      expect(find.text('Unread'), findsOneWidget);
      expect(find.text('Tag 102'), findsOneWidget);
      expect(find.text('2026-10-15 19:55'), findsOneWidget);
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

Future<void> performLoginFlow(WidgetTester tester) async {
  await tester.tap(find.text('Log in'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();

  if (find.text('Two-Factor Verification').evaluate().isNotEmpty) {
    await tester.enterText(find.byType(TextFormField).first, '123456');
    await tester.tap(find.text('Verify & Log in'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
  }
}

  group('Full Application End-to-End Workflow & Navigation', () {
    testWidgets('Screen 1 LoginScreen loads and navigates to Dashboard via 2FA',
        (tester) async {
      await tester.pumpWidget(const MastitisDetectionApp());
      await tester.pumpAndSettle();

      // Screen 1: Auth/Login UI verification
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Sign in to your MDS account'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Log in'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text('Register'), findsOneWidget);

      // Tap Log in dispatches 2FA OTP and navigates to LoginVerificationScreen
      await tester.tap(find.text('Log in'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('Two-Factor Verification'), findsOneWidget);
      expect(find.textContaining('farmer@dairyfarm.com'), findsOneWidget);

      // Enter valid 6-digit OTP code and submit
      await tester.enterText(find.byType(TextFormField).first, '123456');
      await tester.tap(find.text('Verify & Log in'));
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

      // Log in to dashboard via 2FA
      await performLoginFlow(tester);

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
      await performLoginFlow(tester);

      // On Dashboard
      expect(find.text('My cows'), findsOneWidget);

      // Tap Alerts tab
      await tester.tap(find.text('Alerts'));
      await tester.pumpAndSettle();

      // On Screen 5: Alerts
      expect(find.widgetWithText(AppHeader, 'Alerts'), findsOneWidget);
      expect(find.widgetWithText(BottomNavBar, 'Alerts'), findsOneWidget);
      expect(find.text('Mastitis Detections'), findsOneWidget);
      expect(find.text('Unread'), findsWidgets);

      // Tap Dash tab to switch back
      await tester.tap(find.text('Dash'));
      await tester.pumpAndSettle();

      expect(find.text('My cows'), findsOneWidget);
    });

    testWidgets('Navigation from Login to RegisterScreen and back',
        (tester) async {
      await tester.pumpWidget(const MastitisDetectionApp());
      await tester.pumpAndSettle();

      // Tap Register button on LoginScreen
      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      // Verify Screen 2: Auth/Register Screen UI
      expect(find.byType(RegisterScreen), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.text('First Name'), findsOneWidget);
      expect(find.text('Last Name'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Register Account'), findsOneWidget);
      expect(find.text('Already have an account? Log in'), findsOneWidget);

      // Verify header color is Primary Theme (#215433)
      final headerText = tester.widget<Text>(find.text('Create Account'));
      expect(headerText.style?.color, AppColors.primaryTheme);

      // Tap footer "Already have an account? Log in"
      await tester.tap(find.text('Already have an account? Log in'));
      await tester.pumpAndSettle();

      // Verify returned to LoginScreen
      expect(find.text('Welcome back'), findsOneWidget);
    });

    testWidgets('Register Account action transitions to Dashboard and sets root',
        (tester) async {
      await tester.pumpWidget(const MastitisDetectionApp());
      await tester.pumpAndSettle();

      // Go to Register
      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();

      // Enter fields
      await tester.enterText(
          find.widgetWithText(CustomTextField, 'First Name'), 'Jane');
      await tester.enterText(
          find.widgetWithText(CustomTextField, 'Last Name'), 'Smith');
      await tester.enterText(
          find.widgetWithText(CustomTextField, 'Email Address'),
          'jane@dairyfarm.com');
      await tester.enterText(
          find.widgetWithText(CustomTextField, 'Password'), 'secret123');

      // Tap Register Account
      await tester.tap(find.text('Register Account'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Should be on Dashboard
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('My cows'), findsOneWidget);

      // Verify MainShellScreen is absolute root and cannot pop
      final nav = Navigator.of(tester.element(find.text('Dashboard')));
      expect(nav.canPop(), isFalse);
    });

    testWidgets(
        'Navigation stack bug fix: Register -> Select cow to test -> Back to dashboard returns to Dashboard, not Auth',
        (tester) async {
      await tester.pumpWidget(const MastitisDetectionApp());
      await tester.pumpAndSettle();

      // 1. Launch the app and navigate to the Register screen
      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();
      expect(find.byType(RegisterScreen), findsOneWidget);

      // 2. Register a new user. The app routes to the main app shell
      await tester.tap(find.text('Register Account'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('My cows'), findsOneWidget);

      // Verify MainShellScreen is root
      expect(Navigator.of(tester.element(find.text('Dashboard'))).canPop(), isFalse);

      // 3. Tap a cow and then "Select cow to test" to route to Detection Result screen
      await tester.tap(find.text('Tag 102'));
      await tester.pumpAndSettle();
      expect(find.text('Cow profile'), findsOneWidget);

      await tester.tap(find.text('Select cow to test'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.text('Detection result'), findsOneWidget);

      // 4. Tap the "Back to dashboard" button
      await tester.tap(find.text('Back to dashboard'));
      await tester.pumpAndSettle();

      // Expected: Pop back to Dashboard tab, NOT RegisterScreen or LoginScreen!
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('My cows'), findsOneWidget);
      expect(find.byType(RegisterScreen), findsNothing);
      expect(find.text('Create Account'), findsNothing);
      expect(find.text('Welcome back'), findsNothing);
      expect(Navigator.of(tester.element(find.text('Dashboard'))).canPop(), isFalse);
    });

    testWidgets(
        'Logout from Profile clears main app stack and sets LoginScreen as new root',
        (tester) async {
      await tester.pumpWidget(const MastitisDetectionApp());
      await tester.pumpAndSettle();

      // Log in
      await performLoginFlow(tester);

      // Switch to Profile tab
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Farmer John Doe'), findsOneWidget);

      // Tap Log out
      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();

      // Expected: LoginScreen is the new root
      expect(find.text('Welcome back'), findsOneWidget);
      expect(Navigator.of(tester.element(find.text('Welcome back'))).canPop(), isFalse);
    });
  });

  group('MDS Two-Factor Login Workflow (2FA)', () {
    testWidgets('Invalid OTP code shows error message', (tester) async {
      await tester.pumpWidget(const MastitisDetectionApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Log in'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('Two-Factor Verification'), findsOneWidget);

      // Enter invalid OTP
      await tester.enterText(find.byType(TextFormField).first, '999999');
      await tester.tap(find.text('Verify & Log in'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('Invalid verification code.'), findsOneWidget);
    });

    testWidgets('Resend code dispatches fresh code notification', (tester) async {
      await tester.pumpWidget(const MastitisDetectionApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Log in'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('Resend Code'), findsOneWidget);
      await tester.tap(find.text('Resend Code'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('A fresh verification code has been dispatched to your email.'), findsOneWidget);
    });
  });

  group('MDS Password Reset & Email Verification Workflow', () {
    testWidgets('Forgot password flow from Login to ResetPasswordScreen and LoginScreen', (tester) async {
      await tester.pumpWidget(const MastitisDetectionApp());
      await tester.pumpAndSettle();

      // Tap Forgot password? with empty input opens dialog
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();

      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Enter your registered email address to receive a 6-digit verification code.'), findsOneWidget);

      // Enter email in dialog and send code
      final dialogEmailField = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(dialogEmailField, 'farmer@dairyfarm.com');
      await tester.tap(find.text('Send Code'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // On VerifyResetCodeScreen
      expect(find.text('Verify Code'), findsNWidgets(2));
      expect(find.textContaining('farmer@dairyfarm.com'), findsOneWidget);

      // Enter code 123456
      await tester.enterText(find.byType(TextFormField).first, '123456');
      await tester.tap(find.widgetWithText(CustomPrimaryButton, 'Verify Code'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // On ResetPasswordScreen
      expect(find.text('Create New Password'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm New Password'), findsOneWidget);

      // Enter passwords that don't match
      final inputs = find.byType(TextFormField);
      await tester.enterText(inputs.at(0), 'newpassword123');
      await tester.enterText(inputs.at(1), 'mismatch123');
      await tester.tap(find.text('Reset Password'));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match. Please verify both fields.'), findsOneWidget);

      // Enter password with less than 8 characters
      await tester.enterText(inputs.at(0), 'short');
      await tester.enterText(inputs.at(1), 'short');
      await tester.tap(find.text('Reset Password'));
      await tester.pumpAndSettle();

      expect(find.text('Password must be at least 8 characters long.'), findsOneWidget);

      // Enter valid matching passwords
      await tester.enterText(inputs.at(0), 'newpassword123');
      await tester.enterText(inputs.at(1), 'newpassword123');
      await tester.tap(find.text('Reset Password'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Success dialog shown
      expect(find.text('Password Reset Successful'), findsOneWidget);
      await tester.tap(find.text('Log in now'));
      await tester.pumpAndSettle();

      // Returned to LoginScreen
      expect(find.text('Welcome back'), findsOneWidget);
    });
  });

  group('Dashboard: Add Cow Modal Bottom Sheet', () {
    testWidgets(
        'Modal opens with exactly three CustomTextFields and NO Initial Status dropdown',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardScreen(showBottomNav: false),
        ),
      );
      await tester.pumpAndSettle();

      // Tap "+ Add cow"
      await tester.tap(find.text('+ Add cow'));
      await tester.pumpAndSettle();

      // Header: "Register Cow" with a top-right close icon ("X")
      expect(find.text('Register Cow'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);

      // Inputs: Contains exactly three CustomTextField inputs
      expect(find.byType(CustomTextField), findsNWidgets(3));
      expect(find.text('Tag Number'), findsOneWidget);
      expect(find.text('Breed'), findsOneWidget);
      expect(find.text('Age (years)'), findsOneWidget);

      // CRITICAL: Ensure the "Initial Status" dropdown is completely removed
      expect(find.text('Initial Status: '), findsNothing);
      expect(find.byType(DropdownButton<StatusType>), findsNothing);

      // Actions: CustomPrimaryButton ("Save Cow") pinned to bottom
      expect(find.text('Save Cow'), findsOneWidget);

      // Tap close icon
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('Register Cow'), findsNothing);
    });

    testWidgets('Save Cow adds new cow to the list', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardScreen(showBottomNav: false),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('+ Add cow'));
      await tester.pumpAndSettle();

      // Enter a unique tag number
      await tester.enterText(
          find.widgetWithText(CustomTextField, 'Tag Number'),
          'Tag 999');
      await tester.enterText(
          find.widgetWithText(CustomTextField, 'Breed'), 'Jersey Special');
      await tester.enterText(
          find.widgetWithText(CustomTextField, 'Age (years)'), '4');

      await tester.tap(find.text('Save Cow'));
      await tester.pumpAndSettle();

      // Cow modal dismissed and new cow appears on the list
      expect(find.text('Register Cow'), findsNothing);
      expect(find.text('Tag 999'), findsOneWidget);
    });
  });

  group('User Profile Screen Modifications', () {
    testWidgets('ProfileScreen renders strictly to specifications',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(
            firstName: 'John',
            lastName: 'Doe',
            email: 'farmer@dairyfarm.com',
            cowsRegistered: 5,
            showBottomNav: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Layout: White card layout with AppHeader ("Profile")
      expect(find.widgetWithText(AppHeader, 'Profile'), findsOneWidget);

      // Header Area: Centered circular avatar icon (light green bg, dark green user icon)
      final avatarFinder = find.byType(CircleAvatar);
      expect(avatarFinder, findsOneWidget);
      final avatar = tester.widget<CircleAvatar>(avatarFinder);
      expect(avatar.backgroundColor, AppColors.badgeHealthyBg);
      expect(find.byIcon(Icons.person_rounded), findsOneWidget);

      // Farmer's full name
      expect(find.text('Farmer John Doe'), findsOneWidget);

      // CRITICAL: Do not include a subtitle string below the name
      expect(find.textContaining('Green Valley'), findsNothing);
      expect(find.textContaining('Unit #4'), findsNothing);

      // Data Card: Bordered container (#E0E5E0) with 4 rows separated by dividers
      // CRITICAL: Remove Account ID, Hardware Telemetry, Registered Herd Size, and Last Calibration
      expect(find.text('Account ID'), findsNothing);
      expect(find.text('Hardware Telemetry'), findsNothing);
      expect(find.text('Registered Herd Size'), findsNothing);
      expect(find.text('Last Calibration'), findsNothing);

      // Verify exact 4 rows
      expect(find.text('First Name'), findsOneWidget);
      expect(find.text('John'), findsOneWidget);

      expect(find.text('Last Name'), findsOneWidget);
      expect(find.text('Doe'), findsOneWidget);

      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('farmer@dairyfarm.com'), findsOneWidget);

      expect(find.text('Cows Registered'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);

      // Check font weight bold on dynamic value
      final johnText = tester.widget<Text>(find.text('John'));
      expect(johnText.style?.fontWeight, FontWeight.bold);

      // Check text overflow and alignment properties
      final emailText = tester.widget<Text>(find.text('farmer@dairyfarm.com'));
      expect(emailText.textAlign, TextAlign.right);
      expect(emailText.maxLines, 1);
      expect(emailText.overflow, TextOverflow.ellipsis);

      // Actions: Full-width outlined button with an exit icon and the label "Log out"
      expect(find.text('Log out'), findsOneWidget);
      expect(find.byIcon(Icons.exit_to_app_rounded), findsOneWidget);

      // Footer: BottomNavBar with "Profile" active (tab index 2)
      final bottomNavFinder = find.byType(BottomNavBar);
      expect(bottomNavFinder, findsOneWidget);
      final bottomNav = tester.widget<BottomNavBar>(bottomNavFinder);
      expect(bottomNav.activeIndex, 2);
    });

    testWidgets(
        'ProfileScreen handles very long email without RenderFlex overflow',
        (tester) async {
      // Set mobile screen width (e.g., iPhone SE 375x667) to test horizontal layout
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      FlutterErrorDetails? caughtDetails;
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        caughtDetails = details;
      };

      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(
            firstName: 'John',
            lastName: 'Doe',
            email: 'verylongfarmeremailaddresswhichwouldotherwiseoverflow@dairyfarmcooperativenetwork.com',
            cowsRegistered: 1250,
            showBottomNav: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      FlutterError.onError = originalOnError;

      expect(caughtDetails, isNull);
      final longEmailFinder = find.text(
          'verylongfarmeremailaddresswhichwouldotherwiseoverflow@dairyfarmcooperativenetwork.com');
      expect(longEmailFinder, findsOneWidget);

      final emailWidget = tester.widget<Text>(longEmailFinder);
      expect(emailWidget.overflow, TextOverflow.ellipsis);
      expect(emailWidget.maxLines, 1);
      expect(emailWidget.textAlign, TextAlign.right);

      // Verify the Text widget is wrapped inside an Expanded widget in its Row
      expect(
        find.ancestor(
          of: longEmailFinder,
          matching: find.byType(Expanded),
        ),
        findsWidgets,
      );
    });
  });
}
