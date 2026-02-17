import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/verification_screen.dart';
import '../screens/analysis_screen.dart';
import '../screens/user_info_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String verify = '/verify';
  static const String analysis = '/analysis';
  static const String userInfo = '/user-info';

  static Map<String, WidgetBuilder> get routes => {
        login: (context) => const LoginScreen(),
        home: (context) => const HomeScreen(),
        verify: (context) {
          final email = ModalRoute.of(context)!.settings.arguments as String;
          return VerificationScreen(email: email);
        },
        analysis: (context) => const AnalysisScreen(),
        userInfo: (context) => const UserInfoScreen(),
      };
}
