// // import 'package:hive_flutter/hive_flutter.dart';
// // import '../models/meal_model.dart';
// // import '../../../../core/services/hive_service.dart';

// // class DietService {
// //   final Box<MealModel> _mealBox = Hive.box<MealModel>(HiveService.mealBoxName);

// //   List<MealModel> getMeals() {
// //     return _mealBox.values.toList();
// //   }

// //   Future<void> addMeal(MealModel meal) async {
// //     await _mealBox.add(meal);
// //   }

// //   Future<void> deleteMeal(int index) async {
// //     await _mealBox.deleteAt(index);
// //   }

// //   int getTotalCalories() {
// //     return _mealBox.values.fold(0, (sum, item) => sum + item.calories);
// //   }

// //   double getTotalProtein() {
// //     return _mealBox.values.fold(0.0, (sum, item) => sum + item.proteinGrams);
// //   }

// //   double getTotalCarbs() {
// //     return _mealBox.values.fold(0.0, (sum, item) => sum + item.carbsGrams);
// //   }

// //   double getTotalFats() {
// //     return _mealBox.values.fold(0.0, (sum, item) => sum + item.fatGrams);
// //   }
// // }

// /*

// Step 1: Update lib/features/diet/data/services/diet_service.dart
// Ensure your DietService saves the meal properly into Hive without throwing errors in helper methods like getTotalCalories():

// */

// import 'package:hive_flutter/hive_flutter.dart';
// import '../models/meal_model.dart';
// import '../../../../core/services/hive_service.dart';

// class DietService {
//   Box<MealModel> get _mealBox => Hive.box<MealModel>(HiveService.mealBoxName);

//   Future<void> addMeal(MealModel meal) async {
//     // Adding with meal.id as the key ensures Hive updates correctly
//     await _mealBox.put(meal.id, meal);
//   }

//   Future<void> deleteMeal(dynamic key) async {
//     await _mealBox.delete(key);
//   }

//   int getTotalCalories({String? userId}) {
//     final now = DateTime.now();
//     final todayMeals = _mealBox.values.where((meal) {
//       final isSameUser = userId == null || meal.userId == userId;
//       final isToday = meal.date.year == now.year &&
//           meal.date.month == now.month &&
//           meal.date.day == now.day;
//       return isSameUser && isToday;
//     });

//     return todayMeals.fold(0, (sum, meal) => sum + meal.calories);
//   }
// }

// update
import 'package:hive_flutter/hive_flutter.dart';
import 'package:gym_tracker_app/features/diet/data/models/meal_model.dart';
import 'package:gym_tracker_app/core/services/hive_service.dart';

class DietService {
  Box<MealModel> get _mealBox => Hive.box<MealModel>(HiveService.mealBoxName);

  Future<void> addMeal(MealModel meal) async {
    await _mealBox.put(meal.id, meal);
  }

  Future<void> deleteMeal(dynamic key) async {
    await _mealBox.delete(key);
  }

  int getTotalCalories({String? userId}) {
    final now = DateTime.now();
    return _mealBox.values.where((meal) {
      final isSameUser = userId == null || meal.userId == userId;
      final isToday = meal.date.year == now.year &&
          meal.date.month == now.month &&
          meal.date.day == now.day;
      return isSameUser && isToday;
    }).fold(0, (sum, meal) => sum + meal.calories);
  }

  double getTotalProtein({String? userId}) {
    final now = DateTime.now();
    return _mealBox.values.where((meal) {
      final isSameUser = userId == null || meal.userId == userId;
      final isToday = meal.date.year == now.year &&
          meal.date.month == now.month &&
          meal.date.day == now.day;
      return isSameUser && isToday;
    }).fold(0.0, (sum, meal) => sum + meal.proteinGrams);
  }

  double getTotalCarbs({String? userId}) {
    final now = DateTime.now();
    return _mealBox.values.where((meal) {
      final isSameUser = userId == null || meal.userId == userId;
      final isToday = meal.date.year == now.year &&
          meal.date.month == now.month &&
          meal.date.day == now.day;
      return isSameUser && isToday;
    }).fold(0.0, (sum, meal) => sum + meal.carbsGrams);
  }

  double getTotalFats({String? userId}) {
    final now = DateTime.now();
    return _mealBox.values.where((meal) {
      final isSameUser = userId == null || meal.userId == userId;
      final isToday = meal.date.year == now.year &&
          meal.date.month == now.month &&
          meal.date.day == now.day;
      return isSameUser && isToday;
    }).fold(0.0, (sum, meal) => sum + meal.fatGrams);
  }
}
