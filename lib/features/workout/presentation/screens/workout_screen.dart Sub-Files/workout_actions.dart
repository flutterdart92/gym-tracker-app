import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gym_tracker_app/features/auth/data/models/set_model.dart';
import 'package:gym_tracker_app/features/workout/data/models/exercise_model.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:gym_tracker_app/core/theme/app_colors.dart';
import 'package:gym_tracker_app/core/services/hive_service.dart';

class WorkoutActions {
  static void showPrCelebration(
    BuildContext context,
    String exerciseName,
    double weight,
    int reps,
    VoidCallback onDismiss,
  ) {
    HapticFeedback.mediumImpact();

    final double est1RM = weight * (1 + (reps / 30.0));
    final int roundedE1RM = est1RM.round();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final ConfettiController confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    confettiController.play();

    showDialog(
      context: context,
      barrierDismissible: true,
      // barrierColor: Colors.white,
      barrierColor: isDark ? const Color(0xFF0D1117) : Colors.white,
      builder: (ctx) {
        // Future.delayed(const Duration(milliseconds: 1500), () {
        Future.delayed(const Duration(seconds: 5), () {
          if (ctx.mounted) {
            Navigator.of(ctx, rootNavigator: true).pop();
          }
        });

        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              // color: Colors.white,
              color: isDark ? const Color(0xFF0D1117) : Colors.white,
            ),
            AlertDialog(
              // backgroundColor: Colors.transparent,
              // backgroundColor: Colors.white,
              backgroundColor:
                  // isDark ? const Color(0xFF0D1117) : Colors.grey[100],
                  isDark ? const Color(0xFF0D1117) : Colors.white,

              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 250,
                    // width: MediaQuery.of(context).size.width,
                    height: 250,
                    // height: MediaQuery.of(context).size.height,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color.fromARGB(255, 255, 230, 0)
                                .withValues(alpha: 0.3),
                          ),
                        )
                            .animate(
                                onPlay: (controller) =>
                                    controller.repeat(reverse: true))
                            .scale(
                              begin: const Offset(0.9, 0.9),
                              end: const Offset(1.0, 1.0),
                              duration: const Duration(seconds: 1),
                              curve: Curves.easeInOutSine,
                            )
                            .fadeIn(
                              begin: 0.4,
                              duration: const Duration(seconds: 1),
                            ),
                        Container(
                          width: 100,
                          height: 100,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFFFACC15), Color(0xFFCA8A04)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'PR',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ).animate().shimmer(
                              duration: const Duration(milliseconds: 1200),
                              color: Colors.white,
                            ),
                      ],
                    ),
                  ),
                  // const SizedBox(height: 10),
                  // Padding(
                  // padding: const EdgeInsets.only(bottom: 100.0),
                  // child:
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    // crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'New PR!',
                        style: TextStyle(
                          // color: Colors.grey.shade400,
                          color:
                              isDark ? Colors.white : const Color(0xFF0D1117),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '$exerciseName • ${weight.toString().replaceAll(RegExp(r'\.0$'), '')}kg × $reps',
                        style: TextStyle(
                          // color: Colors.grey.shade400,
                          color:
                              isDark ? Colors.white : const Color(0xFF0D1117),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  // ),
                  // const SizedBox(height: 6),
                  // Text(
                  //   'Est. 1RM $roundedE1RM kg',
                  //   style: const TextStyle(
                  //     color: Color(0xFFFACC15),
                  //     fontSize: 14,
                  //     fontWeight: FontWeight.w600,
                  //   ),
                  // ),
                  // const SizedBox(height: 16),
                  // const Text(
                  //   'Awesome!',
                  //   style: TextStyle(
                  //     color: Color(0xFFA3E635),
                  //     fontSize: 16,
                  //     fontWeight: FontWeight.bold,
                  //   ),
                  // ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 30.0),
              child: ConfettiWidget(
                confettiController: confettiController,
                blastDirection: -1.57,
                // blastDirection: -2.57,

                // emissionFrequency: 0.05,
                emissionFrequency: 0.25,

                numberOfParticles: 30,
                maxBlastForce: 30,
                minBlastForce: 10,
                shouldLoop: false,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple,
                  AppColors.limeAccent,
                  Color(0xFFFACC15),
                ],
              ),
            ),
          ],
        );
      },
    ).then((_) {
      confettiController.dispose();
      onDismiss();
    });
  }

  static void deleteExercise(
    BuildContext context,
    ExerciseModel exercise,
    String? activeRestExerciseId,
    VoidCallback onCancelTimer,
  ) async {
    final deletedExercise = exercise;
    final messenger = ScaffoldMessenger.of(context);
    if (activeRestExerciseId == exercise.id) {
      onCancelTimer();
    }
    await exercise.delete();

    if (!context.mounted) return;

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        backgroundColor: AppColors.darkBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Expanded(
              child: Text(
                '${deletedExercise.name} deleted',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                final box =
                    Hive.box<ExerciseModel>(HiveService.exerciseBoxName);
                await box.put(deletedExercise.id, deletedExercise);
                messenger.hideCurrentSnackBar();
              },
              child: const Text(
                'UNDO',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 187, 250, 94),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void deleteSetWithUndo(
    BuildContext context,
    ExerciseModel exercise,
    List<SetModel> sets,
    int index,
    VoidCallback onStateUpdated,
  ) async {
    final removedSet = sets[index];
    final messenger = ScaffoldMessenger.of(context);

    sets.removeAt(index);
    await exercise.save();
    onStateUpdated();

    if (!context.mounted) return;

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        backgroundColor: AppColors.darkBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Expanded(
              child: Text(
                'Set deleted',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                sets.insert(index, removedSet);
                await exercise.save();
                onStateUpdated();
                messenger.hideCurrentSnackBar();
              },
              child: const Text(
                'UNDO',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 187, 250, 94),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void finishWorkoutSession(
    BuildContext context,
    Duration elapsedDuration,
    String Function(Duration) formatDuration,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: const Text('Finish Workout?',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Duration: ${formatDuration(elapsedDuration)}\nGreat session! Save and exit to dashboard?',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continue Workout'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA3E635)),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Finish & Save',
                style: TextStyle(color: Colors.black)),
          ),
        ],
      )
          .animate(onPlay: (c) => c.repeat())
          .shimmer(duration: const Duration(seconds: 2)),
    );
  }
}
