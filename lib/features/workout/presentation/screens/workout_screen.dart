// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_animate/flutter_animate.dart';
// import 'package:gym_tracker_app/core/services/streak_service.dart';
// import 'package:gym_tracker_app/features/auth/data/models/set_model.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:provider/provider.dart';

// import '../../../../core/services/hive_service.dart';
// import '../../../../core/widgets/empty_state_widget.dart';
// import '../../../auth/presentation/providers/auth_provider.dart';
// import '../../data/models/exercise_model.dart';
// import '../../data/services/workout_service.dart';

// // Import subfiles and workout actions
// import 'workout_screen.dart Sub-Files/set_row_item.dart';
// import 'workout_screen.dart Sub-Files/rest_timer_card.dart';
// import 'workout_screen.dart Sub-Files/exercise_form_bottom_sheet.dart';
// import 'workout_screen.dart Sub-Files/workout_actions.dart';

// class WorkoutScreen extends StatefulWidget {
//   const WorkoutScreen({super.key});

//   @override
//   State<WorkoutScreen> createState() => _WorkoutScreenState();
// }

// class _WorkoutScreenState extends State<WorkoutScreen> {
//   final WorkoutService _workoutService = WorkoutService();
//   late Stopwatch _workoutStopwatch;
//   Timer? _stopwatchTimer;
//   int _restSecondsRemaining = 0;
//   Timer? _restTimer;
//   String _activeRestInfo = '';

//   String? _activeRestExerciseId;
//   String? _expandedExerciseId;

//   // Track streak animation/flip flag for the first log of the day
//   bool _showStreakBounce = false;
//   int _currentStreak = 5; // Example streak count

//   // @override
//   // void initState() {
//   //   super.initState();
//   //   _workoutStopwatch = Stopwatch()..start();
//   //   _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (_) {
//   //     if (mounted) setState(() {});
//   //   });
//   // }

//   @override
//   void initState() {
//     super.initState();
//     _workoutStopwatch = Stopwatch()..start();
//     _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (_) {
//       if (mounted) setState(() {});
//     });
//     _loadInitialStreak(); // ---> ADD THIS
//   }

//   Future<void> _loadInitialStreak() async {
//     final streak = StreakService.getCurrentStreak();
//     setState(() {
//       _currentStreak = streak;
//     });
//   }

//   @override
//   void dispose() {
//     _stopwatchTimer?.cancel();
//     _restTimer?.cancel();
//     _workoutStopwatch.stop();
//     super.dispose();
//   }

//   String _formatDuration(Duration d) {
//     String twoDigits(int n) => n.toString().padLeft(2, '0');
//     final hours = twoDigits(d.inHours);
//     final minutes = twoDigits(d.inMinutes.remainder(60));
//     final seconds = twoDigits(d.inSeconds.remainder(60));
//     return '$hours:$minutes:$seconds';
//   }

//   // void _triggerStreakAnimation() {
//   //   setState(() {
//   //     _currentStreak += 1;
//   //     _showStreakBounce = true;
//   //   });

//   //   HapticFeedback.heavyImpact();

//   //   showDialog(
//   //     context: context,
//   //     barrierDismissible: true,
//   //     builder: (ctx) {
//   //       Future.delayed(const Duration(milliseconds: 1400), () {
//   //         if (ctx.mounted) Navigator.of(ctx, rootNavigator: true).pop();
//   //       });
//   //       return Center(
//   //         child: Container(
//   //           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
//   //           decoration: BoxDecoration(
//   //             gradient: const LinearGradient(
//   //               colors: [Color(0xFFF97316), Color(0xFFEF4444)],
//   //               begin: Alignment.topLeft,
//   //               end: Alignment.bottomRight,
//   //             ),
//   //             borderRadius: BorderRadius.circular(20),
//   //             boxShadow: [
//   //               BoxShadow(
//   //                 color: Colors.orange.withValues(alpha: 0.5),
//   //                 blurRadius: 20,
//   //                 spreadRadius: 5,
//   //               )
//   //             ],
//   //           ),
//   //           child: Column(
//   //             mainAxisSize: MainAxisSize.min,
//   //             children: [
//   //               const Icon(Icons.local_fire_department,
//   //                       color: Colors.white, size: 48)
//   //                   .animate(onPlay: (c) => c.repeat(reverse: true))
//   //                   .scale(
//   //                       begin: const Offset(0.8, 0.8),
//   //                       end: const Offset(1.2, 1.2),
//   //                       duration: const Duration(milliseconds: 400)),
//   //               const SizedBox(height: 8),
//   //               Text(
//   //                 'Streak +1: $_currentStreak Days!',
//   //                 style: const TextStyle(
//   //                   color: Colors.white,
//   //                   fontSize: 18,
//   //                   fontWeight: FontWeight.bold,
//   //                   decoration: TextDecoration.none,
//   //                 ),
//   //               ),
//   //             ],
//   //           ),
//   //         ),
//   //       );
//   //     },
//   //   );
//   // }

