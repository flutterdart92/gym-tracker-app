// ignore_for_file: unnecessary_null_comparison

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:gym_tracker_app/core/theme/app_colors.dart';
import 'package:gym_tracker_app/core/services/hive_service.dart';
import 'package:gym_tracker_app/core/animations/app_animations.dart';
import 'package:gym_tracker_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:gym_tracker_app/features/diet/presentation/providers/diet_provider.dart';
import 'package:gym_tracker_app/features/workout/presentation/providers/workout_provider.dart';
import 'package:gym_tracker_app/features/auth/presentation/providers/auth_provider.dart';

import '../widgets/calorie_ring_widget.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int)? onTabSwitch;
  final Function(int)? onNavigateToTab;

  const DashboardScreen({
    super.key,
    this.onTabSwitch,
    this.onNavigateToTab,
  });

  void _navigateToTab(int index) {
    if (onNavigateToTab != null) {
      onNavigateToTab!(index);
    } else if (onTabSwitch != null) {
      onTabSwitch!(index);
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good morning';
    if (hour >= 12 && hour < 17) return 'Good afternoon';
    if (hour >= 17 && hour < 21) return 'Good evening';
    return 'Good night';
  }

  void _recordTodayLogin(String userId) {
    if (userId.isEmpty) return;
    try {
      if (Hive.isBoxOpen(HiveService.streakBoxName)) {
        final box = Hive.box(HiveService.streakBoxName);
        final key = 'login_dates_$userId';
        final streakKey = 'current_streak_$userId';
        final lastDateKey = 'last_login_date_$userId';

        List<dynamic> rawDates = box.get(key, defaultValue: <String>[]);
        List<String> loginDates = rawDates.map((e) => e.toString()).toList();

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final todayStr =
            '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

        if (loginDates.contains(todayStr)) return;

        String? lastLoginStr = box.get(lastDateKey);
        if (lastLoginStr == null) {
          loginDates = [todayStr];
          box.put(key, loginDates);
          box.put(lastDateKey, todayStr);
          box.put(streakKey, 1);
        } else {
          final lastLoginDate = DateTime.parse(lastLoginStr);
          final lastLoginDay = DateTime(
              lastLoginDate.year, lastLoginDate.month, lastLoginDate.day);
          final diffDays = today.difference(lastLoginDay).inDays;

          if (diffDays == 0) {
          } else if (diffDays == 1) {
            loginDates.add(todayStr);
            box.put(key, loginDates);
            box.put(lastDateKey, todayStr);
            int currentStreak = box.get(streakKey, defaultValue: 1);
            box.put(streakKey, currentStreak + 1);
          } else {
            loginDates = [todayStr];
            box.put(key, loginDates);
            box.put(lastDateKey, todayStr);
            box.put(streakKey, 1);
          }
        }
      }
    } catch (_) {}
  }

  int _getCurrentStreak(String userId) {
    if (userId.isEmpty) return 0;
    try {
      if (Hive.isBoxOpen(HiveService.streakBoxName)) {
        final box = Hive.box(HiveService.streakBoxName);
        return box.get('current_streak_$userId', defaultValue: 0);
      }
    } catch (_) {}
    return 0;
  }

  Set<int> _getLoginDayIndices(String userId) {
    if (userId.isEmpty) return {};
    try {
      if (!Hive.isBoxOpen(HiveService.streakBoxName)) return {};

      final box = Hive.box(HiveService.streakBoxName);
      final key = 'login_dates_$userId';
      List<dynamic> rawDates = box.get(key, defaultValue: <String>[]);
      List<String> loginDates = rawDates.map((e) => e.toString()).toList();

      final now = DateTime.now();
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final startOfWeek = DateTime(monday.year, monday.month, monday.day);

      Set<int> indices = {};
      for (String dateStr in loginDates) {
        try {
          final parts = dateStr.split('-');
          final date = DateTime(
              int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
          if (!date.isBefore(startOfWeek) &&
              date.isBefore(startOfWeek.add(const Duration(days: 7)))) {
            indices.add(date.weekday - 1);
          }
        } catch (_) {}
      }
      return indices;
    } catch (_) {
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final dietProvider = context.watch<DietProvider>();
    final workoutProvider = context.watch<WorkoutProvider>();
    final authProvider = context.watch<AuthProvider>();

    final currentUserId = authProvider.currentUser?.email ?? '';
    _recordTodayLogin(currentUserId);
    final loginIndices = _getLoginDayIndices(currentUserId);
    final currentStreak = _getCurrentStreak(currentUserId);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool reduceMotion = AppAnimations.shouldReduceMotion(context);

    final userName = authProvider.currentUser?.name ?? 'User';
    final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

    final double targetKcal = profileProvider.targetCalories > 0
        ? profileProvider.targetCalories.toDouble()
        : 2200.0;
    final double targetProtein = profileProvider.targetProtein > 0
        ? profileProvider.targetProtein.toDouble()
        : 150.0;
    final double targetCarbs = profileProvider.targetCarbs > 0
        ? profileProvider.targetCarbs.toDouble()
        : 200.0;
    final double targetFats = profileProvider.targetFats > 0
        ? profileProvider.targetFats.toDouble()
        : 65.0;

    final double eatenKcal = dietProvider.totalCaloriesToday.toDouble();
    final double eatenProtein = dietProvider.totalProteinToday;
    final double eatenCarbs = dietProvider.totalCarbsToday;
    final double eatenFats = dietProvider.totalFatsToday;
    final double burnedKcal = workoutProvider.todayCaloriesBurned.toDouble();

    final int kcalLeft =
        (targetKcal - eatenKcal + burnedKcal).round().clamp(0, 99999);
    final double volumeTodayKg = workoutProvider.todayTotalVolume;
    final String nextWorkoutTitle = workoutProvider.nextWorkoutName;
    final int nextWorkoutExerciseCount =
        workoutProvider.nextWorkoutExerciseCount;

    final now = DateTime.now();
    final int todayIdx = now.weekday - 1;

    // Phase 1: Staggered animation wrapper helper (40ms apart)
    Widget staggerCard(Widget child, int index, {Duration? staggerDuration}) {
      if (reduceMotion) return child;
      const defaultDelay = AppAnimations.staggerDelay;
      final stepDelay = staggerDuration ?? defaultDelay;
      final delayMs = index * AppAnimations.staggerDelay.inMilliseconds;
      return child
          .animate()
          .fadeIn(
            // duration: const Duration(milliseconds: 1000),
            duration: const Duration(milliseconds: 3000),

            // duration: const Duration(seconds: 2),

            // delay: Duration(milliseconds: delayMs),
            delay: Duration(milliseconds: stepDelay.inMilliseconds * index),

            // staggerDuration: const Duration(milliseconds: 80),
            // delay: Duration(seconds: delayMs),

            curve: AppAnimations.easeOutCubic,
          )
          .slideY(
            begin: 0.1,
            end: 0.0,
            // duration: const Duration(milliseconds: 1000),
            duration: const Duration(milliseconds: 5000),

            // duration: const Duration(seconds: 2),
            // delay: Duration(milliseconds: delayMs),
            delay: Duration(milliseconds: stepDelay.inMilliseconds * index),
            // delay: Duration(seconds: delayMs),
            curve: AppAnimations.easeOutCubic,
          );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header (Stagger Index 0)
              staggerCard(
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatTodayHeaderDate(),
                          style: GoogleFonts.outfit(
                            textStyle: TextStyle(
                              color: isDark
                                  ? Colors.grey.shade400
                                  : AppColors.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_getGreeting()}, $userName',
                          style: GoogleFonts.outfit(
                            textStyle: TextStyle(
                              color: isDark ? Colors.white : AppColors.textDark,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => _navigateToTab(4),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.indigoPrimary,
                        child: Text(
                          userInitial,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                0,
              ),
              const SizedBox(height: 20),

              // 2. Weekly Strip (Stagger Index 1)
              staggerCard(
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                      .asMap()
                      .entries
                      .map((entry) {
                    final idx = entry.key;
                    final day = entry.value;

                    final bool isLoggedIn = loginIndices.contains(idx);
                    final bool hasWorkout =
                        workoutProvider.loggedDayIndices.contains(idx);
                    final bool hasDiet =
                        dietProvider.loggedMealDayIndices.contains(idx);
                    // final bool isDone = isLoggedIn || hasWorkout || hasDiet;
                    // Weekly strip completion logic aligned with active streak/login dates
                    final bool isDone =
                        isLoggedIn; // or tied strictly to valid streak login dates
                    final bool isActiveDay = idx == todayIdx;

                    final dayWidget = Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone
                            ? const Color(0xFFA3E635)
                            : Colors.transparent,
                        border: Border.all(
                          color: isDone
                              ? const Color(0xFFA3E635)
                              : (isDark
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade300),
                          width: 2,
                        ),
                      ),
                    );

                    return Column(
                      children: [
                        Text(
                          day,
                          style: GoogleFonts.outfit(
                            textStyle: TextStyle(
                              color: isActiveDay
                                  ? const Color(0xFFA3E635)
                                  : (isDark
                                      ? Colors.grey.shade400
                                      : AppColors.textMuted),
                              fontSize: 10,
                              fontWeight: isActiveDay
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (isActiveDay && !reduceMotion)
                                Container(
                                  width: 45,
                                  height: 45,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        const Color.fromARGB(255, 149, 243, 8)
                                            .withValues(alpha: 0.3),
                                  ),
                                )
                                    .animate(
                                        onPlay: (c) => c.repeat(reverse: true))
                                    .scale(
                                      begin: const Offset(0.9, 0.9),
                                      end: const Offset(1.0, 1.0),
                                      duration:
                                          const Duration(milliseconds: 1000),
                                      curve: Curves.easeInOutSine,
                                    ),
                              Center(child: dayWidget),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
                1,
                staggerDuration: const Duration(milliseconds: 80),
              ),
              const SizedBox(height: 20),

              // 3. Dark Hero Calorie Ring Card (Stagger Index 2)
              staggerCard(
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E1E1E)
                        : AppColors.darkBackground,
                    borderRadius: AppColors.cardRadius,
                    border:
                        isDark ? Border.all(color: Colors.grey.shade800) : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(
                          begin: 0,
                          end: targetKcal > 0
                              ? (eatenKcal / targetKcal).clamp(0.0, 1.0)
                              : 0.0,
                        ),
                        duration: AppAnimations.countUp,
                        curve: AppAnimations.easeOutCubic,
                        builder: (_, progressVal, __) => CalorieRing(
                          progress: progressVal,
                          left: kcalLeft,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        // children: [
                        // _statLabel('Eaten', '${eatenKcal.round()}'),
                        // const SizedBox(height: 12),
                        // _statLabel('Target', '${targetKcal.round()}'),
                        // const SizedBox(height: 12),
                        // _statLabel('Burned', '${burnedKcal.round()}'),
                        // updated :
                        //   _statLabel('Eaten', eatenKcal.round()),
                        //   const SizedBox(height: 12),

                        //   _statLabel('Target', targetKcal.round()),

                        //   const SizedBox(height: 12),
                        //   _statLabel('Burned', burnedKcal.round()),
                        // ],
                        // updated with target editable
                        children: [
                          _statLabel('Eaten', eatenKcal.round(),
                              isEditable: false, context: context),
                          const SizedBox(height: 12),
                          _statLabel(
                            'Target',
                            targetKcal.round(),
                            isEditable: true,
                            context: context,
                            onChanged: (newTarget) {
                              profileProvider.updateTargetCalories(newTarget);
                            },
                          ),
                          const SizedBox(height: 12),
                          _statLabel('Burned', burnedKcal.round(),
                              isEditable: false, context: context),
                        ],
                      ),
                    ],
                  ),
                ),
                2,
                staggerDuration: const Duration(milliseconds: 160),
              ),
              const SizedBox(height: 10),

              // 4. Macro Bars Card (Stagger Index 3)
              staggerCard(
                SizedBox(
                  width: double.infinity,
                  child: Card(
                    color: isDark ? const Color(0xFF0D1117) : Colors.white,
                    elevation: 0,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _macroBar('Protein', eatenProtein, targetProtein,
                              AppColors.proteinIndigo, isDark),
                          const SizedBox(height: 10),
                          _macroBar('Carbs', eatenCarbs, targetCarbs,
                              AppColors.carbsAmber, isDark),
                          const SizedBox(height: 10),
                          _macroBar('Fats', eatenFats, targetFats,
                              AppColors.fatsPink, isDark),
                        ],
                      ),
                    ),
                  ),
                ),
                3,
                staggerDuration: const Duration(milliseconds: 240),
              ),
              const SizedBox(height: 16),

              // 5. 2x2 KPI Grid Row 1 (Stagger Index 4)
              staggerCard(
                Row(
                  children: [
                    Expanded(
                      child: _kpiTile(
                        'Volume today',
                        '${_formatVolume(volumeTodayKg)} kg',
                        'Calculated from logs',
                        Colors.green,
                        isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _kpiTile(
                        'This week',
                        '${workoutProvider.weeklyWorkoutsDone} / ${workoutProvider.weeklyWorkoutGoal}',
                        'workouts',
                        isDark ? Colors.grey.shade400 : AppColors.textMuted,
                        isDark,
                      ),
                    ),
                  ],
                ),
                4,
                staggerDuration: const Duration(milliseconds: 320),
              ),
              const SizedBox(height: 12),

              // 6. 2x2 KPI Grid Row 2 (Stagger Index 5)
              staggerCard(
                Row(
                  children: [
                    Expanded(
                      child: _kpiTile(
                        'Streak',
                        '$currentStreak days',
                        'best: $currentStreak',
                        AppColors.limeAccent,
                        isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _kpiTile(
                        'Water',
                        '${(dietProvider.waterGlasses * 0.25).toStringAsFixed(1)} / 3 L',
                        '${dietProvider.waterGlasses} glasses',
                        isDark ? Colors.grey.shade400 : AppColors.textMuted,
                        isDark,
                      ),
                    ),
                  ],
                ),
                5,
                staggerDuration: const Duration(milliseconds: 400),
              ),
              const SizedBox(height: 20),

              // 7. Actionable Next Workout Banner (Stagger Index 6)
              staggerCard(
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: AppColors.indigoPrimary,
                    borderRadius: AppColors.cardRadius,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'NEXT WORKOUT',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 8,
                                  letterSpacing: 1),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$nextWorkoutTitle • $nextWorkoutExerciseCount exercises',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.indigoPrimary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          fixedSize: const Size(70, 30),
                        ),
                        onPressed: () => _navigateToTab(2),
                        child: const Text('Start',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 9)),
                      ),
                    ],
                  ),
                ),
                6,
                staggerDuration: const Duration(milliseconds: 480),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatTodayHeaderDate() {
    final now = DateTime.now();
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  static String _formatVolume(double volume) {
    if (volume >= 1000) {
      return volume.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
          );
    }
    return volume.toStringAsFixed(0);
  }

  // static Widget _statLabel(String title, String val) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
  //       Text(val,
  //           style: const TextStyle(
  //               color: Colors.white,
  //               fontSize: 18,
  //               fontWeight: FontWeight.bold)),
  //     ],
  //   );
  // }

  // static Widget _macroBar(
  //     String label, double current, double max, Color color, bool isDark) {
  //   final double safeMax = max > 0 ? max : 1.0;
  //   return Column(
  //     children: [
  //       Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //         children: [
  //           Text(label,
  //               style: TextStyle(
  //                   fontWeight: FontWeight.w600,
  //                   fontSize: 13,
  //                   color: isDark ? Colors.white70 : Colors.black87)),
  //           Text(
  //             '${current.round()} / ${safeMax.round()} g',
  //             style: TextStyle(
  //                 fontWeight: FontWeight.bold,
  //                 fontSize: 13,
  //                 color: isDark ? Colors.white : Colors.black87),
  //           ),
  //         ],
  //       ),
  //       const SizedBox(height: 6),
  //       ClipRRect(
  //         borderRadius: BorderRadius.circular(4),
  //         child: LinearProgressIndicator(
  //           value: (current / safeMax).clamp(0.0, 1.0),
  //           color: color,
  //           backgroundColor:
  //               isDark ? Colors.grey.shade800 : Colors.grey.shade200,
  //           minHeight: 8,
  //         ),
  //       ),
  //     ],
  //   );
  // }

//updated  :
  // static Widget _statLabel(String title, int targetVal) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
  //       TweenAnimationBuilder<int>(
  //         tween: IntTween(begin: 0, end: targetVal),
  //         duration: const Duration(milliseconds: 5000),
  //         curve: Curves.easeOutCubic,
  //         builder: (context, value, child) {
  //           return Text(
  //             '$value',
  //             style: const TextStyle(
  //               color: Colors.white,
  //               fontSize: 18,
  //               fontWeight: FontWeight.bold,
  //             ),
  //           );
  //         },
  //       ),
  //     ],
  //   );
  // }

  // static Widget _statLabel(
  //   String title,
  //   int targetVal, {
  //   required bool isEditable,
  //   required BuildContext context,
  //   Function(int)? onChanged,
  // }) {
  //   return GestureDetector(
  //     onTap: isEditable
  //         ? () {
  //             final TextEditingController controller =
  //                 TextEditingController(text: '$targetVal');
  //             showDialog(
  //               context: context,
  //               builder: (dialogContext) {
  //                 return AlertDialog(
  //                   title: Text('Edit $title Calories'),
  //                   content: TextField(
  //                     controller: controller,
  //                     keyboardType: TextInputType.number,
  //                     autofocus: true,
  //                     decoration: const InputDecoration(
  //                       labelText: 'Target Calories (kcal)',
  //                       border: OutlineInputBorder(),
  //                     ),
  //                   ),
  //                   actions: [
  //                     TextButton(
  //                       onPressed: () => Navigator.pop(dialogContext),
  //                       child: const Text('Cancel'),
  //                     ),
  //                     ElevatedButton(
  //                       onPressed: () {
  //                         final parsed = int.tryParse(controller.text);
  //                         if (parsed != null && parsed > 0) {
  //                           if (onChanged != null) onChanged(parsed);
  //                         }
  //                         Navigator.pop(dialogContext);
  //                       },
  //                       child: const Text('Save'),
  //                     ),
  //                   ],
  //                 );
  //               },
  //             );
  //           }
  //         : null,
  //     child: Container(
  //       color: Colors.transparent, // Ensures easy touch target
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Row(
  //             children: [
  //               Text(title,
  //                   style: const TextStyle(color: Colors.grey, fontSize: 12)),
  //               if (isEditable) ...[
  //                 const SizedBox(width: 4),
  //                 const Icon(Icons.edit, size: 10, color: Colors.grey),
  //               ],
  //             ],
  //           ),
  //           TweenAnimationBuilder<int>(
  //             tween: IntTween(begin: 0, end: targetVal),
  //             duration: const Duration(milliseconds: 5000),
  //             curve: Curves.easeOutCubic,
  //             builder: (context, value, child) {
  //               return Text(
  //                 '$value',
  //                 style: const TextStyle(
  //                   color: Colors.white,
  //                   fontSize: 18,
  //                   fontWeight: FontWeight.bold,
  //                 ),
  //               );
  //             },
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // updte 2 with pencil icon hide from target in calorie ring card

  static Widget _statLabel(
    String title,
    int targetVal, {
    required bool isEditable,
    required BuildContext context,
    Function(int)? onChanged,
  }) {
    return GestureDetector(
      onTap: isEditable
          ? () {
              final TextEditingController controller =
                  TextEditingController(text: '$targetVal');
              showDialog(
                context: context,
                builder: (dialogContext) {
                  return AlertDialog(
                    title: Text('Edit $title Calories'),
                    content: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Target Calories (kcal)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final parsed = int.tryParse(controller.text);
                          if (parsed != null && parsed > 0) {
                            if (onChanged != null) onChanged(parsed);
                          }
                          Navigator.pop(dialogContext);
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  );
                },
              );
            }
          : null,
      child: Container(
        color: Colors.transparent, // Ensures easy touch target
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pencil icon removed completely here
            Text(title,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: targetVal),
              duration: const Duration(milliseconds: 5000),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Text(
                  '$value',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static Widget _macroBar(
      String label, double current, double max, Color color, bool isDark) {
    final double safeMax = max > 0 ? max : 1.0;
    final double targetRatio = (current / safeMax).clamp(0.0, 1.0);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black87)),
            Text(
              '${current.round()} / ${safeMax.round()} g',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isDark ? Colors.white : Colors.black87),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 1.0, end: targetRatio),
          duration: const Duration(milliseconds: 5000),
          curve: Curves.easeOutCubic,
          builder: (context, progressVal, child) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progressVal,
                color: color,
                backgroundColor:
                    isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                minHeight: 8,
              ),
            );
          },
        ),
      ],
    );
  }

  static Widget _kpiTile(String title, String value, String subtitle,
      Color subColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E1E1E)
            : const Color.fromARGB(255, 255, 255, 255),
        borderRadius: AppColors.cardRadius,
        border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : AppColors.textMuted,
                  fontSize: 10)),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textDark)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: TextStyle(
                  fontSize: 9, color: subColor, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
