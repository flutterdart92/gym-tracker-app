import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../data/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  static const String _userBoxName = 'userBox';
  static const String _sessionBoxName = 'sessionBox';
  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _loadUser();
  }

  Future<void> _loadUser() async {
    final sessionBox = await Hive.openBox(_sessionBoxName);
    final userBox = await Hive.openBox<UserModel>(_userBoxName);

    final String? activeEmail = sessionBox.get('activeUserEmail');
    if (activeEmail != null && userBox.containsKey(activeEmail)) {
      _currentUser = userBox.get(activeEmail);
      notifyListeners();
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    int? age,
    double? weight,
    String? fitnessGoal,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final cleanEmail = email.trim().toLowerCase();
      final userBox = await Hive.openBox<UserModel>(_userBoxName);

      if (userBox.containsKey(cleanEmail)) {
        throw Exception("An account with this email already exists.");
      }

      final newUser = UserModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        email: cleanEmail,
        password: password,
        name: name,
        age: age,
        weight: weight,
        fitnessGoal: fitnessGoal,
      );

      // Save user profile by unique email key
      await userBox.put(cleanEmail, newUser);

      // Maintain active session
      final sessionBox = await Hive.openBox(_sessionBoxName);
      await sessionBox.put('activeUserEmail', cleanEmail);

      _currentUser = newUser;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final cleanEmail = email.trim().toLowerCase();
      final userBox = await Hive.openBox<UserModel>(_userBoxName);

      if (!userBox.containsKey(cleanEmail)) {
        throw Exception(
            "No account found for this email. Please sign up first.");
      }

      final savedUser = userBox.get(cleanEmail);
      if (savedUser == null || savedUser.password != password) {
        throw Exception("Invalid email or password.");
      }

      // Save active session key
      final sessionBox = await Hive.openBox(_sessionBoxName);
      await sessionBox.put('activeUserEmail', cleanEmail);

      _currentUser = savedUser;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final sessionBox = await Hive.openBox(_sessionBoxName);
    await sessionBox.delete('activeUserEmail');
    _currentUser = null;
    notifyListeners();
  }
}
