import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:animations/animations.dart';
import 'package:gym_tracker_app/core/services/streak_service.dart';
import 'package:gym_tracker_app/features/auth/data/models/set_model.dart';
import 'package:gym_tracker_app/features/workout/presentation/providers/workout_provider.dart';
import 'package:gym_tracker_app/features/workout/presentation/screens/workout_screen.dart%20Sub-Files/add_set_bottom_sheet.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/hive_service.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/exercise_model.dart';
import '../../data/services/workout_service.dart';

import 'workout_screen.dart Sub-Files/set_row_item.dart';
import 'workout_screen.dart Sub-Files/rest_timer_card.dart';
import 'workout_screen.dart Sub-Files/exercise_form_bottom_sheet.dart';
import 'workout_screen.dart Sub-Files/workout_actions.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final WorkoutService _workoutService = WorkoutService();
  late Stopwatch _workoutStopwatch;
  Timer? _stopwatchTimer;
  int _restSecondsRemaining = 0;
  Timer? _restTimer;
  String _activeRestInfo = '';

  String? _activeRestExerciseId;
  String? _expandedExerciseId;
  // newly added
  String? _newlyAddedSetKey;

  bool _showStreakBounce = false;
  // newly added
  // final bool _shouldAnimateSets = false;
  int _currentStreak = 5;

  // newly added :

  String get _currentUserId =>
      (Provider.of<AuthProvider>(context, listen: false).currentUser?.email ??
              '')
          .toLowerCase();

  @override
  void initState() {
    super.initState();
    _workoutStopwatch = Stopwatch();
    _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _workoutStopwatch.isRunning) setState(() {});
    });
    _loadInitialStreak();
  }

  Future<void> _loadInitialStreak() async {
    final streak = StreakService.getCurrentStreak();
    setState(() {
      _currentStreak = streak;
    });
  }

  @override
  void dispose() {
    _stopwatchTimer?.cancel();
    _restTimer?.cancel();
    _workoutStopwatch.stop();
    super.dispose();
  }

