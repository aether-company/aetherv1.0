// lib/services/screen_time_service.dart
import 'package:app_usage/app_usage.dart';
import 'package:flutter/material.dart';

/// ScreenTimeService reads the total screen time for the last 24 hours
/// using the app_usage package.
/// Make sure the user grants "Usage Access" on Android.
class ScreenTimeService {
  /// Returns total screen time for today (Duration)
  Future<Duration> getTodayScreenTime() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final end = now;

      final List<AppUsageInfo> infoList = await AppUsage().getAppUsage(
        startOfDay,
        end,
      );

      int seconds = 0;
      for (final info in infoList) {
        seconds += info.usage.inSeconds;
      }

      return Duration(seconds: seconds);
    } catch (e) {
      debugPrint("Error reading screen time: $e");
      return Duration.zero;
    }
  }
}
