// lib/services/step_service.dart
import 'dart:async';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// StepService using the device's step counter sensor (pedometer)
/// - start() begins listening to the pedometer stream
/// - stop() cancels the subscription
/// - getTodaySteps() returns the most recent count for today
class StepService {
  StreamSubscription<StepCount>? _sub;
  int _currentCumulative = 0; // latest cumulative value from sensor
  int _todayBaseline = 0; // baseline cumulative at start of day
  int _todaySteps = 0;
  bool _listening = false;

  static const _prefsKeyDate = 'pedometer-date';
  static const _prefsKeyBaseline = 'pedometer-baseline';
  static const _prefsKeyLastCumulative = 'pedometer-lastCumulative';
  static const _prefsKeyTodaySteps = 'pedometer-todaySteps';

  /// Start listening to the pedometer stream
  Future<void> start() async {
    if (_listening) return;
    _listening = true;

    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString(_prefsKeyDate) ?? '';
    final todayKey = _todayKey();

    if (savedDate == todayKey) {
      _todayBaseline = prefs.getInt(_prefsKeyBaseline) ?? 0;
      _todaySteps = prefs.getInt(_prefsKeyTodaySteps) ?? 0;
      _currentCumulative = prefs.getInt(_prefsKeyLastCumulative) ?? 0;
    } else {
      _todayBaseline = 0;
      _todaySteps = 0;
      _currentCumulative = prefs.getInt(_prefsKeyLastCumulative) ?? 0;
    }

    _sub = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: _onError,
      onDone: _onDone,
      cancelOnError: false,
    );
  }

  /// Stop listening to the pedometer stream
  Future<void> stop() async {
    _listening = false;
    await _sub?.cancel();
    _sub = null;
  }

  String _todayKey() {
    final now = DateTime.now();
    final date =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    return date;
  }

  Future<void> _onStepCount(StepCount event) async {
    final cumulative = event.steps ?? 0;
    _currentCumulative = cumulative;

    final prefs = await SharedPreferences.getInstance();
    final todayKey = _todayKey();
    final savedDate = prefs.getString(_prefsKeyDate) ?? '';

    if (savedDate != todayKey) {
      // new day: use current cumulative as baseline
      _todayBaseline = cumulative;
      _todaySteps = 0;
      await prefs.setString(_prefsKeyDate, todayKey);
      await prefs.setInt(_prefsKeyBaseline, _todayBaseline);
      await prefs.setInt(_prefsKeyLastCumulative, cumulative);
      await prefs.setInt(_prefsKeyTodaySteps, _todaySteps);
      return;
    }

    if (_todayBaseline == 0) {
      _todayBaseline = prefs.getInt(_prefsKeyBaseline) ?? cumulative;
      if (_todayBaseline > cumulative) _todayBaseline = cumulative;
      await prefs.setInt(_prefsKeyBaseline, _todayBaseline);
    }

    if (cumulative < _todayBaseline) {
      // sensor reset (e.g., device reboot)
      _todayBaseline = cumulative;
      await prefs.setInt(_prefsKeyBaseline, _todayBaseline);
    }

    _todaySteps = cumulative - _todayBaseline;
    if (_todaySteps < 0) _todaySteps = 0;

    await prefs.setInt(_prefsKeyLastCumulative, cumulative);
    await prefs.setInt(_prefsKeyTodaySteps, _todaySteps);
  }

  void _onError(Object error) {
    // optionally log
  }

  void _onDone() {
    // stream closed
  }

  /// Returns the most recent known step count for today
  Future<int> getTodaySteps() async {
    if (_todaySteps > 0) return _todaySteps;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_prefsKeyTodaySteps) ?? 0;
  }
}