/*

Newly Added :

*/

  void _resetAndStartTimer() {
    _workoutStopwatch.stop();
    _workoutStopwatch.reset();
    _workoutStopwatch.start();
    setState(() {});
  }

  void _resetAndStopTimer() {
    _workoutStopwatch.stop();
    _workoutStopwatch.reset();
    setState(() {});
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  Future<void> _triggerStreakAnimation() async {
    final result = await StreakService.checkAndIncrementStreak();
    bool isNewDay = result['isNewDay'];
    int updatedStreak = result['streak'];

    if (!isNewDay && _showStreakBounce) return;

    setState(() {
      _currentStreak = updatedStreak;
      _showStreakBounce = true;
    });

    HapticFeedback.heavyImpact();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        Future.delayed(const Duration(milliseconds: 6200), () {
          if (ctx.mounted) Navigator.of(ctx, rootNavigator: true).pop();
        });
        return Center(
          child: SizedBox.expand(
            child: Material(
              color: Colors.white,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 4800),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipPath(
                      clipper: EggClipper(),
                      child: Container(
                        width: 170,
                        height: 185,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFFFFE26E),
                              Color.fromARGB(255, 255, 98, 0),
                              Color.fromARGB(255, 255, 0, 0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 30),
                          child: Text(
                            '$_currentStreak',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 50,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _triggerRestTimerForSet(ExerciseModel exercise, List<SetModel> sets,
      int i, int exerciseIndex, List<ExerciseModel> exercises) {
    String nextInfo;
    if (i < sets.length - 1) {
      final nextSet = sets[i + 1];
      nextInfo =
          'Next: Set ${i + 2} · ${nextSet.weight.toString().replaceAll(RegExp(r'\.0$'), '')}kg × ${nextSet.reps}';
    } else if (exerciseIndex < exercises.length - 1) {
      final nextExercise = exercises[exerciseIndex + 1];
      final nextExSets = nextExercise.setsList ?? [];
      if (nextExSets.isNotEmpty) {
        final lastSet = nextExSets.last;
        nextInfo =
            'Next: ${nextExercise.name} · ${nextExSets.length} sets · last ${lastSet.weight.toString().replaceAll(RegExp(r'\.0$'), '')}kg × ${lastSet.reps}';
      } else {
        nextInfo = 'Next: ${nextExercise.name}';
      }
    } else {
      nextInfo = 'Final Set completed!';
    }

    _startRestTimer(
      exercise.id,
      seconds: 90,
      info: nextInfo,
    );
  }

  void _startRestTimer(String exerciseId,
      {int seconds = 60, String info = ''}) {
    _restTimer?.cancel();
    setState(() {
      _activeRestExerciseId = exerciseId;
      _restSecondsRemaining = seconds;
      _activeRestInfo = info;
    });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restSecondsRemaining > 0) {
        setState(() {
          _restSecondsRemaining--;
        });
      }

      // else {
      //   timer.cancel();
      //   _activeRestExerciseId = null;
      // }
      // updated else :

      else {
        timer.cancel();
        final finishedId = _activeRestExerciseId;
        setState(() {
          _activeRestExerciseId = null;
        });

        // Handle Case 01 and Case 02 when rest timer reaches 0
        if (finishedId != null && mounted) {
          final box = Hive.box<ExerciseModel>(HiveService.exerciseBoxName);
          final exercises = box.values
              .where((e) =>
                  e.userId.toLowerCase() == _currentUserId || e.userId.isEmpty)
              .toList();
          final exIndex = exercises.indexWhere((e) => e.id == finishedId);
          if (exIndex != -1) {
            final exercise = exercises[exIndex];
            final sets = exercise.setsList ?? [];
            final allDone = sets.isNotEmpty && sets.every((s) => s.isDone);
            if (allDone) {
              if (exIndex < exercises.length - 1) {
                // Case 01: Automatically move to the next exercise below & start timer
                _resetAndStartTimer();
                // Case 01: Automatically move to the next exercise below
                setState(() {
                  _expandedExerciseId = exercises[exIndex + 1].id;
                });
              } else {
                // Case 02: No other workout below. Show "Completed" and keep closed state.
                setState(() {});
              }
            }
          }
        }
      }
    });
  }

// newly added to shows the meal logged success

  // void _showExerciseLoggedSuccess(BuildContext context) {
  // updated :
  void _showExerciseLoggedSuccess(BuildContext context,
      {bool isEditing = false}) {
    HapticFeedback.mediumImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: isDark
          ? Colors.black.withValues(alpha: 1.0)
          : Colors.white.withValues(alpha: 1.0),
      // transitionDuration: const Duration(milliseconds: 1000),
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (ctx, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  // width: 120,
                  // height: 120,
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // color: Color(0xFFA3E635),
                    color: isDark
                        ? const Color.fromARGB(255, 0, 137, 50)
                        : const Color.fromARGB(255, 181, 255, 187)
                            .withValues(alpha: 0.5),
                  ),
                  child: Center(
                    // child: Icon(
                    //   Icons.check_rounded,
                    //   color: Colors.black,
                    //   size: 56,
                    // ),
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color.fromARGB(255, 127, 255, 138)
                            : const Color.fromARGB(255, 0, 137, 50),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 52,
                      ),
                    ),
                  ),
                )
                    .animate()
                    .scale(
                      // duration: const Duration(milliseconds: 1600),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.elasticOut,
                    )
                    // .fadeIn(duration: const Duration(milliseconds: 1600)),
                    .fadeIn(duration: const Duration(milliseconds: 600)),
                const SizedBox(height: 16),
                Text(
                  // 'Exercise Logged!',
                  // updated
                  isEditing ? 'Exercise Updated!' : 'Exercise Logged!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    // color: isDark ? Colors.white : Colors.black87,
                    color: isDark
                        ? Colors.white.withValues(alpha: 1.0)
                        : Colors.black.withValues(alpha: 1.0),
                  ),
                  // ).animate().fadeIn(delay: const Duration(milliseconds: 300)),
                ).animate().fadeIn(delay: const Duration(milliseconds: 150)),
              ],
            ),
          ),
        );
      },
      // newly added
      transitionBuilder: (ctx, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: anim1,
            curve: Curves.elasticOut,
          ),
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
        );
      },
    );

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    });
  }

  // String _deriveDynamicWorkoutTitle(List<ExerciseModel> exercises) {
  //   if (exercises.isEmpty) return 'Workout Session';

  //   for (final exercise in exercises) {
  //     final sets = exercise.setsList ?? [];
  //     final isAllDone = sets.isNotEmpty && sets.every((s) => s.isDone);
  //     if (!isAllDone) {
  //       return exercise.name;
  //     }
  //   }
  //   return exercises.first.name;
  // }

  /*

 _deriveDynamicWorkoutTitle updated:

*/

