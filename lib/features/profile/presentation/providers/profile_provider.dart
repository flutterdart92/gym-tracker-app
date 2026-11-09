import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ProfileProvider with ChangeNotifier {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  String? _currentUserId;

  // Theme Management
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  // Daily Nutrition Goals
  int _targetCalories = 2200;
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

// for update the target calories
  // Future<void> updateTargetCalories(int newCalories) async {
  //   _targetCalories = newCalories;
  //   // If you are saving to Hive or SharedPreferences, add your save logic here:
  //   // final box = Hive.box(HiveService.profileBoxName);
  //   // box.put('target_calories', newCalories);
  //   notifyListeners();
  // }

// Future<void> _saveToHive() async {
//   try {
//     if (Hive.isBoxOpen(HiveService.profileBoxName)) {
//       final box = Hive.box(HiveService.profileBoxName);
//       box.put('target_calories', _targetCalories);
//       box.put('target_protein', _targetProtein);
//       box.put('target_carbs', _targetCarbs);
//       box.put('target_fats', _targetFats);
//     }
//   } catch (e) {
//     debugPrint('Error saving profile to Hive: $e');
//   }
// }

  // Future<void> updateTargetCalories(int newCalories) async {
  //   _targetCalories = newCalories;

  //   // Automatically adjust target macros based on new calorie target
  //   _targetProtein = ((newCalories * 0.30) / 4).round().toDouble();
  //   _targetCarbs = ((newCalories * 0.50) / 4).round().toDouble();
  //   _targetFats = ((newCalories * 0.20) / 9).round().toDouble();

  //   // Persist securely using FlutterSecureStorage bound to active userId
  //   if (_currentUserId != null) {
  //     await _secureStorage.write(
  //       key: '${_currentUserId}_target_calories',
  //       value: _targetCalories.toString(),
  //     );
  //     await _secureStorage.write(
  //       key: '${_currentUserId}_target_protein',
  //       value: _targetProtein.toString(),
  //     );
  //     await _secureStorage.write(
  //       key: '${_currentUserId}_target_carbs',
  //       value: _targetCarbs.toString(),
  //     );
  //     await _secureStorage.write(
  //       key: '${_currentUserId}_target_fats',
  //       value: _targetFats.toString(),
  //     );
  //   }

  //   notifyListeners();
  // }

  Future<void> updateTargetCalories(int newCalories) async {
    _targetCalories = newCalories;

    // Scale macros proportionally based on your 2200 kcal baseline
    // (150g Protein, 200g Carbs, 65g Fats at 2200 kcal)
    final double scale = newCalories / 2200.0;
    _targetProtein = (150.0 * scale).round().toDouble();
    _targetCarbs = (200.0 * scale).round().toDouble();
    _targetFats = (65.0 * scale).round().toDouble();

    // Persist securely using FlutterSecureStorage bound to active userId
    if (_currentUserId != null) {
      await _secureStorage.write(
        key: '${_currentUserId}_target_calories',
        value: _targetCalories.toString(),
      );
      await _secureStorage.write(
        key: '${_currentUserId}_target_protein',
        value: _targetProtein.toString(),
      );
      await _secureStorage.write(
        key: '${_currentUserId}_target_carbs',
        value: _targetCarbs.toString(),
      );
      await _secureStorage.write(
        key: '${_currentUserId}_target_fats',
        value: _targetFats.toString(),
      );
    }

    notifyListeners();
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
