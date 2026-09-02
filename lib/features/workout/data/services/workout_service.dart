import 'package:hive_flutter/hive_flutter.dart';
import '../models/exercise_model.dart';
import '../../../../core/services/hive_service.dart';

class WorkoutService {
  final Box<ExerciseModel> _workoutBox =
      Hive.box<ExerciseModel>(HiveService.exerciseBoxName);

  List<ExerciseModel> getWorkouts() {
    return _workoutBox.values.toList();
  }

  Future<void> addWorkout(ExerciseModel exercise) async {
    await _workoutBox.add(exercise);
  }

  Future<void> deleteWorkout(int index) async {
    await _workoutBox.deleteAt(index);
  }
}