// show succes on adding new set row
  void _showSetLoggedSuccess(BuildContext context) {
    HapticFeedback.mediumImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: isDark
          ? Colors.black.withValues(alpha: 1.0)
          : Colors.white.withValues(alpha: 1.0),
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (ctx, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? const Color.fromARGB(255, 0, 137, 50)
                        : const Color.fromARGB(255, 181, 255, 187)
                            .withValues(alpha: 0.5),
                  ),
                  child: Center(
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color.fromARGB(255, 127, 255, 138)
                            : const Color.fromARGB(255, 0, 137, 50),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 52,
                      ),
                    ),
                  ),
                )
                    .animate()
                    .scale(
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.elasticOut,
                    )
                    .fadeIn(duration: const Duration(milliseconds: 600)),
                const SizedBox(height: 16),
                Text(
                  'Set Logged!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? Colors.white.withValues(alpha: 1.0)
                        : Colors.black.withValues(alpha: 1.0),
                  ),
                ).animate().fadeIn(delay: const Duration(milliseconds: 150)),
              ],
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: anim1,
            curve: Curves.elasticOut,
          ),
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
        );
      },
    );

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    });
  }

  String _deriveDynamicWorkoutTitle(List<ExerciseModel> exercises) {
    if (exercises.isEmpty) return 'Workout Session';

    if (_expandedExerciseId != null) {
      final expandedEx = exercises.firstWhere(
        (e) => e.id == _expandedExerciseId,
        orElse: () => exercises.first,
      );
      return expandedEx.name;
    }

    for (final exercise in exercises) {
      final sets = exercise.setsList ?? [];
      final isAllDone = sets.isNotEmpty && sets.every((s) => s.isDone);
      if (!isAllDone) {
        return exercise.name;
      }
    }
    return exercises.first.name;
  }

  String _getPreviousSetString(
      Box<ExerciseModel> box, String exerciseName, int setIndex) {
    final previousLogs = box.values
        .where((e) =>
            e.name.trim().toLowerCase() == exerciseName.trim().toLowerCase() &&
            e.setsList != null &&
            e.setsList!.isNotEmpty)
        .toList();

    if (previousLogs.isEmpty) return '-';
    previousLogs.sort((a, b) =>
        (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));

    final lastLog = previousLogs.first;
    if (lastLog.setsList != null && lastLog.setsList!.length > setIndex) {
      final prevSet = lastLog.setsList![setIndex];
      return '${prevSet.weight.toString().replaceAll(RegExp(r'\.0$'), '')} × ${prevSet.reps}';
    }
    return '-';
  }

