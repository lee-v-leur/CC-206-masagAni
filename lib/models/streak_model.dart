import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StreakModel extends ChangeNotifier {
  static const _kStreakCount = 'streak_count';
  static const _kTotalPoints = 'total_points';
  static const _kLastOpen = 'last_open';

  int streakCount = 0; // real consecutive days
  int totalPoints = 0;
  DateTime? lastOpen;

  // Initialize from SharedPreferences
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    streakCount = prefs.getInt(_kStreakCount) ?? 0;
    totalPoints = prefs.getInt(_kTotalPoints) ?? 0;
    final last = prefs.getString(_kLastOpen);
    if (last != null) {
      lastOpen = DateTime.tryParse(last);
    }
    notifyListeners();
  }

  int get displayStreak {
    // Revolve display only between 150-154
    return 150 + (streakCount % 5);
  }

  // Record an app open (call on app launch or when profile screen opens)
  Future<void> recordOpen([DateTime? now]) async {
    now ??= DateTime.now();
    final nowDate = DateTime(now.year, now.month, now.day);

    if (lastOpen != null) {
      final lastDate = DateTime(lastOpen!.year, lastOpen!.month, lastOpen!.day);
      final diff = nowDate.difference(lastDate).inDays;

      if (diff == 0) {
        // Already opened today — nothing to do
        return;
      } else if (diff == 1) {
        // Consecutive day
        streakCount += 1;
        int pointsEarned = 10; // base
        // Weekly bonus when completing each 7-day block
        if (streakCount % 7 == 0) {
          pointsEarned += 20; // one-time weekly bonus
        }
        totalPoints += pointsEarned;
      } else {
        // Missed a day (or more) — reset streak
        streakCount = 1;
        totalPoints += 10; // base for today
      }
    } else {
      // First time opening
      streakCount = 1;
      totalPoints += 10;
    }

    lastOpen = nowDate;
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kStreakCount, streakCount);
    await prefs.setInt(_kTotalPoints, totalPoints);
    await prefs.setString(_kLastOpen, lastOpen?.toIso8601String() ?? '');
  }

  // For testing / debug: allow clearing streak
  Future<void> reset() async {
    streakCount = 0;
    totalPoints = 0;
    lastOpen = null;
    await _saveToPrefs();
    notifyListeners();
  }
}
