import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/journal_service.dart';
import '../../models/journal_entry.dart';
import 'journal_home.dart';

class JournalEntryScreen extends StatefulWidget {
  final JournalEntry? entry;

  JournalEntryScreen({this.entry});

  @override
  _JournalEntryScreenState createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final JournalService _journalService = JournalService();
  final _uuid = Uuid();

  List<String> _notes = [];
  String _selectedMood = 'Neutral';

  bool _isDarkTheme = false; // UI ONLY — does not affect logic

  final List<Map<String, String>> moods = [
    {'mood': 'Happy', 'emoji': '😊'},
    {'mood': 'Sad', 'emoji': '😢'},
    {'mood': 'Angry', 'emoji': '😡'},
    {'mood': 'Excited', 'emoji': '🤩'},
    {'mood': 'Anxious', 'emoji': '😰'},
    {'mood': 'Grateful', 'emoji': '🙏'},
    {'mood': 'Calm', 'emoji': '😌'},
    {'mood': 'Tired', 'emoji': '😴'},
    {'mood': 'Stressed', 'emoji': '😖'},
    {'mood': 'Neutral', 'emoji': '😐'},
  ];

  final List<Color> stickyNoteColors = [
    Color(0xFFFFF9C4),
    Color(0xFFB2EBF2),
    Color(0xFFC8E6C9),
    Color(0xFFFFCCBC),
    Color(0xFFD1C4E9),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      _titleController.text = widget.entry!.title;
      _contentController.text = widget.entry!.content;
      _notes = List.from(widget.entry!.notes);
      _selectedMood = widget.entry!.mood;
    }
  }

  void _saveEntry() async {
    String title = _titleController.text.trim();
    String content = _contentController.text.trim();

    if (_noteController.text.isNotEmpty) {
      _notes.add(_noteController.text.trim());
      _noteController.clear();
    }

    if (title.isNotEmpty && content.isNotEmpty) {
      String userId = FirebaseAuth.instance.currentUser?.uid ?? "default_user";
      String entryId = widget.entry?.entryId ?? _uuid.v4();
      DateTime entryDate = widget.entry?.date ?? DateTime.now();

      JournalEntry newEntry = JournalEntry(
        entryId: entryId,
        userId: userId,
        title: title,
        content: content,
        notes: _notes,
        mood: _selectedMood,
        date: entryDate,
      );

      if (widget.entry == null) {
        await _journalService.addEntry(newEntry);
      } else {
        await _journalService.updateEntry(entryId, newEntry.toMap());
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Entry Saved!")));

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => JournalHome()),
        (route) => false,
      );
    }
  }

  void _addNote() {
    if (_noteController.text.isNotEmpty) {
      setState(() {
        _notes.add(_noteController.text.trim());
        _noteController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBG =
        _isDarkTheme ? Color(0xFF0B1B30) : Color(0xFFE8FAF4);
    final Color cardColor = _isDarkTheme ? Color(0xFF15283F) : Colors.white;
    final Color textColor = _isDarkTheme ? Colors.white : Colors.black87;
    final Color accentColor =
        _isDarkTheme ? Color(0xFF4FA3FF) : Color(0xFF4FC3F7);

    return Scaffold(
      backgroundColor: primaryBG,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          widget.entry == null ? "New Memory" : "Edit Memory",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.check, color: textColor, size: 28),
            onPressed: _saveEntry,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔵 THEME SWITCH
              _buildCleanCard(
                cardColor,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Theme",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    Switch(
                      value: _isDarkTheme,
                      activeColor: accentColor,
                      onChanged:
                          (value) => setState(() => _isDarkTheme = value),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 18),

              // TITLE FIELD
              _buildCleanCard(
                cardColor,
                TextField(
                  controller: _titleController,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  decoration: InputDecoration(
                    hintText: "Entry title...",
                    hintStyle: GoogleFonts.poppins(
                      color: textColor.withOpacity(0.4),
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),

              SizedBox(height: 16),

              // CONTENT FIELD
              _buildCleanCard(
                cardColor,
                SizedBox(
                  height: 320,
                  child: TextField(
                    controller: _contentController,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    style: GoogleFonts.poppins(fontSize: 16, color: textColor),
                    decoration: InputDecoration(
                      hintText: "Write your thoughts...",
                      hintStyle: GoogleFonts.poppins(
                        color: textColor.withOpacity(0.45),
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 18),
              Text(
                "Mood",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              SizedBox(height: 10),

              // MOOD SELECTOR
              SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: moods.length,
                  itemBuilder: (context, index) {
                    final mood = moods[index];
                    final isSelected = _selectedMood == mood['mood'];
                    return GestureDetector(
                      onTap:
                          () => setState(() => _selectedMood = mood['mood']!),
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 6),
                        padding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: isSelected ? accentColor : cardColor,
                          border: Border.all(
                            color:
                                isSelected
                                    ? accentColor
                                    : textColor.withOpacity(0.15),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              mood['emoji']!,
                              style: TextStyle(fontSize: 18),
                            ),
                            SizedBox(width: 6),
                            Text(
                              mood['mood']!,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isSelected ? Colors.white : textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              SizedBox(height: 20),

              // NOTE FIELD
              _buildCleanCard(
                cardColor,
                TextField(
                  controller: _noteController,
                  style: GoogleFonts.poppins(fontSize: 15, color: textColor),
                  decoration: InputDecoration(
                    hintText: "Add note...",
                    hintStyle: GoogleFonts.poppins(
                      color: textColor.withOpacity(0.4),
                    ),
                    border: InputBorder.none,
                    suffixIcon: IconButton(
                      icon: Icon(Icons.add, color: textColor),
                      onPressed: _addNote,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 12),

              // NOTES DISPLAY
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children:
                    _notes.asMap().entries.map((entry) {
                      int index = entry.key;
                      String note = entry.value;
                      return Container(
                        width: 140,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: stickyNoteColors[index %
                                  stickyNoteColors.length]
                              .withOpacity(_isDarkTheme ? 0.85 : 1),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              offset: Offset(2, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              note,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: textColor,
                              ),
                            ),
                            Align(
                              alignment: Alignment.topRight,
                              child: GestureDetector(
                                onTap:
                                    () => setState(() => _notes.remove(note)),
                                child: Icon(
                                  Icons.close,
                                  size: 16,
                                  color: textColor.withOpacity(0.6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCleanCard(Color cardColor, Widget child) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      margin: EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
