import 'package:flutter/material.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gym_tracker_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

import 'package:gym_tracker_app/core/services/hive_service.dart';
import 'package:gym_tracker_app/features/auth/data/models/user_model.dart';
import 'package:gym_tracker_app/features/workout/presentation/providers/workout_provider.dart';
import 'package:gym_tracker_app/features/diet/presentation/providers/diet_provider.dart';

class AuthProvider extends ChangeNotifier {
  static const String _userBoxName = 'userBox';
  static const String _activeUserEmailKey = 'activeUserEmail';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _loadUser();
  }

  /// Load session from Android Keystore / iOS Keychain
  Future<void> _loadUser() async {
    try {
      final activeEmail = await _secureStorage.read(key: _activeUserEmailKey);
      if (activeEmail != null && activeEmail.isNotEmpty) {
        final userBox = await Hive.openBox<UserModel>(
          _userBoxName,
          encryptionCipher: HiveService.cipher,
        );
        if (userBox.containsKey(activeEmail)) {
          _currentUser = userBox.get(activeEmail);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error restoring user session: $e');
    }
  }

  // /// Sync user data across child providers
  // void syncUserProviders(BuildContext context, String userId) {
  //   Provider.of<WorkoutProvider>(context, listen: false)
  //       .loadUserWorkouts(userId);
  //   Provider.of<DietProvider>(context, listen: false).loadUserMeals(userId);
  // }

  // /// Clear in-memory state across child providers
  // void _resetUserProviders(BuildContext context) {
  //   Provider.of<WorkoutProvider>(context, listen: false).resetState();
  //   Provider.of<DietProvider>(context, listen: false).resetState();
  // }

  void syncUserProviders(BuildContext context, String userId) {
    Provider.of<WorkoutProvider>(context, listen: false)
        .loadUserWorkouts(userId);
    Provider.of<DietProvider>(context, listen: false).loadUserMeals(userId);
    Provider.of<ProfileProvider>(context, listen: false)
        .loadUserProfile(userId);
  }

  /// Clear in-memory state across all child providers on logout
  void _resetUserProviders(BuildContext context) {
    Provider.of<WorkoutProvider>(context, listen: false).resetState();
    Provider.of<DietProvider>(context, listen: false).resetState();
    Provider.of<ProfileProvider>(context, listen: false).resetState();
  }

  /// Flexible Sign Up (supports optional BuildContext)
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    int? age,
    double? weight,
    String? fitnessGoal,
    BuildContext? context,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final cleanEmail = email.trim().toLowerCase();
      final userBox = await Hive.openBox<UserModel>(
        _userBoxName,
        encryptionCipher: HiveService.cipher,
      );

      if (userBox.containsKey(cleanEmail)) {
        throw Exception('An account with this email already exists.');
      }

      final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());

      final newUser = UserModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        email: cleanEmail,
        passwordHash: hashedPassword,
        name: name,
        age: age,
        weight: weight,
        fitnessGoal: fitnessGoal,
      );

      await userBox.put(cleanEmail, newUser);
      await _secureStorage.write(key: _activeUserEmailKey, value: cleanEmail);

      _currentUser = newUser;

      if (context != null && context.mounted) {
        syncUserProviders(context, newUser.id);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Flexible Login (supports positional arguments and optional BuildContext)
  Future<void> login(
    String email,
    String password, [
    BuildContext? context,
  ]) async {
    _isLoading = true;
    notifyListeners();

    try {
      final cleanEmail = email.trim().toLowerCase();
      final userBox = await Hive.openBox<UserModel>(
        _userBoxName,
        encryptionCipher: HiveService.cipher,
      );

      if (!userBox.containsKey(cleanEmail)) {
        throw Exception('Invalid email or password.');
      }

      final savedUser = userBox.get(cleanEmail);
      if (savedUser == null || savedUser.passwordHash == null) {
        throw Exception('Invalid email or password.');
      }

      final isPasswordValid = BCrypt.checkpw(password, savedUser.passwordHash!);
      if (!isPasswordValid) {
        throw Exception('Invalid email or password.');
      }

      await _secureStorage.write(key: _activeUserEmailKey, value: cleanEmail);

      _currentUser = savedUser;

      if (context != null && context.mounted) {
        syncUserProviders(context, savedUser.id);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update profile details
  Future<void> updateProfile({
    required String name,
    String? fitnessGoal,
    int? age,
    double? weight,
  }) async {
    if (_currentUser == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final userBox = await Hive.openBox<UserModel>(
        _userBoxName,
        encryptionCipher: HiveService.cipher,
      );

      final updatedUser = UserModel(
        id: _currentUser!.id,
        email: _currentUser!.email,
        passwordHash: _currentUser!.passwordHash,
        name: name,
        age: age ?? _currentUser!.age,
        weight: weight ?? _currentUser!.weight,
        fitnessGoal: fitnessGoal ?? _currentUser!.fitnessGoal,
      );

      await userBox.put(_currentUser!.email, updatedUser);
      _currentUser = updatedUser;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Logout (supports calling with 0 arguments or with BuildContext)
  Future<void> logout([BuildContext? context]) async {
    await _secureStorage.delete(key: _activeUserEmailKey);

    if (context != null && context.mounted) {
      _resetUserProviders(context);
    }

    _currentUser = null;
    notifyListeners();
  }
}
