// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'core/services/hive_service.dart';
// import 'features/auth/presentation/providers/auth_provider.dart';
// import 'features/auth/presentation/screens/auth_screen.dart';
// import 'features/dashboard/presentation/pages/main_navigation_screen.dart';
// import 'features/diet/presentation/providers/diet_provider.dart';
// import 'features/workout/presentation/providers/workout_provider.dart';
// import 'features/profile/presentation/providers/profile_provider.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await HiveService.init();
//   runApp(const GymTrackerApp());
// }

// class GymTrackerApp extends StatelessWidget {
//   const GymTrackerApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => AuthProvider()),
//         ChangeNotifierProvider(create: (_) => WorkoutProvider()),
//         ChangeNotifierProvider(create: (_) => DietProvider()),
//         ChangeNotifierProvider(create: (_) => ProfileProvider()),
//       ],
//       child: Consumer<ProfileProvider>(
//         builder: (context, profileProvider, _) {
//           return MaterialApp(
//             title: 'Gym Tracker',
//             debugShowCheckedModeBanner: false,
//             themeMode: profileProvider.themeMode,
//             theme: ThemeData(
//               colorScheme: ColorScheme.fromSeed(
//                   seedColor: Colors.deepPurple, brightness: Brightness.light),
//               useMaterial3: true,
//             ),
//             darkTheme: ThemeData(
//               colorScheme: ColorScheme.fromSeed(
//                   seedColor: Colors.deepPurple, brightness: Brightness.dark),
//               useMaterial3: true,
//             ),
//             home: Consumer<AuthProvider>(
//               builder: (context, authProvider, _) {
//                 if (authProvider.isAuthenticated) {
//                   return const MainNavigationScreen();
//                 }
//                 return const AuthScreen();
//               },
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// update : Use ChangeNotifierProxyProvider so DietProvider receives AuthProvider:

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'core/services/hive_service.dart';
// import 'features/auth/presentation/providers/auth_provider.dart';
// import 'features/auth/presentation/screens/auth_screen.dart';
// import 'features/dashboard/presentation/pages/main_navigation_screen.dart';
// import 'features/diet/presentation/providers/diet_provider.dart';
// import 'features/workout/presentation/providers/workout_provider.dart';
// import 'features/profile/presentation/providers/profile_provider.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await HiveService.init();
//   runApp(const GymTrackerApp());
// }

// class GymTrackerApp extends StatelessWidget {
//   const GymTrackerApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => AuthProvider()),
//         ChangeNotifierProvider(create: (_) => WorkoutProvider()),
//         ChangeNotifierProxyProvider<AuthProvider, DietProvider>(
//           create: (context) => DietProvider(context.read<AuthProvider>()),
//           update: (context, auth, previous) => DietProvider(auth),
//         ),
//         ChangeNotifierProvider(create: (_) => ProfileProvider()),
//       ],
//       child: Consumer<ProfileProvider>(
//         builder: (context, profileProvider, _) {
//           return MaterialApp(
//             title: 'Gym Tracker',
//             debugShowCheckedModeBanner: false,
//             themeMode: profileProvider.themeMode,
//             theme: ThemeData(
//               colorScheme: ColorScheme.fromSeed(
//                   seedColor: Colors.deepPurple, brightness: Brightness.light),
//               useMaterial3: true,
//             ),
//             darkTheme: ThemeData(
//               colorScheme: ColorScheme.fromSeed(
//                   seedColor: Colors.deepPurple, brightness: Brightness.dark),
//               useMaterial3: true,
//             ),
//             home: Consumer<AuthProvider>(
//               builder: (context, authProvider, _) {
//                 if (authProvider.isAuthenticated) {
//                   return const MainNavigationScreen();
//                 }
//                 return const AuthScreen();
//               },
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

/* update 

Register Adapter and Open Box in main.dart
Ensure that MealModelAdapter() is registered before opening HiveService.mealBoxName in your main() function:


*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/services/hive_service.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/screens/auth_screen.dart';
import 'features/dashboard/presentation/pages/main_navigation_screen.dart';
import 'features/diet/presentation/providers/diet_provider.dart';
import 'features/workout/presentation/providers/workout_provider.dart';
import 'features/profile/presentation/providers/profile_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  runApp(const GymTrackerApp());
}

class GymTrackerApp extends StatelessWidget {
  const GymTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WorkoutProvider()),
        ChangeNotifierProxyProvider<AuthProvider, DietProvider>(
          create: (context) => DietProvider(context.read<AuthProvider>()),
          update: (context, auth, previous) => DietProvider(auth),
        ),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      child: Consumer<ProfileProvider>(
        builder: (context, profileProvider, _) {
          return MaterialApp(
            title: 'Gym Tracker',
            debugShowCheckedModeBanner: false,
            themeMode: profileProvider.themeMode,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.deepPurple, brightness: Brightness.light),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.deepPurple, brightness: Brightness.dark),
              useMaterial3: true,
            ),
            home: Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                if (authProvider.isAuthenticated) {
                  return const MainNavigationScreen();
                }
                return const AuthScreen();
              },
            ),
          );
        },
      ),
    );
  }
}