//   Future<void> _triggerStreakAnimation() async {
//     // Check and update persistent streak via service
//     final result = await StreakService.checkAndIncrementStreak();
//     bool isNewDay = result['isNewDay'];
//     int updatedStreak = result['streak'];

//     // If it's not a new day, we don't need to re-trigger the daily streak bounce popup
//     if (!isNewDay && _showStreakBounce) return;

//     setState(() {
//       _currentStreak = updatedStreak;
//       _showStreakBounce = true;
//     });

//     HapticFeedback.heavyImpact();

//     showDialog(
//       context: context,
//       barrierDismissible: true,
//       builder: (ctx) {
//         Future.delayed(const Duration(milliseconds: 1600), () {
//           if (ctx.mounted) Navigator.of(ctx, rootNavigator: true).pop();
//         });
//         return Center(
//           child: Material(
//             color: Colors.transparent,
//             child: TweenAnimationBuilder<double>(
//               tween: Tween<double>(begin: 0.0, end: 1.0),
//               duration: const Duration(milliseconds: 600),
//               curve: Curves.elasticOut,
//               builder: (context, value, child) {
//                 return Transform.scale(
//                   scale: value,
//                   child: child,
//                 );
//               },
//               child: Container(
//                 width: 180,
//                 height: 220,
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
//                 decoration: BoxDecoration(
//                   gradient: const LinearGradient(
//                     colors: [Color(0xFFF97316), Color(0xFFEF4444)],
//                     begin: Alignment.topCenter,
//                     end: Alignment.bottomCenter,
//                   ),
//                   borderRadius:
//                       const BorderRadius.all(Radius.elliptical(120, 150)),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.orange.withValues(alpha: 0.6),
//                       blurRadius: 25,
//                       spreadRadius: 8,
//                     )
//                   ],
//                 ),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Icon(Icons.local_fire_department,
//                             color: Colors.white, size: 40)
//                         .animate(onPlay: (c) => c.repeat(reverse: true))
//                         .scale(
//                           begin: const Offset(0.85, 0.85),
//                           end: const Offset(1.15, 1.15),
//                           duration: const Duration(milliseconds: 350),
//                           curve: Curves.easeInOut,
//                         ),
//                     const SizedBox(height: 6),
//                     Text(
//                       '$_currentStreak',
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 42,
//                         fontWeight: FontWeight.bold,
//                         decoration: TextDecoration.none,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     const Text(
//                       'Streak +1',
//                       style: TextStyle(
//                         color: Colors.white70,
//                         fontSize: 13,
//                         fontWeight: FontWeight.w600,
//                         decoration: TextDecoration.none,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   void _triggerRestTimerForSet(ExerciseModel exercise, List<SetModel> sets,
//       int i, int exerciseIndex, List<ExerciseModel> exercises) {
//     String nextInfo;
//     if (i < sets.length - 1) {
//       final nextSet = sets[i + 1];
//       nextInfo =
//           'Next: Set ${i + 2} · ${nextSet.weight.toString().replaceAll(RegExp(r'\.0$'), '')}kg × ${nextSet.reps}';
//     } else if (exerciseIndex < exercises.length - 1) {
//       final nextExercise = exercises[exerciseIndex + 1];
//       final nextExSets = nextExercise.setsList ?? [];
//       if (nextExSets.isNotEmpty) {
//         final lastSet = nextExSets.last;
//         nextInfo =
//             'Next: ${nextExercise.name} · ${nextExSets.length} sets · last ${lastSet.weight.toString().replaceAll(RegExp(r'\.0$'), '')}kg × ${lastSet.reps}';
//       } else {
//         nextInfo = 'Next: ${nextExercise.name}';
//       }
//     } else {
//       nextInfo = 'Final exercise completed!';
//     }

