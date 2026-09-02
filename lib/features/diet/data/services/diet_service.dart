import 'package:hive_flutter/hive_flutter.dart';
import '../models/meal_model.dart';
import '../../../../core/services/hive_service.dart';

class DietService {
  final Box<MealModel> _mealBox = Hive.box<MealModel>(HiveService.mealBoxName);

  List<MealModel> getMeals() {
    return _mealBox.values.toList();
  }

  Future<void> addMeal(MealModel meal) async {
    await _mealBox.add(meal);
  }

  Future<void> deleteMeal(int index) async {
    await _mealBox.deleteAt(index);
  }

  int getTotalCalories() {
    return _mealBox.values.fold(0, (sum, item) => sum + item.calories);
  }

  double getTotalProtein() {
    return _mealBox.values.fold(0.0, (sum, item) => sum + item.proteinGrams);
  }

  double getTotalCarbs() {
    return _mealBox.values.fold(0.0, (sum, item) => sum + item.carbsGrams);
  }

  double getTotalFats() {
    return _mealBox.values.fold(0.0, (sum, item) => sum + item.fatGrams);
  }
}
