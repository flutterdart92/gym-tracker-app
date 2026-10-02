import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../features/workout/data/models/exercise_model.dart';
import '../../features/diet/data/models/meal_model.dart';

class HiveService {
  static const String exerciseBoxName = 'exercise_box';
  static const String mealBoxName = 'meal_box';
  static const String userBoxName = 'userBox';
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

    // Retrieve or generate 256-bit encryption key stored in Hardware Keystore
    _cipherKey = await _getOrCreateEncryptionKey();
    final cipher = HiveAesCipher(_cipherKey!);

    // Safely open encrypted boxes
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
    } catch (e) {
      // Re-create boxes if key or schema fails
      await Hive.deleteBoxFromDisk(exerciseBoxName);
      await Hive.deleteBoxFromDisk(mealBoxName);
      await Hive.deleteBoxFromDisk(userBoxName);

      await Hive.openBox<ExerciseModel>(exerciseBoxName,
          encryptionCipher: cipher);
      await Hive.openBox<MealModel>(mealBoxName, encryptionCipher: cipher);
      await Hive.openBox<UserModel>(userBoxName, encryptionCipher: cipher);
    }
  }

  /// Retrieve or generate hardware-backed encryption key
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

  /// Getter for the active HiveAesCipher
  static HiveAesCipher get cipher => HiveAesCipher(_cipherKey!);
}
