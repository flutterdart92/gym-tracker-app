import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:gym_tracker_app/core/services/hive_service.dart';
import 'package:gym_tracker_app/features/workout/data/models/exercise_model.dart';

class WorkoutProvider with ChangeNotifier {
  List<ExerciseModel> _exercises = [];
  String? _currentUserId;

  List<ExerciseModel> get exercises => _exercises;

  /// Load workouts belonging strictly to the active user ID
  Future<void> loadUserWorkouts(String userId) async {
    _currentUserId = userId;
    final box = await Hive.openBox<ExerciseModel>(
      HiveService.exerciseBoxName,
      encryptionCipher: HiveService.cipher,
    );

    _exercises =
        box.values.where((exercise) => exercise.userId == userId).toList();

    notifyListeners();
  }

  /// Get today's workouts for current user
  List<ExerciseModel> get todayWorkouts {
    final now = DateTime.now();
    return _exercises.where((e) {
      final date = e.createdAt ?? DateTime.now();
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).toList();
  }

  /// Add exercise entry bound to active userId
  Future<void> addExercise({
    required String name,
    required int sets,
    required int reps,
    required double weight,
  }) async {
    if (_currentUserId == null) return;

    final box = await Hive.openBox<ExerciseModel>(
      HiveService.exerciseBoxName,
      encryptionCipher: HiveService.cipher,
    );

    final newExercise = ExerciseModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: _currentUserId!,
      name: name,
      sets: sets,
      reps: reps,
      weight: weight,
      createdAt: DateTime.now(),
    );

    await box.put(newExercise.id, newExercise);
    _exercises.add(newExercise);
    notifyListeners();
  }

  /// Reset state on logout
  void resetState() {
    _exercises = [];
    _currentUserId = null;
    notifyListeners();
  }
}
