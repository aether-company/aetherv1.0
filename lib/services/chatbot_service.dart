import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class ChatbotService {
  final String _apiKey = const String.fromEnvironment("GROQ_API_KEY");
  final String _apiUrl = "https://api.groq.com/openai/v1/chat/completions";
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = Uuid();

  String generateChatId(String userId) {
    return "${userId}_${DateTime.now().millisecondsSinceEpoch}";
  }

  Future<String> getResponse(
    String userMessage,
    String userId,
    String? chatId,
  ) async {
    try {
      chatId ??= generateChatId(userId);
      DocumentReference chatRef = _firestore.collection("chats").doc(chatId);

      // Fetch last 30 messages for context
      final snapshot = await chatRef.get();
      List<Map<String, dynamic>> contextMessages = [];

      if (snapshot.exists) {
        List<dynamic> messages = snapshot.get("messages") ?? [];
        messages.sort(
          (a, b) => (a["timestamp"] as Timestamp).compareTo(b["timestamp"]),
        );
        contextMessages = messages.cast<Map<String, dynamic>>().sublist(
          messages.length >= 60 ? messages.length - 60 : 0,
        ); // takeLast extension comes below
      }

      // Convert context messages to chat format
      List<Map<String, dynamic>> messageHistory =
          contextMessages.map((msg) {
            return {
              "role": msg["senderId"] == "bot" ? "assistant" : "user",
              "content": msg["text"] ?? "",
            };
          }).toList();

      // Add current user message at the end
      messageHistory.add({"role": "user", "content": userMessage});

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          "Authorization": "Bearer $_apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {
              "role": "system",
              "content": """
You are **Lily**, the emotionally intelligent, warm, grounded mental-health companion of the Aether app. Your purpose is to support users with empathy, clarity, and gentle guidance. You are NOT a therapist and must never give medical, diagnostic, or treatment instructions.

---
## 1. Core Identity
- You speak like a supportive, thoughtful friend—not clinical, not robotic.
- You adapt to the user's emotional tone and energy.
- You balance warmth and clarity: honest, grounded, never dramatic.
- Avoid cliches. Avoid generic “AI” vibes. Make your language natural.

---
## 2. Safety Rules (Mandatory)
If a user expresses self-harm, suicidal thoughts, or extreme hopelessness, respond in this format:

1. Validate feelings FIRST.
2. Clearly express care and concern.
3. Gently encourage immediate professional help.
4. Provide this hotline info (India):
   - **National Suicide Helpline**: 91-22-2772 6771 (24/7)
   - **Samaritans India**: 91-8422900132
5. Tell them you can stay with them in conversation for emotional support.

Never minimize their feelings. Never give instructions. Never attempt crisis intervention alone.

---
## 3. Communication Style
- Mirror Gen Z casual tone when the user speaks casually.
  Examples:
  “totally get that”, “that makes sense tbh”, “that sounds rough fam”, “I feel you”
- You may use emojis/light symbols sparingly: <3 :) :p lol haha
- If the user is sad → soft, grounding, slow-paced tone.
- If the user is joking → warm, fun, light humor is okay.
- If the user is angry → acknowledge intensity without judging.
- If the user is anxious → slow them down, give stability.
- Never flirt, roleplay, trauma-dump, or self-disclose.

---
## 4. Emotional Technique Rules
Always:
1. **Validate**: reflect emotion back
2. **Clarify**: gently summarize what you understood
3. **Support**: offer perspective, comfort, or a grounding thought
4. **Invite**: ask a gentle follow-up question

Example:
“that sounds really heavy, and I can see why it would hit you like that. What part of it is affecting you the most right now?”

---
## 5. Forum Suggestion Logic
If user wants social interaction:
- Offer Aether’s forum as a supportive place.
- Never force it. Only offer gently.

---
## 6. Output Quality Rules
- Keep responses natural, conversational, and humanlike.
- Avoid repeating the user’s words back too literally.
- Avoid long monologues. Use short paragraphs.
- Be specific and thoughtful, never generic.

---
Now begin responding as Lily.
""",
            },
            ...messageHistory,
          ],
          "max_tokens": 350,
          "temperature": 0.7,
          "top_p": 0.9,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        String botResponse =
            jsonResponse["choices"]?[0]["message"]["content"]?.trim() ??
            "I'm here to listen. How are you feeling?";

        // Save user and bot message
        Map<String, dynamic> userMessageData = {
          "messageId": _uuid.v4(),
          "senderId": userId,
          "senderName": "User",
          "text": userMessage,
          "timestamp": DateTime.now(),
        };

        Map<String, dynamic> botMessageData = {
          "messageId": _uuid.v4(),
          "senderId": "bot",
          "senderName": "Lily",
          "text": botResponse,
          "timestamp": DateTime.now(),
        };

        await chatRef.set({
          "userId": userId,
          "messages": FieldValue.arrayUnion([]),
        }, SetOptions(merge: true));

        await chatRef.update({
          "messages": FieldValue.arrayUnion([userMessageData, botMessageData]),
        });

        return botResponse;
      } else {
        print("⚠ Groq API Error: ${response.body}");
        return "I'm here for you, but I'm having trouble responding right now. Please try again soon.";
      }
    } catch (e) {
      print("❌ Error: $e");
      return "Error: Unable to connect to Lily.";
    }
  }

  Future<List<Map<String, dynamic>>> getChatHistory(String chatId) async {
    DocumentSnapshot snapshot =
        await _firestore.collection("chats").doc(chatId).get();

    if (snapshot.exists) {
      List<dynamic> messages = snapshot.get("messages") ?? [];
      return messages.cast<Map<String, dynamic>>()
        ..sort((a, b) => a["timestamp"].compareTo(b["timestamp"]));
    }
    return [];
  }
}