/*

Newly added _checkExerciseCompletionStatus :

*/

  void _checkExerciseCompletionStatus(ExerciseModel exercise) {
    final sets = exercise.setsList ?? [];
    if (sets.isNotEmpty && sets.every((s) => s.isDone)) {
      _workoutStopwatch.stop();
      setState(() {});
    }
  }

  Future<void> _showAddWorkoutModal(
    BuildContext outerContext, {
    ExerciseModel? existingExercise,
  }) async {
    final bool isEditing = existingExercise != null;
    /*

Newly Added :

*/
    final result = await showModalBottomSheet<bool>(
      context: outerContext,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) => ExerciseFormBottomSheet(
        existingExercise: existingExercise,
        outerContext: outerContext,
        workoutService: _workoutService,
      ),
    );

    // if (result == true && !_workoutStopwatch.isRunning) {
    //   _workoutStopwatch.start();
    // } else
    // if (result == true && outerContext.mounted) {
    //   _showExerciseLoggedSuccess(outerContext);
    // }
    // updated :
    if (result == true && outerContext.mounted) {
      _showExerciseLoggedSuccess(outerContext, isEditing: isEditing);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        // Provider.of<AuthProvider>(context).currentUser?.email ?? '';
        // updated
        (Provider.of<AuthProvider>(context).currentUser?.email ?? '')
            .toLowerCase();
    // final workoutProvider = context.watch<WorkoutProvider>();
    final exerciseBox = Hive.box<ExerciseModel>(HiveService.exerciseBoxName);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // final workoutTitle = workoutProvider.nextWorkoutName;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: ValueListenableBuilder(
            valueListenable: exerciseBox.listenable(),
            builder: (context, Box<ExerciseModel> box, _) {
              final userExercises = box.values
                  .where((e) =>
                      e.userId.toLowerCase() == currentUserId ||
                      e.userId.isEmpty)
                  .toList();
/*

Newly Added userexercise :

*/

              if (userExercises.isEmpty && _workoutStopwatch.isRunning) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _resetAndStopTimer();
                });
              }

              final dynamicTitle = _deriveDynamicWorkoutTitle(userExercises);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dynamicTitle,
                      style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[400] : Colors.grey[600])),
                  Text(
                    _formatDuration(_workoutStopwatch.elapsed),
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87),
                  ),
                ],
              );
            }),
        actions: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA3E635),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              onPressed: () => WorkoutActions.finishWorkoutSession(
                context,
                _workoutStopwatch.elapsed,
                _formatDuration,
              ),
              child: const Text('Finish',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            )
                .animate(onPlay: (c) => c.repeat())
                .shimmer(duration: const Duration(seconds: 2)),
          ),
        ],
      ),
      floatingActionButton: OpenContainer<bool>(
        transitionDuration: const Duration(milliseconds: 350),
        closedColor: const Color(0xFFA3E635),
        openColor: isDark ? const Color(0xFF131313) : Colors.white,
        closedElevation: 6.0,
        openElevation: 0.0,
        closedShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(28)),
        ),
        // Newly Added :
        // Listen for the true result when the form sheet pops/saves
        onClosed: (bool? result) {
          if (result == true && mounted) {
            _showExerciseLoggedSuccess(context, isEditing: false);
          }
        },
        closedBuilder: (context, openContainer) => FloatingActionButton(
          backgroundColor: const Color(0xFFA3E635),
          elevation: 0,
          onPressed: openContainer,
          child: const Icon(Icons.add, color: Colors.black),
        ),
        openBuilder: (context, closedContainer) => ExerciseFormBottomSheet(
          existingExercise: null,
          outerContext: context,
          workoutService: _workoutService,
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: exerciseBox.listenable(),
        builder: (context, Box<ExerciseModel> box, _) {
          final exercises = box.values
              .where((exercise) =>
                  // exercise.userId == currentUserId || exercise.userId.isEmpty)
                  exercise.userId.toLowerCase() == currentUserId ||
                  exercise.userId.isEmpty)
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (exercises.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 40.0),
                    child: EmptyStateWidget(
                      icon: Icons.fitness_center_rounded,
                      title: 'No workouts logged today',
                      description: 'Tap + below to add your first exercise.',
                      buttonLabel: 'Log Exercise',
                      onPressed: () => _showAddWorkoutModal(context),
                    ),
                  )
                else
                  ...exercises.asMap().entries.map((exerciseEntry) {
                    final exerciseIndex = exerciseEntry.key;
                    final exercise = exerciseEntry.value;
                    final isPr = exercise.isPr(box);
                    final sets = exercise.setsList ?? [];
                    final isExpanded = _expandedExerciseId == exercise.id;
                    // newly added

                    if (!isExpanded) {
                      final lastWeight =
                          sets.isNotEmpty ? sets.last.weight : exercise.weight;
                      final lastReps =
                          sets.isNotEmpty ? sets.last.reps : exercise.reps;
                      return Dismissible(
                        key: Key(exercise.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(16)),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),

                        // onDismissed: (_) => WorkoutActions.deleteExercise(
                        //   context,
                        //   exercise,
                        //   _activeRestExerciseId,
                        //   () {
                        //     _restTimer?.cancel();
                        //     _activeRestExerciseId = null;
                        //   },
                        // ),

/*

Updated onDismissed :

*/

                        onDismissed: (_) {
                          WorkoutActions.deleteExercise(
                            context,
                            exercise,
                            _activeRestExerciseId,
                            () {
                              _restTimer?.cancel();
                              _activeRestExerciseId = null;
                            },
                          );
                          if (_expandedExerciseId == exercise.id) {
                            _expandedExerciseId = null;
                          }
                          // final remaining = box.values
                          //     .where((e) =>
                          //         e.userId.toLowerCase() == currentUserId ||
                          //         e.userId.isEmpty)
                          //     .toList();
                          // if (remaining.isEmpty) {
                          //   _resetAndStopTimer();
                          // }
                          // updated :

                          if (_expandedExerciseId == null) {
                            _resetAndStopTimer();
                          }
                        },

                        child: GestureDetector(
                          // onTap: () => setState(() => _expandedExerciseId = exercise.id),
                          // updated
                          // onTap: () {
                          //   if (!_workoutStopwatch.isRunning) {
                          //     _workoutStopwatch.start();
                          //   }
                          //   setState(() => _expandedExerciseId = exercise.id);
                          // },

/*

Update OnTap :

*/

                          // onTap: () {
                          //   _resetAndStartTimer();
                          //   setState(() => _expandedExerciseId = exercise.id);
                          // },
                          //
/*

updated ontap again :

*/
                          onTap: () {
                            final sets = exercise.setsList ?? [];
                            final isAllDone =
                                sets.isNotEmpty && sets.every((s) => s.isDone);

                            // Only restart/start the workout stopwatch if the exercise is NOT fully completed
                            if (!isAllDone) {
                              _resetAndStartTimer();
                            }
                            setState(() => _expandedExerciseId = exercise.id);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF161B22)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: isDark
                                      ? Colors.grey.withValues(alpha: 0.15)
                                      : Colors.grey.shade300),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  exercise.name,
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87),
                                ),
                                Text(
                                  '${sets.length} sets · last ${lastWeight.toString().replaceAll(RegExp(r'\.0$'), '')}kg × $lastReps',
                                  style: TextStyle(
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                      fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return Dismissible(
                      key: Key(exercise.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(16)),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      // onDismissed: (_) => WorkoutActions.deleteExercise(
                      //   context,
                      //   exercise,
                      //   _activeRestExerciseId,
                      //   () {
                      //     _restTimer?.cancel();
                      //     _activeRestExerciseId = null;
                      //   },
                      // ),
/*

Updated onDismissed :

*/

                      onDismissed: (_) {
                        WorkoutActions.deleteExercise(
                          context,
                          exercise,
                          _activeRestExerciseId,
                          () {
                            _restTimer?.cancel();
                            _activeRestExerciseId = null;
                          },
                        );
                        // final remaining = box.values
                        //     .where((e) =>
                        //         e.userId.toLowerCase() == currentUserId ||
                        //         e.userId.isEmpty)
                        //     .toList();
                        // if (remaining.isEmpty) {
                        //   _resetAndStopTimer();
                        // }
                        // updated :
                        if (_expandedExerciseId == exercise.id) {
                          _expandedExerciseId = null;
                        }
                        if (_expandedExerciseId == null) {
                          _resetAndStopTimer();
                        }
                      },

                      child: Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              isDark ? const Color(0xFF161B22) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFFA3E635)
                                  .withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              // onTap: () =>
                              //     setState(() => _expandedExerciseId = null),
/*

Updated OnTap :

*/

                              onTap: () {
                                _resetAndStopTimer();
                                setState(() => _expandedExerciseId = null);
                              },

                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        exercise.name,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                      if (isPr) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.shade700,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'PR',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        )
                                            .animate(onPlay: (c) => c.repeat())
                                            .shimmer(
                                                duration:
                                                    const Duration(seconds: 2)),
                                      ],
                                    ],
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        size: 16, color: Colors.grey),
                                    onPressed: () => _showAddWorkoutModal(
                                        context,
                                        existingExercise: exercise),
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                  ).animate(onPlay: (c) => c.repeat()).shimmer(
                                      duration: const Duration(seconds: 2)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Row(
                              children: [
                                SizedBox(
                                    width: 35,
                                    child: Text('SET',
                                        style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold))),
                                Expanded(
                                    flex: 3,
                                    child: Text('PREVIOUS',
                                        style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold))),
                                Expanded(
                                    flex: 2,
                                    child: Text('KG',
                                        style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold))),
                                Expanded(
                                    flex: 2,
                                    child: Text('REPS',
                                        style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold))),
                                SizedBox(width: 44),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...sets.asMap().entries.map((entry) {
                              final i = entry.key;
                              final setItem = entry.value;
                              final prevStr =
                                  _getPreviousSetString(box, exercise.name, i);
                              // newly added
                              final setKeyStr = '${exercise.id}_set_$i';
                              final isNewSet = _newlyAddedSetKey == setKeyStr;

                              return Dismissible(
                                key: Key(
                                    '${exercise.id}_set_${i}_${setItem.hashCode}'),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.delete,
                                      color: Colors.white, size: 18),
                                ),
                                onDismissed: (_) {
                                  WorkoutActions.deleteSetWithUndo(
                                    context,
                                    exercise,
                                    sets,
                                    i,
                                    () => setState(() {}),
                                  );
                                },
                                child: _GlowingSetRow(
                                  // updated row from glow row
                                  key: Key(setKeyStr),
                                  isNew: isNewSet,
                                  isDark: isDark,
                                  child: SetRowItem(
                                    index: i,
                                    setItem: setItem,
                                    exercise: exercise,
                                    prevStr: prevStr,
                                    isDark: isDark,
                                    box: box,
                                    exerciseIndex: exerciseIndex,
                                    exercises: exercises,
                                    onTapPr: () async {
                                      if (setItem.isPr) {
                                        setState(() {
                                          setItem.isDone = false;
                                          setItem.isPr = false;
                                        });
                                        await exercise.save();
                                      }
                                    },
                                    onToggleDone: () async {
                                      if (!_workoutStopwatch.isRunning) {
                                        _workoutStopwatch.start();
                                      }

                                      final bool wasDone = setItem.isDone;

                                      if (wasDone) {
                                        setState(() {
                                          setItem.isDone = false;
                                          setItem.isPr = false;
                                        });
                                        await exercise.save();
                                        return;
                                      }
                                      final prevLogs = box.values.where((e) =>
                                          e.name.trim().toLowerCase() ==
                                              exercise.name
                                                  .trim()
                                                  .toLowerCase() &&
                                          e.id != exercise.id);

                                      double maxPrevWeight = 0.0;
                                      for (var prev in prevLogs) {
                                        if (prev.setsList != null &&
                                            prev.setsList!.isNotEmpty) {
                                          for (var s in prev.setsList!) {
                                            if (s.weight > maxPrevWeight) {
                                              maxPrevWeight = s.weight;
                                            }
                                          }
                                        } else {
                                          if (prev.weight > maxPrevWeight) {
                                            maxPrevWeight = prev.weight;
                                          }
                                        }
                                      }

                                      for (int j = 0; j < i; j++) {
                                        if (sets[j].weight > maxPrevWeight) {
                                          maxPrevWeight = sets[j].weight;
                                        }
                                      }

                                      final isNewPr =
                                          setItem.weight > maxPrevWeight &&
                                              maxPrevWeight > 0;

                                      if (isNewPr) {
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                          if (mounted) {
                                            WorkoutActions.showPrCelebration(
                                                context,
                                                exercise.name,
                                                setItem.weight,
                                                setItem.reps, () async {
                                              setState(() {
                                                setItem.isDone = true;
                                                setItem.isPr = true;
                                              });
                                              await exercise.save();

                                              if (!_showStreakBounce) {
                                                await _triggerStreakAnimation();
                                              }
                                              _checkExerciseCompletionStatus(
                                                  exercise);

                                              _triggerRestTimerForSet(
                                                  exercise,
                                                  sets,
                                                  i,
                                                  exerciseIndex,
                                                  exercises);
                                            });
                                          }
                                        });
                                      } else {
                                        setState(() {
                                          setItem.isDone = true;
                                        });
                                        await exercise.save();

                                        if (!_showStreakBounce) {
                                          await _triggerStreakAnimation();
                                        }
                                        _checkExerciseCompletionStatus(
                                            exercise);

                                        _triggerRestTimerForSet(exercise, sets,
                                            i, exerciseIndex, exercises);
                                      }
                                    },
                                    onWeightChanged: (newWeight) async {
                                      setItem.weight = newWeight;
                                      await exercise.save();
                                    },
                                    onRepsChanged: (newReps) async {
                                      setItem.reps = newReps;
                                      await exercise.save();
                                    },
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: 12),
                            // Center(
                            //   child: TextButton.icon(
                            //     style: TextButton.styleFrom(
                            //         foregroundColor: const Color(0xFFA3E635)),
                            //     onPressed: () async {
                            //       setState(() {
                            //         final lastW = sets.isNotEmpty
                            //             ? sets.last.weight
                            //             : 60.0;
                            //         final lastR =
                            //             sets.isNotEmpty ? sets.last.reps : 10;
                            //         sets.add(
                            //             SetModel(weight: lastW, reps: lastR));
                            //       });
                            //       await exercise.save();
                            //     },
                            //     icon: const Icon(Icons.add, size: 18),
                            //     label: const Text('Add set',
                            //         style:
                            //             TextStyle(fontWeight: FontWeight.bold)),
                            //   ),
                            // ),
                            // updated :
                            // Center(
                            //   child: (sets.isNotEmpty &&
                            //           sets.every((s) => s.isDone) &&
                            //           exerciseIndex == exercises.length - 1)
                            //       ? Container(
                            //           padding: const EdgeInsets.symmetric(
                            //               horizontal: 16, vertical: 8),
                            //           decoration: BoxDecoration(
                            //             color: const Color(0xFFA3E635)
                            //                 .withValues(alpha: 0.2),
                            //             borderRadius: BorderRadius.circular(12),
                            //           ),
                            //           child: const Text(
                            //             'Completed',
                            //             style: TextStyle(
                            //               color: Color(0xFFA3E635),
                            //               fontWeight: FontWeight.bold,
                            //               fontSize: 14,
                            //             ),
                            //           ),
                            //         )
                            //       : TextButton.icon(
                            //           style: TextButton.styleFrom(
                            //               foregroundColor:
                            //                   const Color(0xFFA3E635)),
                            //           onPressed: () async {
                            //             setState(() {
                            //               final lastW = sets.isNotEmpty
                            //                   ? sets.last.weight
                            //                   : 60.0;
                            //               final lastR = sets.isNotEmpty
                            //                   ? sets.last.reps
                            //                   : 10;
                            //               sets.add(SetModel(
                            //                   weight: lastW, reps: lastR));
                            //             });
                            //             await exercise.save();
                            //           },
                            //           icon: const Icon(Icons.add, size: 18),
                            //           label: const Text('Add set',
                            //               style: TextStyle(
                            //                   fontWeight: FontWeight.bold)),
                            //         ),
                            // ),
