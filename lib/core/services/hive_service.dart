import 'package:hive_flutter/hive_flutter.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../features/workout/data/models/exercise_model.dart';
import '../../features/diet/data/models/meal_model.dart';

class HiveService {
  static const String exerciseBoxName = 'exercise_box';
  static const String mealBoxName = 'meal_box';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register Hive Adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ExerciseModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(MealModelAdapter());
    }

    // Open initial boxes
    await Hive.openBox<ExerciseModel>(exerciseBoxName);
    await Hive.openBox<MealModel>(mealBoxName);
  }
}
