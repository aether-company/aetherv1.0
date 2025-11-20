import 'package:animate_gradient/animate_gradient.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../forum/forum_home.dart';
import '../journal/journal_home.dart';
import '../chatbot/chatbot_screen.dart';
import '../emotion/emotion_log_screen.dart';
import '../music/music_screen.dart';
import '../insights/insights_screen.dart';
import '../insights/insight_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/music_recommendation.dart';
import '../music/music_player_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import 'package:video_player/video_player.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AuthService _authService = AuthService();

  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;

  void _logout(BuildContext context) async {
    await _authService.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  List<Map<String, dynamic>> insightsList = [];

  @override
  void initState() {
    super.initState();

    // Initialize video player
    _controller =
        VideoPlayerController.asset('assets/images/b1.mp4')
          ..setLooping(true)
          ..setVolume(0.0); // Mute the video
    _initializeVideoPlayerFuture = _controller.initialize().then((_) {
      _controller.play(); // Start playing the video
      setState(() {}); // Rebuild the widget once the video is initialized
    });

    // Fetch insights (as in your backend)
    fetchInsights();
  }

  void fetchInsights() async {
    final userId = _authService.currentUserId;
    if (userId == null) return;

    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('insights_generated')
            .orderBy('timestamp', descending: true)
            .get();

    final loadedInsights = snapshot.docs.map((doc) => doc.data()).toList();

    setState(() {
      insightsList = loadedInsights.cast<Map<String, dynamic>>();
    });
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 8.0, bottom: 5),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Future<List<MusicTrack>> fetchLatestRecommendations() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print('User not logged in');
      return [];
    }

    final userId = user.uid;

    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('music_recommendations')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

    if (snapshot.docs.isEmpty) return [];

    final data = snapshot.docs.first.data();

    final List<dynamic> moodTracksRaw = data['moodTracks'] ?? [];
    final List<dynamic> emotionTracksRaw = data['emotionTracks'] ?? [];

    final moodTracks =
        moodTracksRaw
            .map((track) => MusicTrack.fromMap(track))
            .take(2)
            .toList();
    final emotionTracks =
        emotionTracksRaw
            .map((track) => MusicTrack.fromMap(track))
            .take(2)
            .toList();

    return [...moodTracks, ...emotionTracks];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color.fromARGB(255, 4, 18, 39), // Dark background
      drawer: Drawer(
        backgroundColor: const Color.fromARGB(
          255,
          190,
          217,
          242,
        ).withOpacity(0.8), // semi-transparent for glass effect
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color.fromARGB(255, 19, 68, 123),
                    const Color.fromARGB(255, 34, 97, 149),
                  ], // Gradient header
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/logo.png', // Logo for the app
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            _buildDrawerItem(
              Icons.person,
              "Profile",
              onTap: () {
                Navigator.pop(context); // Close the drawer
                // Navigate to Profile screen later
              },
            ),
            _buildDrawerItem(
              Icons.music_note,
              "Music Recommendations",
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => MusicRecommendationScreen(
                          userId: _authService.currentUserId!,
                        ),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              Icons.article,
              "Insights",
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => InsightsScreen()),
                );
              },
            ),
            _buildDrawerItem(
              Icons.run_circle,
              "Activity Tracker",
              onTap: () {
                Navigator.pop(context); // Close the drawer
                // Add navigation later for Activity Tracker
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Animated Gradient Background from the front-end
          AnimateGradient(
            primaryColors: [
              const Color.fromARGB(255, 4, 29, 67),
              const Color.fromARGB(255, 3, 47, 97),
              const Color.fromARGB(255, 10, 49, 87),
            ],
            secondaryColors: [
              const Color.fromARGB(255, 7, 33, 56),
              const Color.fromARGB(255, 22, 55, 82),
              const Color.fromARGB(255, 6, 50, 87),
            ],
            duration: Duration(seconds: 10),
            child: SizedBox.expand(),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Header: Logo and Menu icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Builder(
                        builder:
                            (context) => IconButton(
                              icon: Icon(Icons.menu, color: Colors.white),
                              onPressed:
                                  () => _scaffoldKey.currentState?.openDrawer(),
                            ),
                      ),
                      Image.asset(
                        'assets/images/logo.png',
                        height: 100,
                        width: 200,
                      ),
                      IconButton(
                        icon: Icon(Icons.logout, color: Colors.white),
                        onPressed: () {
                          // Handle logout
                          _logout(context);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Greeting Text: "Hello buddy!"
                  Text(
                    'Hello buddy!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: 30),
                  // Emotion Logging Tile
                  _buildEmotionLoggingTile(),
                  const SizedBox(height: 15),
                  // Button Row
                  _buildButtonRow(context),
                  const SizedBox(height: 15),
                  // Insights Section Title
                  _buildSectionTitle("Insights"),
                  _buildInsightsSection(),
                  const SizedBox(height: 15),
                  // Music Recommendations Section Title
                  _buildSectionTitle("Music Recommendations"),
                  // Music Recommendations from Backend
                  FutureBuilder<List<MusicTrack>>(
                    future:
                        fetchLatestRecommendations(), // Ensure `userId` is available
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator(); // Loading indicator
                      } else if (snapshot.hasError ||
                          !snapshot.hasData ||
                          snapshot.data!.isEmpty) {
                        return SizedBox.shrink(); // No recommendations available
                      } else {
                        return _buildMusicRecommendations(
                          snapshot.data!,
                          context,
                        ); // Music recommendations widget
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionLoggingTile() {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => EmotionLogScreen(
                  userId: _authService.currentUserId!,
                ), // Pass actual userId
          ),
        );

        if (result == 'completed') {
          setState(() {
            // Update the tile text to show a new message
            _tileText = "Feel free to log again!";
          });
        }
      },
      child: Container(
        height: 150,
        width: double.infinity,
        margin: EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 1,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            fit: StackFit.expand,
            children: [
              FutureBuilder(
                future: _initializeVideoPlayerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done &&
                      _controller.value.isInitialized) {
                    return FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _controller.value.size.width,
                        height: _controller.value.size.height,
                        child: VideoPlayer(_controller),
                      ),
                    );
                  } else {
                    return Container(color: Colors.blueGrey.shade200);
                  }
                },
              ),
              Center(
                child: Text(
                  _tileText, // Dynamically change the tile text
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // A state variable to store the tile text
  String _tileText = "Log Emotions"; // Default text

  Widget _buildButtonRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: _buildNavButton(
            context,
            "Forum",
            Icons.forum,
            ForumHome(),
            Colors.cyan,
            false,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _buildNavButton(
            context,
            "Journal",
            Icons.book,
            JournalHome(),
            Colors.blueAccent,
            false,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _buildNavButton(
            context,
            "Lily",
            Icons.smart_toy,
            ChatbotScreen(),
            Colors.teal,
            true,
          ),
        ), // Lily uses image
      ],
    );
  }

  Widget _buildNavButton(
    BuildContext context,
    String text,
    IconData icon,
    Widget page,
    Color color,
    bool isImageIcon,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => page));
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: color.withOpacity(0.1),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                isImageIcon
                    ? Image.asset(
                      'assets/images/lily.png',
                      width: 30,
                      height: 30,
                    ) // Image for Lily
                    : Icon(
                      icon,
                      color: Colors.white,
                      size: 28,
                    ), // Icons for other buttons
                SizedBox(height: 5),
                Text(text, style: TextStyle(color: Colors.white, fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInsightsSection() {
    return Container(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: insightsList.length,
        itemBuilder: (context, index) {
          final insight = insightsList[index];
          return _buildInsightCard(insight, context);
        },
      ),
    );
  }

  Widget _buildInsightCard(Map<String, dynamic> insight, BuildContext context) {
    String previewText =
        insight['text']
            .toString()
            .split(' ')
            .take(12) // Shorter prompt for vertical focus
            .join(' ') +
        '...';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InsightDetailScreen(insight: insight),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: 160,
            margin: EdgeInsets.symmetric(horizontal: 10),
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF1E3A8A).withOpacity(0.6),
                  Color(0xFF3B82F6).withOpacity(0.5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    previewText,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: Offset(1, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMusicRecommendations(
    List<MusicTrack> tracks,
    BuildContext context,
  ) {
    if (tracks.length < 4) return SizedBox.shrink();

    return GridView.builder(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 1.2,
      ),
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        return _buildSmallMusicTile(tracks[index], context);
      },
    );
  }

  Widget _buildSmallMusicTile(MusicTrack track, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => MusicPlayerScreen(
                  title: track.trackName,
                  url: track.trackUrl,
                ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            image: NetworkImage(track.albumArtUrl),
            fit: BoxFit.cover,
          ),
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Text(
              track.trackName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(title, style: TextStyle(color: Colors.black)),
      onTap: onTap,
    );
  }
}
