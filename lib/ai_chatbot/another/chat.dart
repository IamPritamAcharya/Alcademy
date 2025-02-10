import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:http/http.dart' as http;
import 'package:port/ai_chatbot/another/apikey.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'EmptyChatPlaceholder.dart';

class AiChatPage extends StatefulWidget {
  final String initialQuery;

  const AiChatPage({Key? key, this.initialQuery = ""}) : super(key: key);

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final ChatUser myself = ChatUser(id: "1", firstName: "User");
  final ChatUser bot = ChatUser(id: "2", firstName: "Gemini");

  List<ChatMessage> allMessages = [];
  String apiKey = '';
  bool isTyping = false;
  final TextEditingController messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadApiKey();
    if (widget.initialQuery.isNotEmpty) {
      _handleInitialQuery(widget.initialQuery);
    }
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      apiKey = prefs.getString('api_key') ?? '';
    });
    if (apiKey.isEmpty) {
      Navigator.pushReplacementNamed(context, '/api');
    }
  }

  Future<void> _handleInitialQuery(String query) async {
    final initialMessage = ChatMessage(
      text: query,
      user: myself,
      createdAt: DateTime.now(),
    );
    await getdata(initialMessage);
  }

  Future<void> getdata(ChatMessage message) async {
    setState(() {
      isTyping = true;
      allMessages.insert(0, message);
    });

    final url =
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$apiKey";
    final headers = {'Content-Type': 'application/json'};
    final data = {
      "contents": [
        {
          "parts": [
            {"text": _getChatContext()}
          ]
        }
      ]
    };

    try {
      final response = await http.post(Uri.parse(url),
          headers: headers, body: jsonEncode(data));
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final botText = result['candidates'][0]['content']['parts'][0]['text'];

        final botMessage = ChatMessage(
          text: botText,
          user: bot,
          createdAt: DateTime.now(),
        );
        setState(() {
          allMessages.insert(0, botMessage);
        });
      } else {
        throw Exception('API Error');
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() {
        isTyping = false;
      });
    }
  }

  String _getChatContext() {
    return allMessages.reversed
        .map((msg) => '${msg.user.firstName}: ${msg.text}')
        .join('\n');
  }

  void resetChat() {
    setState(() {
      allMessages.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D1E),
      appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: const Color(0xFF1A1D1E),
          centerTitle: true,
          title: const Text(
            'Gemini',
            style: TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'ProductSans',
              letterSpacing: 3,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              color: Colors.white.withOpacity(0.2),
              height: 1,
            ),
          )),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: DashChat(
                  currentUser: myself,
                  onSend: (ChatMessage message) {
                    getdata(message);
                    messageController.clear();
                  },
                  messages: allMessages,
                  inputOptions: InputOptions(
                    sendButtonBuilder: (void Function() onSend) {
                      return IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: onSend,
                      );
                    },
                    inputDecoration: InputDecoration(
                      hintText: 'Type your message...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.5),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 10.0, horizontal: 20.0),
                    ),
                    inputTextStyle: const TextStyle(color: Colors.white),
                    inputToolbarPadding:
                        const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 20.0),
                    leading: [
                      IconButton(
                        icon: const Icon(Icons.delete_sweep_rounded,
                            color: Colors.white70),
                        onPressed: resetChat,
                      ),
                    ],
                  ),
                  messageOptions: MessageOptions(
                    messageDecorationBuilder: (ChatMessage message, _, __) {
                      return BoxDecoration(
                        color: message.user.id == myself.id
                            ? Colors.black54
                            : Colors.grey[800],
                        borderRadius: BorderRadius.circular(20.0),
                      );
                    },
                    messageTextBuilder: (ChatMessage message, _, __) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: MarkdownBody(
                          data: message.text,
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(color: Colors.white),
                            code: const TextStyle(
                              backgroundColor: Colors.white,
                              fontFamily: 'monospace',
                              color: Colors.black,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (isTyping)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.grey,
                        child: Icon(Icons.smart_toy, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AnimatedTextKit(
                          animatedTexts: [
                            TyperAnimatedText(
                              'Gemini is typing...',
                              textStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                          repeatForever: true,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (allMessages.isEmpty) const EmptyChatPlaceholder(),
        ],
      ),
    );
  }
}
