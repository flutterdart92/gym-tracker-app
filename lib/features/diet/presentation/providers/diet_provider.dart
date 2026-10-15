import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:gym_tracker_app/features/diet/data/models/meal_model.dart';
import 'package:gym_tracker_app/core/services/hive_service.dart';

class DietProvider extends ChangeNotifier {
  List<MealModel> _meals = [];
  bool _isLoading = false;
  int _waterGlasses = 6;

  List<MealModel> get meals => _meals;
  bool get isLoading => _isLoading;
  int get waterGlasses => _waterGlasses;

  DietProvider() {
    _initHiveListener();
  }

  /// Automatically sync with Hive box changes
  void _initHiveListener() {
    if (Hive.isBoxOpen(HiveService.mealBoxName)) {
      final box = Hive.box<MealModel>(HiveService.mealBoxName);
      _meals = box.values.toList();
      box.listenable().addListener(() {
        _meals = box.values.toList();
        notifyListeners();
      });
    }
  }

  void setWaterGlasses(int count) {
    _waterGlasses = count;
    notifyListeners();
  }

  /// Helper to check if a date matches today in local time
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    final localDate = date.toLocal();
    return localDate.year == now.year &&
        localDate.month == now.month &&
        localDate.day == now.day;
  }

  /// Get meals logged today (fallback directly to Hive if memory list is empty)
  List<MealModel> get todayMeals {
    List<MealModel> sourceList = _meals;
    if (sourceList.isEmpty && Hive.isBoxOpen(HiveService.mealBoxName)) {
      sourceList = Hive.box<MealModel>(HiveService.mealBoxName).values.toList();
    }
    return sourceList.where((meal) => _isToday(meal.date)).toList();
  }

  double get totalCalories =>
      _meals.fold(0.0, (sum, item) => sum + item.calories);

  double get totalProtein =>
      _meals.fold(0.0, (sum, item) => sum + item.proteinGrams);

  double get totalCarbs =>
      _meals.fold(0.0, (sum, item) => sum + item.carbsGrams);

  double get totalFats => _meals.fold(0.0, (sum, item) => sum + item.fatGrams);

  int get totalCaloriesToday {
    return todayMeals.fold(0, (sum, item) => sum + item.calories.round());
  }

  double get totalProteinToday {
    return todayMeals.fold(0.0, (sum, item) => sum + item.proteinGrams);
  }

  double get totalCarbsToday {
    return todayMeals.fold(0.0, (sum, item) => sum + item.carbsGrams);
  }

  double get totalFatsToday {
    return todayMeals.fold(0.0, (sum, item) => sum + item.fatGrams);
  }

  Future<Box<MealModel>> _getMealBox() async {
    if (Hive.isBoxOpen(HiveService.mealBoxName)) {
      return Hive.box<MealModel>(HiveService.mealBoxName);
    }
    return await Hive.openBox<MealModel>(
      HiveService.mealBoxName,
      encryptionCipher: HiveService.cipher,
    );
  }

  Future<void> loadUserMeals(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final box = await _getMealBox();
      _meals = box.values.where((meal) {
        return meal.userId == userId || meal.userId.isEmpty;
      }).toList();
    } catch (e) {
      debugPrint('Error loading meals from Hive: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addMeal(MealModel meal) async {
    try {
      final box = await _getMealBox();
      await box.add(meal);
      if (!_meals.contains(meal)) {
        _meals.add(meal);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding meal to Hive: $e');
    }
  }

  Future<void> deleteMeal(MealModel meal) async {
    try {
      final box = await _getMealBox();
      final keyToDelete = box.keys.firstWhere(
        (key) => box.get(key) == meal,
        orElse: () => null,
      );

      if (keyToDelete != null) {
        await box.delete(keyToDelete);
      } else {
        final keyByMatch = box.keys.firstWhere(
          (key) {
            final item = box.get(key);
            return item?.name == meal.name && item?.date == meal.date;
          },
          orElse: () => null,
        );
        if (keyByMatch != null) {
          await box.delete(keyByMatch);
        }
      }

      _meals.removeWhere((item) =>
          item == meal || (item.name == meal.name && item.date == meal.date));
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting meal from Hive: $e');
    }
  }

  Future<void> clearAllMeals() async {
    try {
      final box = await _getMealBox();
      await box.clear();
      _meals.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing meal box: $e');
    }
  }

  void resetState() {
    _meals.clear();
    notifyListeners();
  }
}
