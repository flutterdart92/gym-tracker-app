import 'package:flutter/material.dart';
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
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
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
                        style: TextStyle(
                            color: isDark
                                ? Colors.grey.shade400
                                : AppColors.textMuted,
                            fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_getGreeting()}, $userName',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => _navigateToTab(3),
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
              const SizedBox(height: 20),

              // 2. Weekly Strip
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

                  return Column(
                    children: [
                      Text(day,
                          style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : AppColors.textMuted)),
                      const SizedBox(height: 6),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone
                              ? AppColors.limeAccent
                              : Colors.transparent,
                          border: Border.all(
                            color: isDone
                                ? AppColors.limeAccent
                                : (isDark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300),
                            width: 2,
                          ),
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
              const SizedBox(height: 16),

              // 4. Macro Progress Bars
              _macroBar('Protein', eatenProtein, targetProtein,
                  AppColors.proteinIndigo, isDark),
              const SizedBox(height: 10),
              _macroBar('Carbs', eatenCarbs, targetCarbs, AppColors.carbsAmber,
                  isDark),
              const SizedBox(height: 10),
              _macroBar(
                  'Fats', eatenFats, targetFats, AppColors.fatsPink, isDark),
              const SizedBox(height: 20),

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
                                fontSize: 10,
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
                              fontSize: 16,
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
                      ),
                      onPressed: () => _navigateToTab(2),
                      child: const Text('Start',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
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
        color: isDark ? const Color(0xFF1E1E1E) : AppColors.lightCardBg,
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
                  fontSize: 12)),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textDark)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: TextStyle(
                  fontSize: 11, color: subColor, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