/*


updated  : 


*/

//                             Center(
//                               child: (sets.isNotEmpty &&
//                                       sets.every((s) => s.isDone))
//                                   ? Container(
//                                       padding: const EdgeInsets.symmetric(
//                                           horizontal: 16, vertical: 8),
//                                       decoration: BoxDecoration(
//                                         color: const Color(0xFFA3E635)
//                                             .withValues(alpha: 0.2),
//                                         borderRadius: BorderRadius.circular(12),
//                                       ),
//                                       child: const Text(
//                                         'Completed',
//                                         style: TextStyle(
//                                           color: Color(0xFFA3E635),
//                                           fontWeight: FontWeight.bold,
//                                           fontSize: 14,
//                                         ),
//                                       ),
//                                     )
//                                   : TextButton.icon(
//                                       style: TextButton.styleFrom(
//                                           foregroundColor:
//                                               const Color(0xFFA3E635)),
//                                       onPressed: () async {
//                                         setState(() {
//                                           final lastW = sets.isNotEmpty
//                                               ? sets.last.weight
//                                               : 60.0;
//                                           final lastR = sets.isNotEmpty
//                                               ? sets.last.reps
//                                               : 10;
//                                           sets.add(SetModel(
//                                               weight: lastW, reps: lastR));
//                                         });
//                                         await exercise.save();
//                                       },
//                                       icon: const Icon(Icons.add, size: 18),
//                                       label: const Text('Add set',
//                                           style: TextStyle(
//                                               fontWeight: FontWeight.bold)),
//                                     ),
//                             ),
/*


updated 2 : 


*/

                            // Center(
                            //   child: (sets.isNotEmpty &&
                            //           sets.every((s) => s.isDone))
                            //       ? Container(
                            //           padding: const EdgeInsets.symmetric(
                            //               horizontal: 16, vertical: 8),
                            //           decoration: BoxDecoration(
                            //             color: const Color(0xFFA3E635)
                            //                 .withValues(alpha: 0.2),
                            //             borderRadius: BorderRadius.circular(12),
                            //           ),
                            //           child: const Text(
                            //             'Completed',
                            //             style: TextStyle(
                            //               color: Color(0xFFA3E635),
                            //               fontWeight: FontWeight.bold,
                            //               fontSize: 14,
                            //             ),
                            //           ),
                            //         )
                            //       : TextButton.icon(
                            //           style: TextButton.styleFrom(
                            //               foregroundColor:
                            //                   const Color(0xFFA3E635)),
                            //           onPressed: () => _showAddWorkoutModal(
                            //             context,
                            //             existingExercise: exercise,
                            //           ),
                            //           icon: const Icon(Icons.add, size: 18),
                            //           label: const Text('Add set',
                            //               style: TextStyle(
                            //                   fontWeight: FontWeight.bold)),
                            //         ),
                            // ),

                            // Center(
                            //   child: (sets.isNotEmpty &&
                            //           sets.every((s) => s.isDone))
                            //       ? Container(
                            //           padding: const EdgeInsets.symmetric(
                            //               horizontal: 16, vertical: 8),
                            //           decoration: BoxDecoration(
                            //             color: const Color(0xFFA3E635)
                            //                 .withValues(alpha: 0.2),
                            //             borderRadius: BorderRadius.circular(12),
                            //           ),
                            //           child: const Text(
                            //             'Completed',
                            //             style: TextStyle(
                            //               color: Color(0xFFA3E635),
                            //               fontWeight: FontWeight.bold,
                            //               fontSize: 14,
                            //             ),
                            //           ),
                            //         )
                            //       : TextButton.icon(
                            //           style: TextButton.styleFrom(
                            //               foregroundColor:
                            //                   const Color(0xFFA3E635)),
                            //           onPressed: () async {
                            //             final lastW = sets.isNotEmpty
                            //                 ? sets.last.weight
                            //                 : 60.0;
                            //             final lastR = sets.isNotEmpty
                            //                 ? sets.last.reps
                            //                 : 10;

                            //             // Check if identical set already exists
                            //             final bool duplicateExists = sets.any(
                            //               (s) =>
                            //                   s.weight == lastW &&
                            //                   s.reps == lastR,
                            //             );

                            //             if (duplicateExists) {
                            //               HapticFeedback.heavyImpact();
                            //               ScaffoldMessenger.of(context)
                            //                   .clearSnackBars();
                            //               ScaffoldMessenger.of(context)
                            //                   .showSnackBar(
                            //                 const SnackBar(
                            //                   behavior:
                            //                       SnackBarBehavior.floating,
                            //                   backgroundColor:
                            //                       Color(0xFF161B22),
                            //                   content: Text(
                            //                     'This set already exists!',
                            //                     style: TextStyle(
                            //                         color: Colors.white,
                            //                         fontWeight:
                            //                             FontWeight.bold),
                            //                   ),
                            //                   duration: Duration(seconds: 2),
                            //                 ),
                            //               );
                            //               return;
                            //             }

                            //             final newSet = SetModel(
                            //                 weight: lastW, reps: lastR);
                            //             setState(() {
                            //               sets.add(newSet);
                            //               _newlyAddedSetKey =
                            //                   '${exercise.id}_set_${sets.length - 1}';
                            //             });
                            //             await exercise.save();

                            //             // Clear glow key after animation completes
                            //             Future.delayed(
                            //                 const Duration(milliseconds: 3500),
                            //                 () {
                            //               if (mounted &&
                            //                   _newlyAddedSetKey ==
                            //                       '${exercise.id}_set_${sets.length - 1}') {
                            //                 setState(
                            //                     () => _newlyAddedSetKey = null);
                            //               }
                            //             });
                            //           },
                            //           icon: const Icon(Icons.add, size: 18),
                            //           label: const Text('Add set',
                            //               style: TextStyle(
                            //                   fontWeight: FontWeight.bold)),
                            //         ),
                            // ),

