import 'package:flutter/material.dart';
import 'package:gym_tracker_app/core/services/hive_service.dart';
import 'package:gym_tracker_app/features/diet/data/models/meal_model.dart';
import 'package:hive/hive.dart';

class DietProvider extends ChangeNotifier {
  List<MealModel> _meals = [];
  String? _currentUserId;

  List<MealModel> get meals => _meals;

  /// Load meals belonging strictly to active userId
  Future<void> loadUserMeals(String userId) async {
    _currentUserId = userId;
    final box = await Hive.openBox<MealModel>(
      HiveService.mealBoxName,
      encryptionCipher: HiveService.cipher,
    );

    _meals = box.values.where((meal) => meal.userId == userId).toList();

    notifyListeners();
  }

  /// Get today's meals for current user
  List<MealModel> get todayMeals {
    final now = DateTime.now();
    return _meals.where((m) {
      return m.date.year == now.year &&
          m.date.month == now.month &&
          m.date.day == now.day;
    }).toList();
  }

  /// Add meal bound to active userId
  Future<void> addMeal({
    required String name,
    required int calories,
    required double protein,
    required double carbs,
    required double fats,
  }) async {
    if (_currentUserId == null) return;

    final box = await Hive.openBox<MealModel>(
      HiveService.mealBoxName,
      encryptionCipher: HiveService.cipher,
    );

    final newMeal = MealModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: _currentUserId!,
      name: name,
      calories: calories,
      proteinGrams: protein,
      carbsGrams: carbs,
      fatGrams: fats,
      date: DateTime.now(),
    );

    await box.put(newMeal.id, newMeal);
    _meals.add(newMeal);
    notifyListeners();
  }

  /// Reset state on logout
  void resetState() {
    _meals = [];
    _currentUserId = null;
    notifyListeners();
  }
}
