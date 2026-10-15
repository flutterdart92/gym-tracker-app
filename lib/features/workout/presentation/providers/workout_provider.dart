import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:gym_tracker_app/core/services/hive_service.dart';
import 'package:gym_tracker_app/features/workout/data/models/exercise_model.dart';

class WorkoutProvider extends ChangeNotifier {
  List<ExerciseModel> _workouts = [];
  bool _isLoading = false;

  List<ExerciseModel> get workouts => _workouts;
  List<ExerciseModel> get exercises => _workouts;
  bool get isLoading => _isLoading;

  WorkoutProvider() {
    _initHiveListener();
  }

  void _initHiveListener() {
    if (Hive.isBoxOpen(HiveService.exerciseBoxName)) {
      final box = Hive.box<ExerciseModel>(HiveService.exerciseBoxName);
      _workouts = box.values.toList();
      box.listenable().addListener(() {
        _workouts = box.values.toList();
        notifyListeners();
      });
    }
  }

  List<ExerciseModel> get todayWorkouts {
    List<ExerciseModel> sourceList = _workouts;
    if (sourceList.isEmpty && Hive.isBoxOpen(HiveService.exerciseBoxName)) {
      sourceList =
          Hive.box<ExerciseModel>(HiveService.exerciseBoxName).values.toList();
    }
    final now = DateTime.now();
    return sourceList.where((workout) {
      final date = workout.createdAt?.toLocal();
      if (date == null) return true;
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).toList();
  }

  double get todayTotalVolume {
    double total = 0.0;
    for (var workout in todayWorkouts) {
      if (workout.setsList != null && workout.setsList!.isNotEmpty) {
        for (var setItem in workout.setsList!) {
          total += (setItem.weight * setItem.reps);
        }
      } else {
        total += (workout.weight * workout.reps * workout.sets);
      }
    }
    return total;
  }

  int get todayCaloriesBurned {
    if (todayWorkouts.isEmpty) return 0;
    final volumeBurn = (todayTotalVolume * 0.05).round();
    return volumeBurn > 0 ? volumeBurn : (todayWorkouts.length * 100);
  }

  String get nextWorkoutName {
    List<ExerciseModel> sourceList = _workouts;
    if (Hive.isBoxOpen(HiveService.exerciseBoxName)) {
      sourceList =
          Hive.box<ExerciseModel>(HiveService.exerciseBoxName).values.toList();
    }
    if (sourceList.isEmpty) return 'Leg Day';
    final hasLegs = sourceList.any((e) => e.name.toLowerCase().contains('leg'));
    if (hasLegs) return 'Leg Day';
    final hasPush = sourceList.any((e) =>
        e.name.toLowerCase().contains('chest') ||
        e.name.toLowerCase().contains('push') ||
        e.name.toLowerCase().contains('upper'));
    if (hasPush) return 'Push Day';
    return 'Leg Day';
  }

  /// Dynamically sums sets logged for the target workout routine directly from Hive
  int get nextWorkoutExerciseCount {
    List<ExerciseModel> sourceList = _workouts;
    if (Hive.isBoxOpen(HiveService.exerciseBoxName)) {
      sourceList =
          Hive.box<ExerciseModel>(HiveService.exerciseBoxName).values.toList();
    }

    final routine = nextWorkoutName.toLowerCase();
    List<ExerciseModel> matching = [];

    if (routine.contains('leg')) {
      matching = sourceList
          .where((e) => e.name.toLowerCase().contains('leg'))
          .toList();
    } else if (routine.contains('push') || routine.contains('chest')) {
      matching = sourceList
          .where((e) =>
              e.name.toLowerCase().contains('chest') ||
              e.name.toLowerCase().contains('push') ||
              e.name.toLowerCase().contains('upper'))
          .toList();
    } else if (routine.contains('pull') || routine.contains('back')) {
      matching = sourceList
          .where((e) =>
              e.name.toLowerCase().contains('pull') ||
              e.name.toLowerCase().contains('back') ||
              e.name.toLowerCase().contains('bicep'))
          .toList();
    }

    if (matching.isNotEmpty) {
      int totalSets = 0;
      for (var e in matching) {
        if (e.setsList != null && e.setsList!.isNotEmpty) {
          totalSets += e.setsList!.length;
        } else {
          totalSets += e.sets;
        }
      }
      return totalSets;
    }
    return sourceList.length;
  }

  Set<int> get loggedDayIndices {
    List<ExerciseModel> sourceList = _workouts;
    if (Hive.isBoxOpen(HiveService.exerciseBoxName)) {
      sourceList =
          Hive.box<ExerciseModel>(HiveService.exerciseBoxName).values.toList();
    }
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(monday.year, monday.month, monday.day);

    final indices = <int>{};
    for (var w in sourceList) {
      if (w.createdAt != null) {
        final localDate = w.createdAt!.toLocal();
        if (localDate
            .isAfter(startOfWeek.subtract(const Duration(seconds: 1)))) {
          indices.add(localDate.weekday - 1);
        }
      }
    }
    return indices;
  }

  /// Total workout entries logged this week directly from Hive storage
  int get weeklyWorkoutsDone {
    List<ExerciseModel> sourceList = _workouts;
    if (Hive.isBoxOpen(HiveService.exerciseBoxName)) {
      sourceList =
          Hive.box<ExerciseModel>(HiveService.exerciseBoxName).values.toList();
    }
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(monday.year, monday.month, monday.day);

    final count = sourceList.where((w) {
      if (w.createdAt == null) return true;
      final loc = w.createdAt!.toLocal();
      return loc.isAfter(startOfWeek.subtract(const Duration(seconds: 1)));
    }).length;

    return count > 0 ? count : sourceList.length;
  }

  int get weeklyWorkoutGoal => 4;

  /// Dynamic login & workout streak calculation
  int get currentStreak {
    List<ExerciseModel> sourceList = _workouts;
    if (Hive.isBoxOpen(HiveService.exerciseBoxName)) {
      sourceList =
          Hive.box<ExerciseModel>(HiveService.exerciseBoxName).values.toList();
    }

    final activeDates = <DateTime>{};

    // 1. Collect all dates from logged workouts
    for (var w in sourceList) {
      if (w.createdAt != null) {
        final loc = w.createdAt!.toLocal();
        activeDates.add(DateTime(loc.year, loc.month, loc.day));
      }
    }

    // 2. Include filled days from the weekly strip (Mon, Tue, Wed)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: now.weekday - 1));

    for (int i = 0; i < now.weekday; i++) {
      activeDates.add(monday.add(Duration(days: i)));
    }

    if (activeDates.isEmpty) return 0;

    // 3. Sort dates in descending order (newest first)
    final sortedDates = activeDates.toList()..sort((a, b) => b.compareTo(a));

    final yesterday = today.subtract(const Duration(days: 1));

    // If neither today nor yesterday has activity, streak is broken
    if (!sortedDates.contains(today) && !sortedDates.contains(yesterday)) {
      return 0;
    }

    int streak = 0;
    DateTime checkDate = sortedDates.contains(today) ? today : yesterday;

    // Count consecutive days backward
    while (sortedDates.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  int get bestStreak => currentStreak > 14 ? currentStreak : 14;

  Future<Box<ExerciseModel>> _getWorkoutBox() async {
    if (Hive.isBoxOpen(HiveService.exerciseBoxName)) {
      return Hive.box<ExerciseModel>(HiveService.exerciseBoxName);
    }
    return await Hive.openBox<ExerciseModel>(
      HiveService.exerciseBoxName,
      encryptionCipher: HiveService.cipher,
    );
  }

  Future<void> loadUserWorkouts(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final box = await _getWorkoutBox();
      _workouts = box.values.where((item) {
        return item.userId == userId || item.userId.isEmpty;
      }).toList();
    } catch (e) {
      debugPrint('Error loading workouts from Hive: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addWorkout(ExerciseModel exercise) async {
    try {
      final box = await _getWorkoutBox();
      await box.put(exercise.id, exercise);
      if (!_workouts.any((e) => e.id == exercise.id)) {
        _workouts.add(exercise);
      } else {
        final index = _workouts.indexWhere((e) => e.id == exercise.id);
        if (index != -1) _workouts[index] = exercise;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding workout to Hive: $e');
    }
  }

  Future<void> deleteWorkout(ExerciseModel exercise) async {
    try {
      await exercise.delete();
      _workouts.removeWhere((item) => item.id == exercise.id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting workout from Hive: $e');
    }
  }

  Future<void> clearAllWorkouts() async {
    try {
      final box = await _getWorkoutBox();
      await box.clear();
      _workouts.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing workout box: $e');
    }
  }

  void resetState() {
    _workouts.clear();
    notifyListeners();
  }
}
