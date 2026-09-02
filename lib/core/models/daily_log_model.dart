import 'package:hive/hive.dart';
import '../../features/diet/data/models/meal_model.dart';
import '../../features/workout/data/models/exercise_model.dart';

part 'daily_log_model.g.dart';

@HiveType(typeId: 2)
class DailyLogModel extends HiveObject {
  @HiveField(0)
  final String date; // Format: YYYY-MM-DD

  @HiveField(1)
  final List<MealModel> meals;

  @HiveField(2)
  final List<ExerciseModel> exercises;

  DailyLogModel({
    required this.date,
    required this.meals,
    required this.exercises,
  });
}