//     _startRestTimer(
//       exercise.id,
//       seconds: 90,
//       info: nextInfo,
//     );
//   }

//   void _startRestTimer(String exerciseId,
//       {int seconds = 60, String info = ''}) {
//     _restTimer?.cancel();
//     setState(() {
//       _activeRestExerciseId = exerciseId;
//       _restSecondsRemaining = seconds;
//       _activeRestInfo = info;
//     });
//     _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (_restSecondsRemaining > 0) {
//         setState(() {
//           _restSecondsRemaining--;
//         });
//       } else {
//         timer.cancel();
//         _activeRestExerciseId = null;
//       }
//     });
//   }

//   void _showAddWorkoutModal(
//     BuildContext outerContext, {
//     ExerciseModel? existingExercise,
//   }) {
//     showModalBottomSheet(
//       context: outerContext,
//       isScrollControlled: true,
//       backgroundColor: const Color(0xFF161B22),
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//       ),
//       builder: (modalContext) => ExerciseFormBottomSheet(
//         existingExercise: existingExercise,
//         outerContext: outerContext,
//         workoutService: _workoutService,
//       ),
//     );
//   }

//   String _getPreviousSetString(
//       Box<ExerciseModel> box, String exerciseName, int setIndex) {
//     final previousLogs = box.values
//         .where((e) =>
//             e.name.trim().toLowerCase() == exerciseName.trim().toLowerCase() &&
//             e.setsList != null &&
//             e.setsList!.isNotEmpty)
//         .toList();

//     if (previousLogs.isEmpty) return '-';
//     previousLogs.sort((a, b) =>
//         (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));

//     final lastLog = previousLogs.first;
//     if (lastLog.setsList != null && lastLog.setsList!.length > setIndex) {
//       final prevSet = lastLog.setsList![setIndex];
//       return '${prevSet.weight.toString().replaceAll(RegExp(r'\.0$'), '')} × ${prevSet.reps}';
//     }
//     return '-';
//   }

