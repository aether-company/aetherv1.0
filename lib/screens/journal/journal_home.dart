import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/journal_service.dart';
import '../../models/journal_entry.dart';
import 'journal_entry_screen.dart';
import 'journal_detail_screen.dart';

class JournalHome extends StatefulWidget {
  @override
  _JournalHomeState createState() => _JournalHomeState();
}

class _JournalHomeState extends State<JournalHome>
    with SingleTickerProviderStateMixin {
  final JournalService _journalService = JournalService();
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd – HH:mm').format(date);
  }

  String getMoodIcon(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return '😊';
      case 'sad':
        return '😔';
      case 'excited':
        return '🤩';
      case 'angry':
        return '😠';
      case 'anxious':
        return '😰';
      case 'grateful':
        return '🙏';
      case 'calm':
        return '😌';
      case 'tired':
        return '😪';
      case 'stressed':
        return '😧';
      case 'neutral':
        return '😐';
      default:
        return '📖';
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text(
            "Please log in to view entries.",
            style: GoogleFonts.poppins(fontSize: 18, color: Colors.white),
          ),
        ),
      );
    }

    String userId = user.uid;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal, Colors.lightBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10),

              /// TITLE
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Text(
                  "Memory Log",
                  style: GoogleFonts.sacramento(
                    fontSize: 68,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(left: 26, bottom: 12),
                child: DefaultTextStyle(
                  style: GoogleFonts.poppins(fontSize: 18, color: Colors.white),
                  child: AnimatedTextKit(
                    totalRepeatCount: 1,
                    animatedTexts: [
                      TypewriterAnimatedText(
                        'Write your story.',
                        speed: Duration(milliseconds: 120),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              /// LIST CONTENT
              Expanded(
                child: StreamBuilder<List<JournalEntry>>(
                  stream: _journalService.getUserEntries(userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          "Error loading entries.",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          "Start writing your first memory!",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }

                    final entries = snapshot.data!;

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                transitionDuration: Duration(milliseconds: 400),
                                pageBuilder:
                                    (_, anim, __) => FadeTransition(
                                      opacity: anim,
                                      child: JournalDetailScreen(entry: entry),
                                    ),
                              ),
                            );
                          },
                          child: Container(
                            margin: EdgeInsets.only(bottom: 18),
                            padding: EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Color(0xFFA8E6CF),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.teal.shade900,
                                width: 1.4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 12,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  getMoodIcon(entry.mood),
                                  style: TextStyle(fontSize: 36),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  entry.title.isNotEmpty
                                      ? entry.title
                                      : "Untitled",
                                  style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  "Mood: ${entry.mood} • ${formatDate(entry.date)}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: AnimatedBuilder(
        animation: _scaleAnimation,
        builder:
            (context, child) => Transform.scale(
              scale: _scaleAnimation.value,
              child: FloatingActionButton.extended(
                backgroundColor: Color(0xFF00BFA6),
                icon: Icon(Icons.edit, size: 26),
                label: Text(
                  "New Entry",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
                elevation: 8,
                onPressed: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      transitionDuration: Duration(milliseconds: 400),
                      pageBuilder:
                          (_, anim, __) => FadeTransition(
                            opacity: anim,
                            child: JournalEntryScreen(),
                          ),
                    ),
                  );
                },
              ),
            ),
      ),
    );
  }
}
