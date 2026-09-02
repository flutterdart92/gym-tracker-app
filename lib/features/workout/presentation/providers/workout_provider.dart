import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../../../core/services/hive_service.dart';
import '../../data/models/exercise_model.dart';

class WorkoutProvider extends ChangeNotifier {
  final Box<ExerciseModel> _exerciseBox =
      Hive.box<ExerciseModel>(HiveService.exerciseBoxName);

  List<ExerciseModel> get exercises => _exerciseBox.values.toList();

  Future<void> addExercise(ExerciseModel exercise) async {
    await _exerciseBox.put(exercise.id, exercise);
    notifyListeners();
  }

  Future<void> deleteExercise(String id) async {
    await _exerciseBox.delete(id);
    notifyListeners();
  }
}