//   @override
//   Widget build(BuildContext context) {
//     final currentUserId =
//         Provider.of<AuthProvider>(context).currentUser?.email ?? '';
//     final exerciseBox = Hive.box<ExerciseModel>(HiveService.exerciseBoxName);
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     return Scaffold(
//       backgroundColor: isDark ? const Color(0xFF0D1117) : Colors.grey[100],
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('Push Day',
//                 style: TextStyle(
//                     fontSize: 13,
//                     color: isDark ? Colors.grey[400] : Colors.grey[600])),
//             Text(
//               _formatDuration(_workoutStopwatch.elapsed),
//               style: TextStyle(
//                   fontSize: 22,
//                   fontWeight: FontWeight.bold,
//                   color: isDark ? Colors.white : Colors.black87),
//             ),
//           ],
//         ),
//         actions: [
//           Padding(
//             padding:
//                 const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//             child: ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFFA3E635),
//                 foregroundColor: Colors.black,
//                 shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(20)),
//                 padding: const EdgeInsets.symmetric(horizontal: 20),
//               ),
//               onPressed: () => WorkoutActions.finishWorkoutSession(
//                 context,
//                 _workoutStopwatch.elapsed,
//                 _formatDuration,
//               ),
//               child: const Text('Finish',
//                   style: TextStyle(fontWeight: FontWeight.bold)),
//             )
//                 .animate(onPlay: (c) => c.repeat())
//                 .shimmer(duration: const Duration(seconds: 2)),
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         backgroundColor: const Color(0xFFA3E635),
//         tooltip: 'Add Exercise',
//         onPressed: () => _showAddWorkoutModal(context),
//         child: const Icon(Icons.add, color: Colors.black),
//       ),
//       body: ValueListenableBuilder(
//         valueListenable: exerciseBox.listenable(),
//         builder: (context, Box<ExerciseModel> box, _) {
//           final exercises = box.values
//               .where((exercise) =>
//                   exercise.userId == currentUserId || exercise.userId.isEmpty)
//               .toList();

//           return SingleChildScrollView(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 if (exercises.isEmpty)
//                   Padding(
//                     padding: const EdgeInsets.only(top: 40.0),
//                     child: EmptyStateWidget(
//                       icon: Icons.fitness_center_rounded,
//                       title: 'No workouts logged today',
//                       description: 'Tap + below to add your first exercise.',
//                       buttonLabel: 'Log Exercise',
//                       onPressed: () => _showAddWorkoutModal(context),
//                     ),
//                   )
//                 else
//                   ...exercises.asMap().entries.map((exerciseEntry) {
//                     final exerciseIndex = exerciseEntry.key;
//                     final exercise = exerciseEntry.value;
//                     final isPr = exercise.isPr(box);
//                     final sets = exercise.setsList ?? [];
//                     final isExpanded = _expandedExerciseId == exercise.id;

//                     // Collapsed View
//                     if (!isExpanded) {
//                       final lastWeight =
//                           sets.isNotEmpty ? sets.last.weight : exercise.weight;
//                       final lastReps =
//                           sets.isNotEmpty ? sets.last.reps : exercise.reps;
//                       return Dismissible(
//                         key: Key(exercise.id),
//                         direction: DismissDirection.endToStart,
//                         background: Container(
//                           alignment: Alignment.centerRight,
//                           padding: const EdgeInsets.only(right: 20),
//                           decoration: BoxDecoration(
//                               color: Colors.red,
//                               borderRadius: BorderRadius.circular(16)),
//                           child: const Icon(Icons.delete, color: Colors.white),
//                         ),
//                         onDismissed: (_) => WorkoutActions.deleteExercise(
//                           context,
//                           exercise,
//                           _activeRestExerciseId,
//                           () {
//                             _restTimer?.cancel();
//                             _activeRestExerciseId = null;
//                           },
//                         ),
//                         child: GestureDetector(
//                           onTap: () =>
//                               setState(() => _expandedExerciseId = exercise.id),
//                           child: Container(
//                             margin: const EdgeInsets.only(bottom: 12),
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 16, vertical: 16),
//                             decoration: BoxDecoration(
//                               color: isDark
//                                   ? const Color(0xFF161B22)
//                                   : Colors.white,
//                               borderRadius: BorderRadius.circular(16),
//                               border: Border.all(
//                                   color: isDark
//                                       ? Colors.grey.withValues(alpha: 0.15)
//                                       : Colors.grey.shade300),
//                             ),
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 Text(
//                                   exercise.name,
//                                   style: TextStyle(
//                                       fontSize: 16,
//                                       fontWeight: FontWeight.bold,
//                                       color: isDark
//                                           ? Colors.white
//                                           : Colors.black87),
//                                 ),
//                                 Text(
//                                   '${sets.length} sets · last ${lastWeight.toString().replaceAll(RegExp(r'\.0$'), '')}kg × $lastReps',
//                                   style: TextStyle(
//                                       color: isDark
//                                           ? Colors.grey[400]
//                                           : Colors.grey[600],
//                                       fontSize: 13),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       );
//                     }

//                     // Expanded View
//                     return Dismissible(
//                       key: Key(exercise.id),
//                       direction: DismissDirection.endToStart,
//                       background: Container(
//                         alignment: Alignment.centerRight,
//                         padding: const EdgeInsets.only(right: 20),
//                         decoration: BoxDecoration(
//                             color: Colors.red,
//                             borderRadius: BorderRadius.circular(16)),
//                         child: const Icon(Icons.delete, color: Colors.white),
//                       ),
//                       onDismissed: (_) => WorkoutActions.deleteExercise(
//                         context,
//                         exercise,
//                         _activeRestExerciseId,
//                         () {
//                           _restTimer?.cancel();
//                           _activeRestExerciseId = null;
//                         },
//                       ),
//                       child: Container(
//                         margin: const EdgeInsets.only(bottom: 20),
//                         padding: const EdgeInsets.all(16),
//                         decoration: BoxDecoration(
//                           color:
//                               isDark ? const Color(0xFF161B22) : Colors.white,
//                           borderRadius: BorderRadius.circular(16),
//                           border: Border.all(
//                               color: const Color(0xFFA3E635)
//                                   .withValues(alpha: 0.3)),
//                         ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             GestureDetector(
//                               onTap: () =>
//                                   setState(() => _expandedExerciseId = null),
//                               child: Row(
//                                 mainAxisAlignment:
//                                     MainAxisAlignment.spaceBetween,
//                                 children: [
//                                   Row(
//                                     children: [
//                                       Text(
//                                         exercise.name,
//                                         style: TextStyle(
//                                           fontSize: 18,
//                                           fontWeight: FontWeight.bold,
//                                           color: isDark
//                                               ? Colors.white
//                                               : Colors.black87,
//                                         ),
//                                       ),
//                                       if (isPr) ...[
//                                         const SizedBox(width: 8),
//                                         Container(
//                                           padding: const EdgeInsets.symmetric(
//                                               horizontal: 8, vertical: 2),
//                                           decoration: BoxDecoration(
//                                             color: Colors.amber.shade700,
//                                             borderRadius:
//                                                 BorderRadius.circular(6),
//                                           ),
//                                           child: const Text(
//                                             'PR',
//                                             style: TextStyle(
//                                               color: Colors.black,
//                                               fontWeight: FontWeight.bold,
//                                               fontSize: 11,
//                                             ),
//                                           ),
//                                         )
//                                             .animate(onPlay: (c) => c.repeat())
//                                             .shimmer(
//                                                 duration:
//                                                     const Duration(seconds: 2)),
//                                       ],
//                                     ],
//                                   ),
//                                   IconButton(
//                                     icon: const Icon(Icons.edit,
//                                         size: 16, color: Colors.grey),
//                                     onPressed: () => _showAddWorkoutModal(
//                                         context,
//                                         existingExercise: exercise),
//                                     constraints: const BoxConstraints(),
//                                     padding: EdgeInsets.zero,
//                                   ).animate(onPlay: (c) => c.repeat()).shimmer(
//                                       duration: const Duration(seconds: 2)),
//                                 ],
//                               ),
//                             ),
//                             const SizedBox(height: 12),
//                             const Row(
//                               children: [
//                                 SizedBox(
//                                     width: 35,
//                                     child: Text('SET',
//                                         style: TextStyle(
//                                             color: Colors.grey,
//                                             fontSize: 12,
//                                             fontWeight: FontWeight.bold))),
//                                 Expanded(
//                                     flex: 3,
//                                     child: Text('PREVIOUS',
//                                         style: TextStyle(
//                                             color: Colors.grey,
//                                             fontSize: 12,
//                                             fontWeight: FontWeight.bold))),
//                                 Expanded(
//                                     flex: 2,
//                                     child: Text('KG',
//                                         style: TextStyle(
//                                             color: Colors.grey,
//                                             fontSize: 12,
//                                             fontWeight: FontWeight.bold))),
//                                 Expanded(
//                                     flex: 2,
//                                     child: Text('REPS',
//                                         style: TextStyle(
//                                             color: Colors.grey,
//                                             fontSize: 12,
//                                             fontWeight: FontWeight.bold))),
//                                 SizedBox(width: 44),
//                               ],
//                             ),
//                             const SizedBox(height: 8),
//                             ...sets.asMap().entries.map((entry) {
//                               final i = entry.key;
//                               final setItem = entry.value;
//                               final prevStr =
//                                   _getPreviousSetString(box, exercise.name, i);

//                               return Dismissible(
//                                 key: Key(
//                                     '${exercise.id}_set_${i}_${setItem.hashCode}'),
//                                 direction: DismissDirection.endToStart,
//                                 background: Container(
//                                   alignment: Alignment.centerRight,
//                                   padding: const EdgeInsets.only(right: 16),
//                                   decoration: BoxDecoration(
//                                     color: Colors.red,
//                                     borderRadius: BorderRadius.circular(10),
//                                   ),
//                                   child: const Icon(Icons.delete,
//                                       color: Colors.white, size: 18),
//                                 ),
//                                 onDismissed: (_) {
//                                   WorkoutActions.deleteSetWithUndo(
//                                     context,
//                                     exercise,
//                                     sets,
//                                     i,
//                                     () => setState(() {}),
//                                   );
//                                 },
//                                 child: SetRowItem(
//                                   index: i,
//                                   setItem: setItem,
//                                   exercise: exercise,
//                                   prevStr: prevStr,
//                                   isDark: isDark,
//                                   box: box,
//                                   exerciseIndex: exerciseIndex,
//                                   exercises: exercises,
//                                   onTapPr: () async {
//                                     if (setItem.isPr) {
//                                       setState(() {
//                                         setItem.isDone = false;
//                                         setItem.isPr = false;
//                                       });
//                                       await exercise.save();
//                                     }
//                                   },
//                                   onToggleDone: () async {
//                                     final bool wasDone = setItem.isDone;

//                                     if (wasDone) {
//                                       setState(() {
//                                         setItem.isDone = false;
//                                         setItem.isPr = false;
//                                       });
//                                       await exercise.save();
//                                       return;
//                                     }

//                                     // Trigger first log of the day streak bounce if first completion
//                                     if (!_showStreakBounce) {
//                                       await _triggerStreakAnimation();
//                                     }

//                                     final prevLogs = box.values.where((e) =>
//                                         e.name.trim().toLowerCase() ==
//                                             exercise.name
//                                                 .trim()
//                                                 .toLowerCase() &&
//                                         e.id != exercise.id);

//                                     double maxPrevWeight = 0.0;
//                                     for (var prev in prevLogs) {
//                                       if (prev.setsList != null &&
//                                           prev.setsList!.isNotEmpty) {
//                                         for (var s in prev.setsList!) {
//                                           if (s.weight > maxPrevWeight) {
//                                             maxPrevWeight = s.weight;
//                                           }
//                                         }
//                                       } else {
//                                         if (prev.weight > maxPrevWeight) {
//                                           maxPrevWeight = prev.weight;
//                                         }
//                                       }
//                                     }

//                                     for (int j = 0; j < i; j++) {
//                                       if (sets[j].weight > maxPrevWeight) {
//                                         maxPrevWeight = sets[j].weight;
//                                       }
//                                     }

//                                     final isNewPr =
//                                         setItem.weight > maxPrevWeight &&
//                                             maxPrevWeight > 0;

//                                     if (isNewPr) {
//                                       WidgetsBinding.instance
//                                           .addPostFrameCallback((_) {
//                                         if (mounted) {
//                                           WorkoutActions.showPrCelebration(
//                                               context,
//                                               exercise.name,
//                                               setItem.weight,
//                                               setItem.reps, () async {
//                                             setState(() {
//                                               setItem.isDone = true;
//                                               setItem.isPr = true;
//                                             });
//                                             await exercise.save();
//                                             _triggerRestTimerForSet(
//                                                 exercise,
//                                                 sets,
//                                                 i,
//                                                 exerciseIndex,
//                                                 exercises);
//                                           });
//                                         }
//                                       });
//                                     } else {
//                                       setState(() {
//                                         setItem.isDone = true;
//                                       });
//                                       await exercise.save();
//                                       _triggerRestTimerForSet(exercise, sets, i,
//                                           exerciseIndex, exercises);
//                                     }
//                                   },
//                                   onWeightChanged: (newWeight) async {
//                                     setItem.weight = newWeight;
//                                     await exercise.save();
//                                   },
//                                   onRepsChanged: (newReps) async {
//                                     setItem.reps = newReps;
//                                     await exercise.save();
//                                   },
//                                 ),
//                               );
//                             }),
//                             const SizedBox(height: 12),
//                             Center(
//                               child: TextButton.icon(
//                                 style: TextButton.styleFrom(
//                                     foregroundColor: const Color(0xFFA3E635)),
//                                 onPressed: () async {
//                                   setState(() {
//                                     final lastW = sets.isNotEmpty
//                                         ? sets.last.weight
//                                         : 60.0;
//                                     final lastR =
//                                         sets.isNotEmpty ? sets.last.reps : 10;
//                                     sets.add(
//                                         SetModel(weight: lastW, reps: lastR));
//                                   });
//                                   await exercise.save();
//                                 },
//                                 icon: const Icon(Icons.add, size: 18),
//                                 label: const Text('Add set',
//                                     style:
//                                         TextStyle(fontWeight: FontWeight.bold)),
//                               ),
//                             ),
//                             if (_activeRestExerciseId == exercise.id &&
//                                 _restSecondsRemaining > 0)
//                               RestTimerCard(
//                                 isDark: isDark,
//                                 restSecondsRemaining: _restSecondsRemaining,
//                                 activeRestInfo: _activeRestInfo,
//                                 onMinus15: () => setState(() =>
//                                     _restSecondsRemaining =
//                                         (_restSecondsRemaining - 15)
//                                             .clamp(0, 300)),
//                                 onPlus15: () =>
//                                     setState(() => _restSecondsRemaining += 15),
//                                 onSkip: () => setState(() {
//                                   _restSecondsRemaining = 0;
//                                   _activeRestExerciseId = null;
//                                 }),
//                               ),
//                           ],
//                         ),
//                       ),
//                     );
//                   }),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gym_tracker_app/core/services/streak_service.dart';
import 'package:gym_tracker_app/features/auth/data/models/set_model.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/hive_service.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/exercise_model.dart';
import '../../data/services/workout_service.dart';

// Import subfiles and workout actions
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

  // Track streak animation/flip flag for the first log of the day
  bool _showStreakBounce = false;
  int _currentStreak = 5;

  @override
  void initState() {
    super.initState();
    _workoutStopwatch = Stopwatch()..start();
    _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
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

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  // This makes the REAL egg shape like your target image

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
            // child: SizedBox(
            //   width: 250,
            //   height: ,
            child: Material(
              // animateColor: Colors.green,
              // shape: Rectangle<int>(20, 20, 150, 150),
              // shape: const Border(bottom: BorderSide(color: Colors.black)),
              // color: Colors.transparent,
              color: Colors.white,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 4800),
                curve: Curves.elasticOut, // Flip up with elastic bounce
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  // crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // --- PERFECT EGG SHAPE ---
                    ClipPath(
                      clipper: EggClipper(),
                      child: Container(
                        width: 170,
                        height: 185,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFFFFE26E), // yellow top
                              Color.fromARGB(255, 255, 98, 0), // orange mid
                              Color.fromARGB(
                                  255, 255, 0, 0), // red bottom - like target
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
                    // const SizedBox(height: 24),
                    // Text(
                    //   'Streak +1: flame bounces',
                    //   style: TextStyle(
                    //     color: Colors.grey[700],
                    //     fontSize: 18,
                    //     decoration: TextDecoration.none,
                    //   ),
                    // ),
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
      nextInfo = 'Final exercise completed!';
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
      } else {
        timer.cancel();
        _activeRestExerciseId = null;
      }
    });
  }

  void _showAddWorkoutModal(
    BuildContext outerContext, {
    ExerciseModel? existingExercise,
  }) {
    showModalBottomSheet(
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

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        Provider.of<AuthProvider>(context).currentUser?.email ?? '';
    final exerciseBox = Hive.box<ExerciseModel>(HiveService.exerciseBoxName);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Push Day',
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
        ),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFA3E635),
        tooltip: 'Add Exercise',
        onPressed: () => _showAddWorkoutModal(context),
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: ValueListenableBuilder(
        valueListenable: exerciseBox.listenable(),
        builder: (context, Box<ExerciseModel> box, _) {
          final exercises = box.values
              .where((exercise) =>
                  exercise.userId == currentUserId || exercise.userId.isEmpty)
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

                    // Collapsed View
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
                        onDismissed: (_) => WorkoutActions.deleteExercise(
                          context,
                          exercise,
                          _activeRestExerciseId,
                          () {
                            _restTimer?.cancel();
                            _activeRestExerciseId = null;
                          },
                        ),
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _expandedExerciseId = exercise.id),
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

                    // Expanded View
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
                      onDismissed: (_) => WorkoutActions.deleteExercise(
                        context,
                        exercise,
                        _activeRestExerciseId,
                        () {
                          _restTimer?.cancel();
                          _activeRestExerciseId = null;
                        },
                      ),
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
                              onTap: () =>
                                  setState(() => _expandedExerciseId = null),
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

                                    // Handle PR celebration or normal completion
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

                                            // Trigger streak after PR popup closes if it's the first log of the day
                                            if (!_showStreakBounce) {
                                              await _triggerStreakAnimation();
                                            }

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

                                      // Trigger first log of the day streak bounce immediately
                                      if (!_showStreakBounce) {
                                        await _triggerStreakAnimation();
                                      }

                                      _triggerRestTimerForSet(exercise, sets, i,
                                          exerciseIndex, exercises);
                                    }
                                  },
                                  // onToggleDone: () async {
                                  //   final bool wasDone = setItem.isDone;

                                  //   if (wasDone) {
                                  //     setState(() {
                                  //       setItem.isDone = false;
                                  //       setItem.isPr = false;
                                  //     });
                                  //     await exercise.save();
                                  //     return;
                                  //   }

                                  //   // Trigger first log of the day streak bounce if first completion
                                  //   if (!_showStreakBounce) {
                                  //     await _triggerStreakAnimation();
                                  //   }

                                  //   final prevLogs = box.values.where((e) =>
                                  //       e.name.trim().toLowerCase() ==
                                  //           exercise.name
                                  //               .trim()
                                  //               .toLowerCase() &&
                                  //       e.id != exercise.id);

                                  //   double maxPrevWeight = 0.0;
                                  //   for (var prev in prevLogs) {
                                  //     if (prev.setsList != null &&
                                  //         prev.setsList!.isNotEmpty) {
                                  //       for (var s in prev.setsList!) {
                                  //         if (s.weight > maxPrevWeight) {
                                  //           maxPrevWeight = s.weight;
                                  //         }
                                  //       }
                                  //     } else {
                                  //       if (prev.weight > maxPrevWeight) {
                                  //         maxPrevWeight = prev.weight;
                                  //       }
                                  //     }
                                  //   }

                                  //   for (int j = 0; j < i; j++) {
                                  //     if (sets[j].weight > maxPrevWeight) {
                                  //       maxPrevWeight = sets[j].weight;
                                  //     }
                                  //   }

                                  //   final isNewPr =
                                  //       setItem.weight > maxPrevWeight &&
                                  //           maxPrevWeight > 0;

                                  //   if (isNewPr) {
                                  //     WidgetsBinding.instance
                                  //         .addPostFrameCallback((_) {
                                  //       if (mounted) {
                                  //         WorkoutActions.showPrCelebration(
                                  //             context,
                                  //             exercise.name,
                                  //             setItem.weight,
                                  //             setItem.reps, () async {
                                  //           setState(() {
                                  //             setItem.isDone = true;
                                  //             setItem.isPr = true;
                                  //           });
                                  //           await exercise.save();
                                  //           _triggerRestTimerForSet(
                                  //               exercise,
                                  //               sets,
                                  //               i,
                                  //               exerciseIndex,
                                  //               exercises);
                                  //         });
                                  //       }
                                  //     });
                                  //   } else {
                                  //     setState(() {
                                  //       setItem.isDone = true;
                                  //     });
                                  //     await exercise.save();
                                  //     _triggerRestTimerForSet(exercise, sets, i,
                                  //         exerciseIndex, exercises);
                                  //   }
                                  // },
                                  onWeightChanged: (newWeight) async {
                                    setItem.weight = newWeight;
                                    await exercise.save();
                                  },
                                  onRepsChanged: (newReps) async {
                                    setItem.reps = newReps;
                                    await exercise.save();
                                  },
                                ),
                              );
                            }),
                            const SizedBox(height: 12),
                            Center(
                              child: TextButton.icon(
                                style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFFA3E635)),
                                onPressed: () async {
                                  setState(() {
                                    final lastW = sets.isNotEmpty
                                        ? sets.last.weight
                                        : 60.0;
                                    final lastR =
                                        sets.isNotEmpty ? sets.last.reps : 10;
                                    sets.add(
                                        SetModel(weight: lastW, reps: lastR));
                                  });
                                  await exercise.save();
                                },
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Add set',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
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

