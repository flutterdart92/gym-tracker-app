// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:gym_tracker_app/features/dashboard/presentation/screens/dashboard_screen.dart';
// import 'package:gym_tracker_app/features/diet/presentation/screens/diet_screen.dart';
// import 'package:gym_tracker_app/features/profile/presentation/screens/profile_screen.dart';
// import 'package:gym_tracker_app/features/workout/presentation/screens/workout_screen.dart';
// import 'package:gym_tracker_app/features/auth/presentation/providers/auth_provider.dart';
// import '../../../../core/theme/app_colors.dart';

// class MainNavigationScreen extends StatefulWidget {
//   const MainNavigationScreen({super.key});

//   @override
//   State<MainNavigationScreen> createState() => _MainNavigationScreenState();
// }

// class _MainNavigationScreenState extends State<MainNavigationScreen> {
//   int _currentIndex = 0;

//   @override
//   void initState() {
//     super.initState();
//     // Sync providers immediately upon entering MainNavigationScreen (handles app restart & login)
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final authProvider = Provider.of<AuthProvider>(context, listen: false);
//       if (authProvider.currentUser != null) {
//         // authProvider.syncUserProviders(context, authProvider.currentUser!.id);
//         authProvider.syncUserProviders(
//             context, authProvider.currentUser!.email);
//       }
//     });
//   }

//   void _navigateToTab(int index) {
//     setState(() {
//       _currentIndex = index;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final bool isDark = Theme.of(context).brightness == Brightness.dark;

//     final List<Widget> screens = [
//       DashboardScreen(onNavigateToTab: _navigateToTab), // 0: Home
//       const DietScreen(), // 1: Diet
//       const WorkoutScreen(), // 2: Train
//       const Center(child: Text('Progress Screen')), // 3: Progress
//       const ProfileScreen(), // 4: Me
//     ];

//     return Scaffold(
//       body: IndexedStack(
//         index: _currentIndex,
//         children: screens,
//       ),
//       bottomNavigationBar: Container(
//         decoration: BoxDecoration(
//           color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
//           border: Border(
//             top: BorderSide(
//               color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
//               width: 1.0,
//             ),
//           ),
//         ),
//         child: BottomNavigationBar(
//           currentIndex: _currentIndex > 4 ? 0 : _currentIndex,
//           onTap: (index) {
//             if (index == 3) {
//               _navigateToTab(3);
//             } else if (index == 4) {
//               _navigateToTab(4);
//             } else {
//               _navigateToTab(index);
//             }
//           },
//           type: BottomNavigationBarType.fixed,
//           backgroundColor: Colors.transparent,
//           elevation: 0,
//           selectedItemColor: AppColors.indigoPrimary,
//           unselectedItemColor:
//               isDark ? Colors.grey.shade500 : Colors.grey.shade400,
//           selectedLabelStyle: const TextStyle(
//             fontWeight: FontWeight.bold,
//             fontSize: 13,
//           ),
//           unselectedLabelStyle: const TextStyle(
//             fontWeight: FontWeight.normal,
//             fontSize: 12,
//           ),
//           showUnselectedLabels: true,
//           items: const [
//             BottomNavigationBarItem(
//               icon: SizedBox.shrink(),
//               label: 'Home',
//             ),
//             BottomNavigationBarItem(
//               icon: SizedBox.shrink(),
//               label: 'Diet',
//             ),
//             BottomNavigationBarItem(
//               icon: SizedBox.shrink(),
//               label: 'Train',
//             ),
//             BottomNavigationBarItem(
//               icon: SizedBox.shrink(),
//               label: 'Progress',
//             ),
//             BottomNavigationBarItem(
//               icon: SizedBox.shrink(),
//               label: 'Me',
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:gym_tracker_app/features/progress/progress_screen.dart';
import 'package:provider/provider.dart';
import 'package:animations/animations.dart';
import 'package:gym_tracker_app/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:gym_tracker_app/features/diet/presentation/screens/diet_screen.dart';
import 'package:gym_tracker_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:gym_tracker_app/features/workout/presentation/screens/workout_screen.dart';
import 'package:gym_tracker_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:gym_tracker_app/core/animations/app_animations.dart';
import '../../../../core/theme/app_colors.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Sync providers immediately upon entering MainNavigationScreen (handles app restart & login)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.currentUser != null) {
        authProvider.syncUserProviders(
            context, authProvider.currentUser!.email);
      }
    });
  }

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool reduceMotion = AppAnimations.shouldReduceMotion(context);

    final List<Widget> screens = [
      DashboardScreen(onNavigateToTab: _navigateToTab), // 0: Home
      const DietScreen(), // 1: Diet
      const WorkoutScreen(), // 2: Train
      // const Center(child: Text('Progress Screen')),
      const prgoressscreen(), // 3: Progress
      //// 3: Progress
      const ProfileScreen(), // 4: Me
    ];

    return Scaffold(
      body: PageTransitionSwitcher(
        duration: reduceMotion ? Duration.zero : AppAnimations.tabTransition,
        transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
          if (reduceMotion) return child;
          return FadeThroughTransition(
            animation: primaryAnimation,
            secondaryAnimation: secondaryAnimation,
            child: child,
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              width: 1.0,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex > 4 ? 0 : _currentIndex,
          onTap: (index) {
            if (index == 3) {
              _navigateToTab(3);
            } else if (index == 4) {
              _navigateToTab(4);
            } else {
              _navigateToTab(index);
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppColors.indigoPrimary,
          unselectedItemColor:
              isDark ? Colors.grey.shade500 : Colors.grey.shade400,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 12,
          ),
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: SizedBox.shrink(),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: SizedBox.shrink(),
              label: 'Diet',
            ),
            BottomNavigationBarItem(
              icon: SizedBox.shrink(),
              label: 'Train',
            ),
            BottomNavigationBarItem(
              icon: SizedBox.shrink(),
              label: 'Progress',
            ),
            BottomNavigationBarItem(
              icon: SizedBox.shrink(),
              label: 'Me',
            ),
          ],
        ),
      ),
    );
  }
}
