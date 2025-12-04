// lib/screens/activity/activity_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/step_service.dart';
import '../../services/screen_time_service.dart'; // keep your existing screen time service

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen>
    with WidgetsBindingObserver {
  final StepService _stepService = StepService();
  final ScreenTimeService _screenTimeService = ScreenTimeService();

  int _steps = 0;
  Duration _screenTime = Duration.zero;
  Timer? _pollTimer;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Start pedometer service
    _stepService.start();

    _startFlow();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _stepService.stop();
    super.dispose();
  }

  // refresh when app resumes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshNow();
    }
  }

  Future<void> _startFlow() async {
    await _loadSaved();
    await _requestActivityPermission();
    await _refreshNow();

    // Periodic polling every 60 seconds
    _pollTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _refreshNow(),
    );

    setState(() => _loading = false);
  }

  Future<void> _requestActivityPermission() async {
    final status = await Permission.activityRecognition.status;
    if (!status.isGranted) {
      await Permission.activityRecognition.request();
    }
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final stepsSaved = prefs.getInt(_todayKey('steps')) ?? 0;
    final screenSaved = prefs.getInt(_todayKey('screenMinutes')) ?? 0;
    setState(() {
      _steps = stepsSaved;
      _screenTime = Duration(minutes: screenSaved);
    });
  }

  String _todayKey(String suffix) {
    final now = DateTime.now();
    final date =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    return "$date-$suffix";
  }

  Future<void> _refreshNow() async {
    // Steps
    try {
      final steps = await _stepService.getTodaySteps();
      if (mounted) setState(() => _steps = steps);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_todayKey('steps'), steps);
    } catch (e) {
      // ignore for now
    }

    // Screen time
    try {
      final screen = await _screenTimeService.getTodayScreenTime();
      if (mounted) setState(() => _screenTime = screen);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_todayKey('screenMinutes'), screen.inMinutes);
    } catch (e) {
      // ignore
    }
  }

  String _humanScreenTime(Duration d) {
    if (d.inHours >= 1) {
      final hours = d.inHours;
      final mins = d.inMinutes.remainder(60);
      return "${hours}h ${mins}m";
    } else {
      return "${d.inMinutes}m";
    }
  }

  // show dialog guiding user to enable Usage Access
  Future<void> _showUsageAccessDialog() async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Enable Usage Access"),
            content: const Text(
              "To read screen time, open Android Settings → Digital Wellbeing & parental controls → Usage Access (or Settings → Apps → Special app access → Usage access) and allow this app. Then reopen the app.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Open app settings so user can manually grant Usage Access
                  openAppSettings(); // from permission_handler
                },
                child: const Text("Open App Settings"),
              ),
            ],
          ),
    );
  }

  // --- UI code below can remain unchanged ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E14),
        centerTitle: true,
        title: const Text(
          "Your Activities",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _sectionTitle("Daily Overview"),
                  const SizedBox(height: 12),
                  _userSummaryCard(),
                  const SizedBox(height: 28),
                  _sectionTitle("Your Stats"),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _metricCard(
                          "Screen Time",
                          _humanScreenTime(_screenTime),
                          Icons.phone_android,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _metricCard(
                          "Steps Walked",
                          _steps.toString(),
                          Icons.directions_walk_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _metricCard(
                          "Water Intake",
                          "1.8 L",
                          Icons.water_drop,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _metricCard(
                          "Calories Burned",
                          "544 kcal",
                          Icons.local_fire_department,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _sectionTitle("Recommended Activities"),
                  const SizedBox(height: 16),
                  ...[
                    _activityTile("10 min meditation", false),
                    _activityTile("Read 5 pages", true),
                    _activityTile("Evening walk for 20 mins", false),
                    _activityTile("Drink 2 glasses of water", true),
                    _activityTile("Limit phone usage before bed", false),
                  ],
                  const SizedBox(height: 32),
                  _sectionTitle("Completed Today"),
                  const SizedBox(height: 16),
                  ...[
                    _activityTile("Morning stretching routine", true),
                    _activityTile("Completed journal entry", true),
                  ],
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await _refreshNow();
                      } catch (_) {}
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text("Refresh now"),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _showUsageAccessDialog,
                    icon: const Icon(Icons.settings),
                    label: const Text(
                      "Open Usage Access / App Settings (Android)",
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    "Tip: On Android, allow 'Usage Access' if prompted so screen time can be read. On iOS, full device screen-time is restricted by Apple. Steps require Health/Google Fit permissions and a real device.",
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
    );
  }

  Widget _sectionTitle(String text) => Text(
    text,
    style: TextStyle(
      color: Colors.blue.shade300,
      fontSize: 18,
      fontWeight: FontWeight.bold,
    ),
  );

  Widget _userSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueGrey.shade800, width: 1),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 34,
            backgroundColor: Colors.blueAccent,
            child: Icon(Icons.person, color: Colors.white, size: 40),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Aether User",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Level 5 • Streak: 12 days 🔥",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blueGrey.shade800, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue.shade300, size: 30),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _activityTile(String task, bool completed) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: completed ? Colors.blueAccent : Colors.blueGrey.shade800,
        ),
      ),
      child: Row(
        children: [
          Icon(
            completed ? Icons.check_circle : Icons.radio_button_unchecked,
            color: completed ? Colors.blueAccent : Colors.white60,
          ),
          const SizedBox(width: 14),
          Text(
            task,
            style: TextStyle(
              color: completed ? Colors.blue.shade200 : Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
