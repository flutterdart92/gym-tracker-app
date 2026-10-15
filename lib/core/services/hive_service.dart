import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gym_tracker_app/features/auth/data/models/set_model.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../features/workout/data/models/exercise_model.dart';
import '../../features/diet/data/models/meal_model.dart';
import '../../features/diet/data/models/food_item_model.dart';

class HiveService {
  static const String exerciseBoxName = 'exercise_box';
  static const String mealBoxName = 'meal_box';
  static const String userBoxName = 'userBox';
  static const String recentFoodsBoxName = 'recent_foods_box';
  static const String _encryptionKeyAlias = 'hive_encryption_key';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static Uint8List? _cipherKey;

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register Hive adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ExerciseModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(MealModelAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(FoodItemModelAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      // <--- ADD THIS
      Hive.registerAdapter(SetModelAdapter());
    }

    _cipherKey = await _getOrCreateEncryptionKey();
    final cipher = HiveAesCipher(_cipherKey!);

    try {
      if (!Hive.isBoxOpen(exerciseBoxName)) {
        await Hive.openBox<ExerciseModel>(exerciseBoxName,
            encryptionCipher: cipher);
      }
      if (!Hive.isBoxOpen(mealBoxName)) {
        await Hive.openBox<MealModel>(mealBoxName, encryptionCipher: cipher);
      }
      if (!Hive.isBoxOpen(userBoxName)) {
        await Hive.openBox<UserModel>(userBoxName, encryptionCipher: cipher);
      }
      if (!Hive.isBoxOpen(recentFoodsBoxName)) {
        await Hive.openBox<FoodItemModel>(recentFoodsBoxName,
            encryptionCipher: cipher);
      }
    } catch (e) {
      await Hive.deleteBoxFromDisk(exerciseBoxName);
      await Hive.deleteBoxFromDisk(mealBoxName);
      await Hive.deleteBoxFromDisk(userBoxName);
      await Hive.deleteBoxFromDisk(recentFoodsBoxName);

      await Hive.openBox<ExerciseModel>(exerciseBoxName,
          encryptionCipher: cipher);
      await Hive.openBox<MealModel>(mealBoxName, encryptionCipher: cipher);
      await Hive.openBox<UserModel>(userBoxName, encryptionCipher: cipher);
      await Hive.openBox<FoodItemModel>(recentFoodsBoxName,
          encryptionCipher: cipher);
    }
  }

  static Future<Uint8List> _getOrCreateEncryptionKey() async {
    final existingKeyBase64 =
        await _secureStorage.read(key: _encryptionKeyAlias);

    if (existingKeyBase64 != null) {
      return base64Url.decode(existingKeyBase64);
    }

    final newKey = Hive.generateSecureKey();
    final newKeyBase64 = base64Url.encode(newKey);

    await _secureStorage.write(
      key: _encryptionKeyAlias,
      value: newKeyBase64,
    );

    return Uint8List.fromList(newKey);
  }

  static HiveAesCipher get cipher => HiveAesCipher(_cipherKey!);
}
