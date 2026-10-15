import 'dart:async';
import 'package:flutter/material.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

import 'package:gym_tracker_app/core/services/hive_service.dart';
import 'package:gym_tracker_app/features/auth/data/models/user_model.dart';
import 'package:gym_tracker_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:gym_tracker_app/features/workout/presentation/providers/workout_provider.dart';
import 'package:gym_tracker_app/features/diet/presentation/providers/diet_provider.dart';

class AuthProvider extends ChangeNotifier {
  static const String _userBoxName = 'userBox';
  static const String _activeUserEmailKey = 'activeUserEmail';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  UserModel? _currentUser;
  bool _isLoading = false;

  int _failedLoginAttempts = 0;
  DateTime? _lockoutEndTime;
  Timer? _lockoutTimer;
  // Add this getter alias inside AuthProvider class:
  UserModel? get user => _currentUser;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  int get failedLoginAttempts => _failedLoginAttempts;

  bool get isLockedOut {
    if (_lockoutEndTime == null) return false;
    if (DateTime.now().isAfter(_lockoutEndTime!)) {
      _lockoutEndTime = null;
      _failedLoginAttempts = 0;
      return false;
    }
    return true;
  }

  int get lockoutSecondsRemaining {
    if (_lockoutEndTime == null) return 0;
    final diff = _lockoutEndTime!.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  AuthProvider() {
    _loadUser();
  }

  bool recordFailedLogin() {
    _failedLoginAttempts++;
    if (_failedLoginAttempts >= 5) {
      _lockoutEndTime = DateTime.now().add(const Duration(seconds: 30));
      notifyListeners();
      return true;
    }
    notifyListeners();
    return false;
  }

  void resetFailedAttempts() {
    _failedLoginAttempts = 0;
    _lockoutEndTime = null;
    _lockoutTimer?.cancel();
    notifyListeners();
  }

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

  void syncUserProviders(BuildContext context, String userId) {
    Provider.of<WorkoutProvider>(context, listen: false)
        .loadUserWorkouts(userId);
    Provider.of<DietProvider>(context, listen: false).loadUserMeals(userId);
    Provider.of<ProfileProvider>(context, listen: false)
        .loadUserProfile(userId);
  }

  void _resetUserProviders(BuildContext context) {
    Provider.of<WorkoutProvider>(context, listen: false).resetState();
    Provider.of<DietProvider>(context, listen: false).resetState();
    Provider.of<ProfileProvider>(context, listen: false).resetState();
  }

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
      resetFailedAttempts();

      if (context != null && context.mounted) {
        syncUserProviders(context, newUser.id);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(
    String email,
    String password, [
    BuildContext? context,
  ]) async {
    if (isLockedOut) {
      throw Exception(
          'Too many failed login attempts. Retry in $lockoutSecondsRemaining seconds.');
    }

    _isLoading = true;
    notifyListeners();

    try {
      final cleanEmail = email.trim().toLowerCase();
      final userBox = await Hive.openBox<UserModel>(
        _userBoxName,
        encryptionCipher: HiveService.cipher,
      );

      if (!userBox.containsKey(cleanEmail)) {
        recordFailedLogin();
        throw Exception('No account found with this email address.');
      }

      final savedUser = userBox.get(cleanEmail);
      if (savedUser == null || savedUser.passwordHash == null) {
        recordFailedLogin();
        throw Exception('Invalid email or password.');
      }

      final isPasswordValid = BCrypt.checkpw(password, savedUser.passwordHash!);
      if (!isPasswordValid) {
        recordFailedLogin();
        throw Exception('Invalid email or password.');
      }

      await _secureStorage.write(key: _activeUserEmailKey, value: cleanEmail);

      _currentUser = savedUser;
      resetFailedAttempts();

      if (context != null && context.mounted) {
        syncUserProviders(context, savedUser.id);
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    final userBox = await Hive.openBox<UserModel>(
      _userBoxName,
      encryptionCipher: HiveService.cipher,
    );

    if (!userBox.containsKey(cleanEmail)) {
      throw Exception('No account found with this email address.');
    }

    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  Future<void> resetPasswordWithNewPassword({
    required String email,
    required String newPassword,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final cleanEmail = email.trim().toLowerCase();
      final userBox = await Hive.openBox<UserModel>(
        _userBoxName,
        encryptionCipher: HiveService.cipher,
      );

      if (!userBox.containsKey(cleanEmail)) {
        throw Exception('No account found with this email address.');
      }

      final existingUser = userBox.get(cleanEmail)!;
      final hashedPassword = BCrypt.hashpw(newPassword, BCrypt.gensalt());

      final updatedUser = UserModel(
        id: existingUser.id,
        email: existingUser.email,
        passwordHash: hashedPassword,
        name: existingUser.name,
        age: existingUser.age,
        weight: existingUser.weight,
        fitnessGoal: existingUser.fitnessGoal,
      );

      await userBox.put(cleanEmail, updatedUser);
      if (_currentUser?.email == cleanEmail) {
        _currentUser = updatedUser;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> changePassword(String newPassword) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final userBox = await Hive.openBox<UserModel>(
        _userBoxName,
        encryptionCipher: HiveService.cipher,
      );

      final hashedPassword = BCrypt.hashpw(newPassword, BCrypt.gensalt());
      final updatedUser = UserModel(
        id: _currentUser!.id,
        email: _currentUser!.email,
        passwordHash: hashedPassword,
        name: _currentUser!.name,
        age: _currentUser!.age,
        weight: _currentUser!.weight,
        fitnessGoal: _currentUser!.fitnessGoal,
      );

      await userBox.put(_currentUser!.email, updatedUser);
      _currentUser = updatedUser;
      return true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    required String name,
    String? fitnessGoal,
    int? age,
    double? weight,
    double? height,
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

  /// Wipe all logs across disk and UI state
  Future<void> deleteAllLogs([BuildContext? context]) async {
    if (context != null && context.mounted) {
      final dietProvider = Provider.of<DietProvider>(context, listen: false);
      final workoutProvider =
          Provider.of<WorkoutProvider>(context, listen: false);

      await dietProvider.clearAllMeals();
      await workoutProvider.clearAllWorkouts();
    }
    notifyListeners();
  }

  Future<void> deleteAccount([BuildContext? context]) async {
    if (_currentUser == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await deleteAllLogs(context);

      final userBox = await Hive.openBox<UserModel>(
        _userBoxName,
        encryptionCipher: HiveService.cipher,
      );

      await userBox.delete(_currentUser!.email);
      await _secureStorage.delete(key: _activeUserEmailKey);

      if (context != null && context.mounted) {
        _resetUserProviders(context);
      }

      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout([BuildContext? context]) async {
    await _secureStorage.delete(key: _activeUserEmailKey);

    if (context != null && context.mounted) {
      _resetUserProviders(context);
    }

    _currentUser = null;
    notifyListeners();
  }
}
