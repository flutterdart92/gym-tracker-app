import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../data/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  static const String _userBoxName = 'userBox';
  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _loadUser();
  }

  Future<void> _loadUser() async {
    final box = await Hive.openBox<UserModel>(_userBoxName);
    if (box.isNotEmpty) {
      _currentUser = box.getAt(0);
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
      final newUser = UserModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        email: email,
        password: password,
        name: name,
        age: age,
        weight: weight,
        fitnessGoal: fitnessGoal,
      );

      final box = await Hive.openBox<UserModel>(_userBoxName);
      await box.clear();
      await box.add(newUser);

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
      final box = await Hive.openBox<UserModel>(_userBoxName);

      if (box.isEmpty) {
        throw Exception("No account found. Please sign up first.");
      }

      final savedUser = box.getAt(0);
      if (savedUser?.email != email || savedUser?.password != password) {
        throw Exception("Invalid email or password.");
      }

      _currentUser = savedUser;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final box = await Hive.openBox<UserModel>(_userBoxName);
    await box.clear();
    _currentUser = null;
    notifyListeners();
  }
}
