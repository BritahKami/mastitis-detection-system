import 'package:flutter/material.dart';
import 'constants/theme_constants.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell_screen.dart';
import 'screens/register_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MastitisDetectionApp());
}

/// Root Application Widget for Mastitis Detection System (MDS)
class MastitisDetectionApp extends StatelessWidget {
  const MastitisDetectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MDS - Mastitis Detection System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/dashboard': (context) => const MainShellScreen(initialIndex: 0),
        '/alerts': (context) => const MainShellScreen(initialIndex: 1),
        '/profile': (context) => const MainShellScreen(initialIndex: 2),
      },
    );
  }
}