/*


updated 3 : 


*/

                            Center(
                              child: (sets.isNotEmpty &&
                                      sets.every((s) => s.isDone))
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFA3E635)
                                            .withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'Completed',
                                        style: TextStyle(
                                          color: Color(0xFFA3E635),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    )
                                  : TextButton.icon(
                                      style: TextButton.styleFrom(
                                          foregroundColor:
                                              const Color(0xFFA3E635)),
                                      onPressed: () async {
                                        final result =
                                            await showModalBottomSheet<bool>(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor:
                                              const Color(0xFF161B22),
                                          shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.vertical(
                                                top: Radius.circular(24)),
                                          ),
                                          builder: (modalContext) =>
                                              AddSetBottomSheet(
                                            exercise: exercise,
                                          ),
                                        );

                                        if (result == true && mounted) {
                                          // update added :
                                          final updatedSets =
                                              exercise.setsList ?? [];
                                          setState(() {
                                            _newlyAddedSetKey =
                                                '${exercise.id}_set_${sets.length - 1}';
                                          });
// update added
                                          _showSetLoggedSuccess(context);
                                          Future.delayed(
                                              const Duration(
                                                  milliseconds: 3500), () {
                                            if (mounted &&
                                                _newlyAddedSetKey ==
                                                    '${exercise.id}_set_${sets.length - 1}') {
                                              setState(() =>
                                                  _newlyAddedSetKey = null);
                                            }
                                          });
                                        }
                                      },
                                      icon: const Icon(Icons.add, size: 18),
                                      label: const Text('Add set',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ),
                            ),

                            if (_activeRestExerciseId == exercise.id &&
                                _restSecondsRemaining > 0)
                              RestTimerCard(
                                isDark: isDark,
                                restSecondsRemaining: _restSecondsRemaining,
                                activeRestInfo: _activeRestInfo,
                                onMinus15: () => setState(() =>
                                    _restSecondsRemaining =
                                        (_restSecondsRemaining - 15)
                                            .clamp(0, 300)),
                                onPlus15: () =>
                                    setState(() => _restSecondsRemaining += 15),
                                onSkip: () => setState(() {
                                  _restSecondsRemaining = 0;
                                  _activeRestExerciseId = null;
                                }),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class EggClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();

    path.moveTo(w * 0.5, 0);
    path.cubicTo(w * 0.18, 0, 0, h * 0.38, w * 0.06, h * 0.65);
    path.cubicTo(w * 0.10, h * 0.92, w * 0.32, h, w * 0.5, h);
    path.cubicTo(w * 0.68, h, w * 0.90, h * 0.92, w * 0.94, h * 0.65);
    path.cubicTo(w, h * 0.38, w * 0.82, 0, w * 0.5, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// newly added

class _GlowingSetRow extends StatefulWidget {
  final Widget child;
  final bool isNew;
  final bool isDark;
  final bool forceSlide;

  const _GlowingSetRow({
    super.key,
    required this.child,
    required this.isNew,
    required this.isDark,
    this.forceSlide = false,
  });

  @override
  State<_GlowingSetRow> createState() => _GlowingSetRowState();
}

class _GlowingSetRowState extends State<_GlowingSetRow>
    with SingleTickerProviderStateMixin {
  bool _glowActive = false;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      // duration: const Duration(milliseconds: 1600),
      duration: const Duration(seconds: 3),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeIn));

    if (widget.isNew || widget.forceSlide) {
      _slideController.forward();
    } else {
      _slideController.value = 1.0;
    }

    _startGlowIfNeeded();
  }

  void _startGlowIfNeeded() {
    if (widget.isNew) {
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) setState(() => _glowActive = true);
        Future.delayed(const Duration(milliseconds: 1800), () {
          if (mounted) setState(() => _glowActive = false);
        });
      });
    }
  }

  @override
  void didUpdateWidget(covariant _GlowingSetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.forceSlide && !oldWidget.forceSlide) {
      _slideController.forward(from: 0);
    }
    if (widget.isNew && !oldWidget.isNew) {
      _glowActive = false;
      _startGlowIfNeeded();
      _slideController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color normalBg = widget.isDark
        ? const Color.fromARGB(0, 42, 42, 42)
        : const Color.fromARGB(255, 253, 253, 253);

    final Color glowBg = widget.isDark
        ? const Color(0xFF324D1E)
        : const Color.fromARGB(255, 208, 252, 144);

    const Color glowBorder = Color.fromARGB(255, 153, 255, 0);

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: AnimatedContainer(
          duration: const Duration(seconds: 2),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: _glowActive ? glowBg : normalBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _glowActive ? glowBorder : Colors.transparent,
              width: _glowActive ? 3.5 : 0.0,
            ),
            boxShadow: _glowActive
                ? [
                    BoxShadow(
                      color: const Color.fromARGB(255, 188, 238, 114)
                          .withValues(alpha: widget.isDark ? 0.25 : 0.3),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/*



updated



*/
