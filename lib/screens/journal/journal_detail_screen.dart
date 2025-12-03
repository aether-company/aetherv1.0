import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/journal_entry.dart';
import '../../services/journal_service.dart';
import 'journal_home.dart';

class JournalDetailScreen extends StatelessWidget {
  final JournalEntry entry;
  final JournalService _journalService = JournalService();

  JournalDetailScreen({required this.entry});

  void _deleteEntry(BuildContext context) async {
    await _journalService.deleteEntry(entry.entryId!);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Entry deleted.")));
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => JournalHome()),
      (route) => false,
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}-${date.month}-${date.year}";
  }

  final List<Color> stickyNoteColors = [
    Color(0xFF2D2D2D),
    Color(0xFF3A3A3A),
    Color(0xFF4A4A4A),
    Color(0xFF5A5A5A),
    Color(0xFF333333),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      entry.title.isNotEmpty ? entry.title : "Untitled",
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.redAccent.withOpacity(0.3),
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _deleteEntry(context),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 18),

              /// CONTENT CARD
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade800, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    painter: LinedPaperPainterDark(),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// MOOD + DATE
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Mood: ${entry.mood}",
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.tealAccent,
                                ),
                              ),
                              Text(
                                _formatDate(entry.date),
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 22),

                          /// BODY CONTENT
                          Text(
                            entry.content,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              height: 1.5,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withOpacity(0.92),
                            ),
                          ),

                          SizedBox(height: 26),

                          /// NOTES
                          if (entry.notes.isNotEmpty) ...[
                            Text(
                              "Notes",
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 14),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children:
                                  entry.notes.asMap().entries.map((e) {
                                    int index = e.key;
                                    String note = e.value;
                                    return Container(
                                      padding: EdgeInsets.all(14),
                                      width: 140,
                                      decoration: BoxDecoration(
                                        color:
                                            stickyNoteColors[index %
                                                stickyNoteColors.length],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white12,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.4,
                                            ),
                                            blurRadius: 5,
                                            offset: Offset(2, 3),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        note,
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// DARK LINED PAPER LINES
class LinedPaperPainterDark extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withOpacity(0.05)
          ..strokeWidth = 1;

    for (double y = 22; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
