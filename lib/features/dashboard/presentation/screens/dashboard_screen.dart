import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:gym_tracker_app/core/theme/app_colors.dart';
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

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final dietProvider = context.watch<DietProvider>();
    final workoutProvider = context.watch<WorkoutProvider>();
    final authProvider = context.watch<AuthProvider>();

    // Detect dark mode brightness
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final userName = authProvider.currentUser?.name ?? 'Test1';
    final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'T';

    final double targetKcal = profileProvider.targetCalories > 0
        ? profileProvider.targetCalories.toDouble()
        : 2000.0;
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
    final int todayIdx = now.weekday - 1; // Mon = 0, Tue = 1, Wed = 2...

    return Scaffold(
      // backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      backgroundColor: isDark ? const Color(0xFF0D1117) : Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header (Date + Dynamic Greeting + Avatar)
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
                          // fontWeight: FontWeight.bold,
                        )),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_getGreeting()}, $userName',
                        style: GoogleFonts.outfit(
                            textStyle: TextStyle(
                          color: isDark ? Colors.white : AppColors.textDark,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        )),
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
                    )
                        .animate(onPlay: (c) => c.repeat())
                        .shimmer(duration: const Duration(seconds: 2)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. Weekly Strip with Pulsing Organic Aura behind Active Day
              // 2. Weekly Strip with Pulsing Organic Aura Effect for Active Day
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                    .asMap()
                    .entries
                    .map((entry) {
                  final idx = entry.key;
                  final day = entry.value;

                  final bool isPastOrToday = idx <= todayIdx;
                  final bool hasWorkout =
                      workoutProvider.loggedDayIndices.contains(idx);
                  final bool hasDiet =
                      (idx == todayIdx && dietProvider.todayMeals.isNotEmpty);
                  final isDone = isPastOrToday || hasWorkout || hasDiet;
                  final bool isActiveDay =
                      idx == todayIdx; // Current day highlight

                  final dayWidget = Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone
                          // ? AppColors.limeAccent
                          ? const Color(0xFFA3E635)
                          : Colors.transparent,
                      border: Border.all(
                        color: isDone
                            // ? AppColors.limeAccent
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
                                // ? AppColors.limeAccent
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
                        // width: 44,
                        // height: 44,
                        width: 32,
                        height: 32,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Organic pulsing aura behind active day
                            if (isActiveDay)
                              Container(
                                width: 45,
                                height: 45,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color.fromARGB(255, 149, 243, 8)
                                      .withValues(alpha: 0.3),
                                ),
                              )
                                  .animate(
                                      onPlay: (controller) =>
                                          controller.repeat(reverse: true))
                                  .scale(
                                    begin: const Offset(0.9, 0.9),
                                    end: const Offset(1.0, 1.0),
                                    duration:
                                        const Duration(milliseconds: 1000),
                                    curve: Curves.easeInOutSine,
                                  )
                                  .fadeIn(
                                    begin: 0.4,
                                    duration:
                                        const Duration(milliseconds: 1000),
                                  ),
                            // The actual Day Circle
                            Center(child: dayWidget),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // 3. Dark Hero Card
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
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (_, progressVal, __) => CalorieRing(
                        progress: progressVal,
                        left: kcalLeft,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _statLabel('Eaten', '${eatenKcal.round()}'),
                        const SizedBox(height: 12),
                        _statLabel('Target', '${targetKcal.round()}'),
                        const SizedBox(height: 12),
                        _statLabel('Burned', '${burnedKcal.round()}'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              SizedBox(
                width: double.infinity, // full width
                // height: 220, // <-- uncomment if you want FIXED height
                child: Card(
                  color: isDark ? const Color(0xFF0D1117) : Colors.white,
                  elevation: 0,
                  margin: const EdgeInsets.symmetric(
                      horizontal: 0,
                      vertical:
                          8), // <-- controls width: less horizontal = wider card
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16)), // uncomment this
                  child: Padding(
                    padding: const EdgeInsets.all(
                        20), // <-- bigger number = taller/wider card. You have only top/left/right 16
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

              const SizedBox(height: 16),

              // 5. 2x2 KPI Grid Tiles
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _kpiTile(
                      'Streak',
                      '${workoutProvider.currentStreak} days',
                      'best: ${workoutProvider.bestStreak}',
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
              const SizedBox(height: 20),

              // 6. Actionable Next Workout Banner
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
                    )..animate(onPlay: (c) => c.repeat())
                        .shimmer(duration: const Duration(seconds: 2)),
                  ],
                ),
              )..animate(onPlay: (c) => c.repeat())
                  .shimmer(duration: const Duration(seconds: 2)),
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

  static Widget _statLabel(String title, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(val,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  static Widget _macroBar(
      String label, double current, double max, Color color, bool isDark) {
    final double safeMax = max > 0 ? max : 1.0;
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
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (current / safeMax).clamp(0.0, 1.0),
            color: color,
            backgroundColor:
                isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            minHeight: 8,
          ),
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
