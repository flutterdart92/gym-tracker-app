import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/user_model.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoggedIn = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;

  Future<bool> login(String email, String password) async {
    final box = await Hive.openBox<UserModel>('users');
    final user = box.values.firstWhere(
      (u) => u.email == email && u.password == password,
      orElse: () => UserModel(id: '', email: '', password: '', name: ''),
    );

    if (user.id.isNotEmpty) {
      _currentUser = user;
      _isLoggedIn = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> signUp(String name, String email, String password) async {
    final box = await Hive.openBox<UserModel>('users');
    final exists = box.values.any((u) => u.email == email);

    if (exists) return false;

    final newUser = UserModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      password: password,
    );

    await box.put(newUser.id, newUser);
    _currentUser = newUser;
    _isLoggedIn = true;
    notifyListeners();
    return true;
  }

  void logout() {
    _currentUser = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}