// class EggClipper extends CustomClipper<Path> {
//   @override
//   Path getClip(Size size) {
//     final w = size.width;
//     final h = size.height;
//     final path = Path();

//     // Start at top center - pointed
//     path.moveTo(w * 0.5, 0);
//     // left side curve to bottom
//     path.cubicTo(w * 0.05, 0, -w * 0.05, h * 0.55, w * 0.15, h * 0.85);
//     path.cubicTo(w * 0.25, h * 0.98, w * 0.4, h, w * 0.5, h);
//     path.cubicTo(w * 0.6, h, w * 0.75, h * 0.98, w * 0.85, h * 0.85);
//     path.cubicTo(w * 1.05, h * 0.55, w * 0.95, 0, w * 0.5, 0);
//     path.close();
//     return path;
//   }

//   @override
//   bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
// }

// Replace your EggClipper with this - exact target match
class EggClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();

    // Top pointed but round
    path.moveTo(w * 0.5, 0);
    // Left side - curve out to make bottom fat
    path.cubicTo(w * 0.18, 0, 0, h * 0.38, w * 0.06, h * 0.65);
    // Left bottom bulge
    path.cubicTo(w * 0.10, h * 0.92, w * 0.32, h, w * 0.5, h);
    // Right bottom bulge - makes bottom wide like target
    path.cubicTo(w * 0.68, h, w * 0.90, h * 0.92, w * 0.94, h * 0.65);
    // Right side back to top
    path.cubicTo(w, h * 0.38, w * 0.82, 0, w * 0.5, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
