import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'data/api_client.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/reports_repository.dart';
import 'data/repositories/analysis_repository.dart';
import 'presentation/providers/analysis_provider.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/reports_provider.dart';


void main() {
  final apiClient = ApiClient();
  final authRepository = AuthRepository(apiClient);
  final reportsRepository = ReportsRepository(apiClient);
  final analysisRepository = AnalysisRepository(apiClient);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authRepository)..checkAuthStatus()),
        ChangeNotifierProvider(create: (_) => ReportsProvider(reportsRepository)),
        ChangeNotifierProvider(create: (_) => AnalysisProvider(analysisRepository)),
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
