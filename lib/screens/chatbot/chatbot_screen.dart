import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/chatbot_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatbotScreen extends StatefulWidget {
  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ChatbotService _chatbotService = ChatbotService();

  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> messages = [];
  bool _isLoading = false;
  String? _selectedChatId;
  List<String> _chatSessions = [];

  @override
  void initState() {
    super.initState();
    _loadChatSessions();
  }

  Future<void> _loadChatSessions() async {
    final snapshot = await FirebaseFirestore.instance.collection('chats').get();
    setState(() {
      _chatSessions = snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  Future<void> _loadChatHistory(String chatId) async {
    final doc =
        await FirebaseFirestore.instance.collection('chats').doc(chatId).get();
    if (doc.exists) {
      setState(() {
        messages =
            (doc.data()?['messages'] as List<dynamic>)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
        _selectedChatId = chatId;
      });
      _scrollToBottom();
    }
  }

  Future<void> _saveChat() async {
    if (_selectedChatId == null) {
      final newDoc = await FirebaseFirestore.instance.collection('chats').add({
        'messages': messages,
      });
      setState(() {
        _selectedChatId = newDoc.id;
        _chatSessions.add(newDoc.id);
      });
    } else {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(_selectedChatId)
          .update({'messages': messages});
    }
  }

  Future<void> _sendMessage() async {
    String userMessage = _controller.text.trim();
    if (userMessage.isEmpty) return;

    setState(() {
      messages.add({"user": userMessage});
      messages.add({"bot": "Lily is thinking..."});
      _isLoading = true;
    });

    _controller.clear();
    _scrollToBottom();

    try {
      String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      String botResponse = await _chatbotService.getResponse(
        userMessage,
        _selectedChatId ?? '',
        userId,
      );

      setState(() {
        messages.removeLast();
        messages.add({
          "bot":
              botResponse.isNotEmpty
                  ? botResponse
                  : "Hmm... I'm not sure how to respond to that.",
        });
        _isLoading = false;
      });

      await _saveChat();
      _scrollToBottom();
    } catch (e) {
      setState(() {
        messages.removeLast();
        messages.add({"bot": "Oops! Something went wrong."});
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    // wait for frame to be rendered then scroll
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.minScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // keep original gradient colors — only tweak layout/shape/typography
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar: avatar + title — tightened layout and subtle spacing
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundImage: AssetImage(
                        'assets/images/lily_icon.png',
                      ),
                    ),
                    SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Lily",
                          style: GoogleFonts.dancingScript(
                            fontSize: 30,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Your friendly assistant",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white70,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                    Spacer(),
                    // optional place for session / settings icon in future (keeps top bar balanced)
                    // Icon(Icons.more_vert, color: Colors.white70),
                  ],
                ),
              ),

              // Message list — reversed so newest appears at bottom.
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Scrollbar(
                    radius: Radius.circular(8),
                    thumbVisibility: true,
                    child: ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: EdgeInsets.symmetric(vertical: 10),
                      itemCount: messages.length,
                      itemBuilder: (context, reversedIndex) {
                        // because list is reversed, map index appropriately
                        final index = messages.length - 1 - reversedIndex;
                        final msg = messages[index];
                        final isUser = msg.containsKey('user');
                        final message = msg.values.first?.toString() ?? '';

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Align(
                            alignment:
                                isUser
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.76,
                              ),
                              child: ChatBubble(
                                message: message,
                                isUser: isUser,
                                avatar:
                                    isUser
                                        ? null
                                        : AssetImage(
                                          'assets/images/lily_icon.png',
                                        ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Input area — compact, clean, with elevated circular send button
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.06),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  hintText: 'Type your message...',
                                  hintStyle: GoogleFonts.inter(
                                    color: Colors.white54,
                                    fontSize: 15,
                                  ),
                                  border: InputBorder.none,
                                ),
                                textCapitalization:
                                    TextCapitalization.sentences,
                                onSubmitted: (value) => _sendMessage(),
                              ),
                            ),
                            if (_isLoading)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.0,
                                    valueColor: AlwaysStoppedAnimation(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Material(
                      color: Colors.transparent,
                      shape: CircleBorder(),
                      child: InkWell(
                        onTap: _sendMessage,
                        customBorder: CircleBorder(),
                        child: Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            // keep the send icon white, but give the button a subtle translucent background for affordance
                            color: Colors.white.withOpacity(0.06),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reusable bubble widget — centralized styling, polished radii & shadow.
/// Does not change your colors, only refines shape, padding and shadow for a production feel.
class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final ImageProvider? avatar;

  const ChatBubble({
    Key? key,
    required this.message,
    required this.isUser,
    this.avatar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // keep your original color choices — only add subtle shadow and refined radii
    final Color userColor = Colors.blueAccent;
    final Color botColor = const Color.fromARGB(255, 156, 230, 240);

    // asymmetric radius to create a modern chat bubble shape
    final BorderRadius userRadius = BorderRadius.only(
      topLeft: Radius.circular(14),
      topRight: Radius.circular(16),
      bottomLeft: Radius.circular(16),
      bottomRight: Radius.circular(6),
    );

    final BorderRadius botRadius = BorderRadius.only(
      topLeft: Radius.circular(16),
      topRight: Radius.circular(14),
      bottomLeft: Radius.circular(6),
      bottomRight: Radius.circular(16),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isUser && avatar != null)
          Padding(
            padding: const EdgeInsets.only(right: 8.0, left: 4.0),
            child: CircleAvatar(radius: 14, backgroundImage: avatar),
          ),
        Flexible(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: isUser ? userColor : botColor,
              borderRadius: isUser ? userRadius : botRadius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.16),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: DefaultTextStyle(
              style: GoogleFonts.inter(
                fontSize: 15,
                color: isUser ? Colors.white : Colors.black87,
                height: 1.35,
              ),
              child: Text(message),
            ),
          ),
        ),
        if (isUser)
          SizedBox(
            width: 6,
          ), // balance spacing on the right side for user messages
      ],
    );
  }
}
