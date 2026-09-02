import 'package:hive_flutter/hive_flutter.dart';
import '../../features/workout/data/models/exercise_model.dart';
import '../../features/diet/data/models/meal_model.dart';

class HiveService {
  static const String exerciseBoxName = 'exercise_box';
  static const String mealBoxName = 'meal_box';

  static Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(ExerciseModelAdapter());
    Hive.registerAdapter(MealModelAdapter());

    await Hive.openBox<ExerciseModel>(exerciseBoxName);
    await Hive.openBox<MealModel>(mealBoxName);
  }
}
