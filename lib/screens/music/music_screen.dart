import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import ',./../music_player_screen.dart';
import '../../models/music_recommendation.dart';
import '../../services/recommendation_service.dart';

class MusicRecommendationScreen extends StatefulWidget {
  final String userId;

  const MusicRecommendationScreen({required this.userId, Key? key})
    : super(key: key);

  @override
  _MusicRecommendationScreenState createState() =>
      _MusicRecommendationScreenState();
}

class _MusicRecommendationScreenState extends State<MusicRecommendationScreen> {
  late final RecommendationService _recommendationService;
  List<MusicTrack> _moodTracks = [];
  List<MusicTrack> _emotionTracks = [];
  List<MusicTrack> _playedTracks = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _mood;
  String? _primaryEmotion;

  @override
  void initState() {
    super.initState();
    _recommendationService = RecommendationService();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final checkinSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .collection('checkins')
              .orderBy('date', descending: true)
              .limit(1)
              .get();

      if (checkinSnapshot.docs.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No recent check-ins found.';
        });
        return;
      }

      final checkinData = checkinSnapshot.docs.first.data();
      _mood = checkinData['mood'];
      _primaryEmotion = checkinData['primaryEmotion'];

      final recommendationsSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .collection('music_recommendations')
              .orderBy('timestamp', descending: true)
              .limit(1)
              .get();

      if (recommendationsSnapshot.docs.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No recommendations found for your latest check-in.';
        });
        return;
      }

      final recommendationData = recommendationsSnapshot.docs.first.data();
      final recommendationId = recommendationsSnapshot.docs.first.id;
      final recommendation = MusicRecommendation.fromMap(
        recommendationId,
        recommendationData,
      );

      final userPlayedUrls = recommendation.userPlayed;

      final playedTracks =
          [
            ...recommendation.moodTracks,
            ...recommendation.emotionTracks,
          ].where((track) => userPlayedUrls.contains(track.trackUrl)).toList();

      setState(() {
        _moodTracks = recommendation.moodTracks;
        _emotionTracks = recommendation.emotionTracks;
        _playedTracks = playedTracks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading recommendations: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 26, 75, 238),
              Color.fromARGB(255, 0, 138, 189),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child:
              _isLoading
                  ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                  : _errorMessage != null
                  ? Center(
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                  : ListView(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Your Music Recommendations',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_mood != null && _moodTracks.isNotEmpty)
                        _buildRecommendationSection(
                          'Since you were feeling $_mood, here are your tracks:',
                          _moodTracks,
                        ),
                      if (_primaryEmotion != null && _emotionTracks.isNotEmpty)
                        _buildRecommendationSection(
                          'Because you felt $_primaryEmotion, these might help:',
                          _emotionTracks,
                        ),
                      if (_playedTracks.isNotEmpty)
                        _buildRecommendationSection(
                          'Your Recently Played Tracks:',
                          _playedTracks,
                        ),
                    ],
                  ),
        ),
      ),
    );
  }

  Widget _buildRecommendationSection(String title, List<MusicTrack> tracks) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: tracks.length,
              separatorBuilder: (context, index) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final track = tracks[index];
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: 160,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                              child: Image.network(
                                track.albumArtUrl,
                                height: 100,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) => Container(
                                      height: 100,
                                      color: Colors.grey,
                                      child: const Icon(
                                        Icons.music_note,
                                        color: Colors.white,
                                      ),
                                    ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    track.trackName,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    track.artistName,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
