import 'package:flutter/material.dart';
import '../../data/repositories/profile_repository.dart';

class ThemeProvider extends ChangeNotifier {
  final ProfileRepository? _profileRepository;
  ThemeMode _themeMode = ThemeMode.light;

  ThemeProvider({ProfileRepository? repository}) : _profileRepository = repository;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> toggleTheme() async {
    final newMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setTheme(newMode, save: true);
  }

  Future<void> setTheme(ThemeMode mode, {bool save = false}) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    notifyListeners();

    if (save && _profileRepository != null) {
      try {
        await _profileRepository!.updateProfile({
          'personal_details': {
            'theme_preference': mode == ThemeMode.dark ? 'dark' : 'light'
          }
        });
      } catch (e) {
        // Silently fail or log error
        debugPrint('Failed to save theme preference: $e');
      }
    }
  }
}
