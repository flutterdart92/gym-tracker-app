// import 'package:hive_flutter/hive_flutter.dart';
// import '../../../../core/services/hive_service.dart'; // Adjust path if needed

// class StreakService {
//   static const String _currentStreakKey = 'current_streak';
//   static const String _lastLogDateKey = 'last_log_date';

//   static Box get _box => Hive.box(HiveService.streakBoxName);

//   static int getCurrentStreak() {
//     return _box.get(_currentStreakKey, defaultValue: 5);
//   }

//   static Future<Map<String, dynamic>> checkAndIncrementStreak() async {
//     int streak = _box.get(_currentStreakKey, defaultValue: 5);
//     String? lastLogDateStr = _box.get(_lastLogDateKey);

//     DateTime now = DateTime.now();
//     DateTime today = DateTime(now.year, now.month, now.day);

//     if (lastLogDateStr == null) {
//       streak = 1;
//       await _box.put(_currentStreakKey, streak);
//       await _box.put(_lastLogDateKey, today.toIso8601String());
//       return {'isNewDay': true, 'streak': streak};
//     }

//     DateTime lastLogDate = DateTime.parse(lastLogDateStr);
//     DateTime lastLogDayOnly =
//         DateTime(lastLogDate.year, lastLogDate.month, lastLogDate.day);

//     int differenceDays = today.difference(lastLogDayOnly).inDays;

//     if (differenceDays == 0) {
//       // Already logged today
//       return {'isNewDay': false, 'streak': streak};
//     } else if (differenceDays == 1) {
//       // Consecutive day! Increment streak
//       streak += 1;
//       await _box.put(_currentStreakKey, streak);
//       await _box.put(_lastLogDateKey, today.toIso8601String());
//       return {'isNewDay': true, 'streak': streak};
//     } else {
//       // Streak broken, reset to 1
//       streak = 1;
//       await _box.put(_currentStreakKey, streak);
//       await _box.put(_lastLogDateKey, today.toIso8601String());
//       return {'isNewDay': true, 'streak': streak};
//     }
//   }
// }

import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/services/hive_service.dart';

class StreakService {
  static const String _currentStreakKey = 'current_streak';
  static const String _lastLogDateKey = 'last_log_date';

  static Box get _box => Hive.box(HiveService.streakBoxName);

  static int getCurrentStreak() {
    return _box.get(_currentStreakKey, defaultValue: 5);
  }

  static Future<Map<String, dynamic>> checkAndIncrementStreak() async {
    int streak = _box.get(_currentStreakKey, defaultValue: 5);
    String? lastLogDateStr = _box.get(_lastLogDateKey);

    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    if (lastLogDateStr == null) {
      streak = 1;
      await _box.put(_currentStreakKey, streak);
      await _box.put(_lastLogDateKey, today.toIso8601String());
      return {'isNewDay': true, 'streak': streak};
    }

    DateTime lastLogDate = DateTime.parse(lastLogDateStr);
    DateTime lastLogDayOnly =
        DateTime(lastLogDate.year, lastLogDate.month, lastLogDate.day);

    int differenceDays = today.difference(lastLogDayOnly).inDays;

    if (differenceDays == 0) {
      // Already logged today
      return {'isNewDay': false, 'streak': streak};
    } else if (differenceDays == 1) {
      // Consecutive day! Increment streak
      streak += 1;
      await _box.put(_currentStreakKey, streak);
      await _box.put(_lastLogDateKey, today.toIso8601String());
      return {'isNewDay': true, 'streak': streak};
    } else {
      // Streak broken, reset to 1
      streak = 1;
      await _box.put(_currentStreakKey, streak);
      await _box.put(_lastLogDateKey, today.toIso8601String());
      return {'isNewDay': true, 'streak': streak};
    }
  }
}
