import 'package:hive/hive.dart';
import '../../../../core/services/hive_service.dart';
import '../models/exercise_model.dart';

class WorkoutService {
  Box<ExerciseModel> get _exerciseBox =>
      Hive.box<ExerciseModel>(HiveService.exerciseBoxName);

  Future<void> addWorkout(ExerciseModel exercise) async {
    await _exerciseBox.put(exercise.id, exercise);
  }

  Future<void> deleteWorkout(int index) async {
    await _exerciseBox.deleteAt(index);
  }

  Future<void> deleteWorkoutById(String id) async {
    await _exerciseBox.delete(id);
  }

  List<ExerciseModel> getAllWorkouts() {
    return _exerciseBox.values.toList();
  }

  List<ExerciseModel> getWorkouts() {
    return getAllWorkouts();
  }
}
