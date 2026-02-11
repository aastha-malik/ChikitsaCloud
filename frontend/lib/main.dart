import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'data/api_client.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/reports_repository.dart';
import 'data/repositories/analysis_repository.dart';
import 'data/repositories/profile_repository.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/reports_provider.dart';
import 'presentation/providers/analysis_provider.dart';
import 'presentation/providers/profile_provider.dart';
import 'presentation/providers/family_provider.dart';
import 'presentation/providers/hospital_provider.dart';

void main() {
  final apiClient = ApiClient();
  final authRepository = AuthRepository(apiClient);
  final reportsRepository = ReportsRepository(apiClient);
  final analysisRepository = AnalysisRepository(apiClient);
  final profileRepository = ProfileRepository(apiClient);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authRepository)..checkAuthStatus()),
        ChangeNotifierProvider(create: (_) => ReportsProvider(reportsRepository)),
        ChangeNotifierProvider(create: (_) => AnalysisProvider(analysisRepository)),
        ChangeNotifierProvider(create: (_) => ProfileProvider(profileRepository)),
        ChangeNotifierProvider(create: (_) => FamilyProvider()),
        ChangeNotifierProvider(create: (_) => HospitalProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChikitsaCloud',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.login,
      routes: AppRoutes.routes,
    );
  }
}
