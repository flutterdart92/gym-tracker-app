import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:gym_tracker_app/core/services/hive_service.dart';
import 'package:gym_tracker_app/features/workout/data/models/exercise_model.dart';

class WorkoutProvider extends ChangeNotifier {
  List<ExerciseModel> _workouts = [];
  bool _isLoading = false;
  String? _currentUserId; // Track active user ID

  List<ExerciseModel> get workouts => _workouts;
  List<ExerciseModel> get exercises => _workouts;
  bool get isLoading => _isLoading;

  WorkoutProvider() {
    _initHiveListener();
  }

  Future<void> _initHiveListener() async {
    try {
      final box = await _getWorkoutBox();
      _updateWorkoutsFromBox(box);
      box.listenable().addListener(() {
        _updateWorkoutsFromBox(box);
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error initializing workout box listener: $e');
    }
  }

  void _updateWorkoutsFromBox(Box<ExerciseModel> box) {
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      _workouts = [];
    } else {
      _workouts = box.values
          .where((e) => e.userId == _currentUserId || e.userId.isEmpty)
          .toList();
    }
  }

  /// Helper to get strictly user-filtered source list
  List<ExerciseModel> get _sourceList {
    if (_currentUserId == null) return [];
    if (Hive.isBoxOpen(HiveService.exerciseBoxName)) {
      return Hive.box<ExerciseModel>(HiveService.exerciseBoxName)
          .values
          .where((e) => e.userId == _currentUserId || e.userId.isEmpty)
          .toList();
    }
    return _workouts;
  }

  List<ExerciseModel> get todayWorkouts {
    final now = DateTime.now();
    return _sourceList.where((workout) {
      final date = workout.createdAt?.toLocal();
      if (date == null) return true;
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).toList();
  }

  // double get todayTotalVolume {
  //   double total = 0.0;
  //   for (var workout in todayWorkouts) {
  //     if (workout.setsList != null && workout.setsList!.isNotEmpty) {
  //       for (var setItem in workout.setsList!) {
  //         total += (setItem.weight * setItem.reps);
  //       }
  //     } else {
  //       total += (workout.weight * workout.reps * workout.sets);
  //     }
  //   }
  //   return total;
  // }

  // int get todayCaloriesBurned {
  //   if (todayWorkouts.isEmpty) return 0;
  //   final volumeBurn = (todayTotalVolume * 0.05).round();
  //   return volumeBurn > 0 ? volumeBurn : (todayWorkouts.length * 100);
  // }

  // String get nextWorkoutName {
  //   final sourceList = _sourceList;
  //   if (sourceList.isEmpty) return 'Leg Day';
  //   final hasLegs = sourceList.any((e) => e.name.toLowerCase().contains('leg'));
  //   if (hasLegs) return 'Leg Day';
  //   final hasPush = sourceList.any((e) =>
  //       e.name.toLowerCase().contains('chest') ||
  //       e.name.toLowerCase().contains('push') ||
  //       e.name.toLowerCase().contains('upper'));
  //   if (hasPush) return 'Push Day';
  //   return 'Leg Day';
  // }

  // int get nextWorkoutExerciseCount {
  //   final sourceList = _sourceList;
  //   final routine = nextWorkoutName.toLowerCase();
  //   List<ExerciseModel> matching = [];

  //   if (routine.contains('leg')) {
  //     matching = sourceList
  //         .where((e) => e.name.toLowerCase().contains('leg'))
  //         .toList();
  //   } else if (routine.contains('push') || routine.contains('chest')) {
  //     matching = sourceList
  //         .where((e) =>
  //             e.name.toLowerCase().contains('chest') ||
  //             e.name.toLowerCase().contains('push') ||
  //             e.name.toLowerCase().contains('upper'))
  //         .toList();
  //   } else if (routine.contains('pull') || routine.contains('back')) {
  //     matching = sourceList
  //         .where((e) =>
  //             e.name.toLowerCase().contains('pull') ||
  //             e.name.toLowerCase().contains('back') ||
  //             e.name.toLowerCase().contains('bicep'))
  //         .toList();
  //   }

  //   if (matching.isNotEmpty) {
  //     int totalSets = 0;
  //     for (var e in matching) {
  //       if (e.setsList != null && e.setsList!.isNotEmpty) {
  //         totalSets += e.setsList!.length;
  //       } else {
  //         totalSets += e.sets;
  //       }
  //     }
  //     return totalSets;
  //   }
  //   return sourceList.length;
  // }

// update
  double get todayTotalVolume {
    double total = 0.0;
    for (var workout in todayWorkouts) {
      if (workout.setsList != null && workout.setsList!.isNotEmpty) {
        for (var setItem in workout.setsList!) {
          if (setItem.isDone) {
            total += (setItem.weight * setItem.reps);
          }
        }
      }
    }
    return total;
  }

  int get todayCaloriesBurned {
    final vol = todayTotalVolume;
    if (vol <= 0) return 0;
    return (vol * 0.05).round();
  }

  String get nextWorkoutName {
    final sourceList = todayWorkouts;
    if (sourceList.isEmpty) return 'Workout Session';

    for (final exercise in sourceList) {
      final sets = exercise.setsList ?? [];
      final isAllDone = sets.isNotEmpty && sets.every((s) => s.isDone);
      if (!isAllDone) {
        return exercise.name;
      }
    }
    return sourceList.first.name;
  }

  int get nextWorkoutExerciseCount {
    final sourceList = todayWorkouts;
    if (sourceList.isEmpty) return 0;
    final activeName = nextWorkoutName;
    final matching = sourceList.where((e) => e.name == activeName).toList();
    if (matching.isNotEmpty && matching.first.setsList != null) {
      return matching.first.setsList!.length;
    }
    return sourceList.first.setsList?.length ?? sourceList.first.sets;
  }

  Set<int> get loggedDayIndices {
    final sourceList = _sourceList;
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

  int get weeklyWorkoutsDone {
    final sourceList = _sourceList;
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(monday.year, monday.month, monday.day);

    final count = sourceList.where((w) {
      if (w.createdAt == null) return true;
      final loc = w.createdAt!.toLocal();
      return loc.isAfter(startOfWeek.subtract(const Duration(seconds: 1)));
    }).length;

    return count;
  }

  int get weeklyWorkoutGoal => 4;

  int get currentStreak {
    final sourceList = _sourceList;
    final activeDates = <DateTime>{};

    for (var w in sourceList) {
      if (w.createdAt != null) {
        final loc = w.createdAt!.toLocal();
        activeDates.add(DateTime(loc.year, loc.month, loc.day));
      }
    }

    if (activeDates.isEmpty) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sortedDates = activeDates.toList()..sort((a, b) => b.compareTo(a));
    final yesterday = today.subtract(const Duration(days: 1));

    if (!sortedDates.contains(today) && !sortedDates.contains(yesterday)) {
      return 0;
    }

    int streak = 0;
    DateTime checkDate = sortedDates.contains(today) ? today : yesterday;

    while (sortedDates.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  int get bestStreak {
    final sourceList = _sourceList;
    final activeDates = <DateTime>{};

    for (var w in sourceList) {
      if (w.createdAt != null) {
        final loc = w.createdAt!.toLocal();
        activeDates.add(DateTime(loc.year, loc.month, loc.day));
      }
    }

    if (activeDates.isEmpty) return 0;

    final sortedDates = activeDates.toList()..sort((a, b) => a.compareTo(b));
    int maxStreak = 0;
    int currentRun = 0;
    DateTime? prevDate;

    for (var date in sortedDates) {
      if (prevDate == null) {
        currentRun = 1;
      } else {
        final diff = date.difference(prevDate).inDays;
        if (diff == 1) {
          currentRun++;
        } else if (diff > 1) {
          currentRun = 1;
        }
      }
      prevDate = date;
      if (currentRun > maxStreak) {
        maxStreak = currentRun;
      }
    }

    return maxStreak > currentStreak ? maxStreak : currentStreak;
  }

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
    _currentUserId = userId;
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

      // Safe stamp if userId is empty and current user is active
      if (exercise.userId.isEmpty && _currentUserId != null) {
        exercise.userId = _currentUserId!;
      }

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
      final keysToDelete = box.values
          .where((e) => e.userId == _currentUserId)
          .map((e) => e.key)
          .toList();
      await box.deleteAll(keysToDelete);
      _workouts.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing workout box: $e');
    }
  }

  void resetState() {
    _currentUserId = null;
    _workouts.clear();
    notifyListeners();
  }
}
