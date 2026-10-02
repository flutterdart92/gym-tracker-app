import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ProfileProvider with ChangeNotifier {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  String? _currentUserId;

  // Theme Management
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  // Daily Nutrition Goals
  int _targetCalories = 2000;
  double _targetProtein = 150.0;
  double _targetCarbs = 200.0;
  double _targetFats = 65.0;

  int get targetCalories => _targetCalories;
  double get targetProtein => _targetProtein;
  double get targetCarbs => _targetCarbs;
  double get targetFats => _targetFats;

  /// Toggle light / dark theme mode
  void toggleTheme([bool? isDark]) {
    if (isDark != null) {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    } else {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    }
    notifyListeners();
  }

  /// Load nutrition targets specifically for the active user ID
  Future<void> loadUserProfile(String userId) async {
    _currentUserId = userId;

    final calStr = await _secureStorage.read(key: '${userId}_target_calories');
    final proStr = await _secureStorage.read(key: '${userId}_target_protein');
    final carbStr = await _secureStorage.read(key: '${userId}_target_carbs');
    final fatStr = await _secureStorage.read(key: '${userId}_target_fats');

    _targetCalories = int.tryParse(calStr ?? '') ?? 2000;
    _targetProtein = double.tryParse(proStr ?? '') ?? 150.0;
    _targetCarbs = double.tryParse(carbStr ?? '') ?? 200.0;
    _targetFats = double.tryParse(fatStr ?? '') ?? 65.0;

    notifyListeners();
  }

  /// Alias method matching profile_screen.dart call
  Future<void> updateGoals({
    required int calories,
    required double protein,
    required double carbs,
    required double fats,
  }) async {
    await updateNutritionTargets(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fats: fats,
    );
  }

  /// Save daily targets bound to active userId
  Future<void> updateNutritionTargets({
    required int calories,
    required double protein,
    required double carbs,
    required double fats,
  }) async {
    _targetCalories = calories;
    _targetProtein = protein;
    _targetCarbs = carbs;
    _targetFats = fats;

    if (_currentUserId != null) {
      await _secureStorage.write(
        key: '${_currentUserId}_target_calories',
        value: calories.toString(),
      );
      await _secureStorage.write(
        key: '${_currentUserId}_target_protein',
        value: protein.toString(),
      );
      await _secureStorage.write(
        key: '${_currentUserId}_target_carbs',
        value: carbs.toString(),
      );
      await _secureStorage.write(
        key: '${_currentUserId}_target_fats',
        value: fats.toString(),
      );
    }

    notifyListeners();
  }

  /// Clear in-memory state on logout
  void resetState() {
    _currentUserId = null;
    _targetCalories = 2000;
    _targetProtein = 150.0;
    _targetCarbs = 200.0;
    _targetFats = 65.0;
    notifyListeners();
  }
}
