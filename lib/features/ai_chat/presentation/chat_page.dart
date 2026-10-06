import 'package:port/shared/widgets/app_bar_divider.dart';
import 'package:port/shared/widgets/markdown_viewer.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import '../data/chat_repository.dart';
import 'package:port/features/ai_chat/presentation/api_key_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:port/features/ai_chat/presentation/empty_chat_placeholder.dart';

class AiChatPage extends StatefulWidget {
  final String initialQuery;

  const AiChatPage({super.key, this.initialQuery = ""});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final ChatUser myself = ChatUser(id: "1", firstName: "User");
  final ChatUser bot = ChatUser(id: "2", firstName: "Gemini");

  List<ChatMessage> allMessages = [];
  final _chat = ChatRepository();
  String apiKey = '';
  bool isTyping = false;
  final TextEditingController messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    await _loadApiKey();
    if (!mounted) return;
    if (apiKey.isEmpty) {
      _showApiKeyDialog(context);
    } else if (widget.initialQuery.isNotEmpty) {
      await _handleInitialQuery(widget.initialQuery);
    }
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    if (mounted) {
      setState(() {
        apiKey = prefs.getString('api_key') ?? '';
      });
    }
  }

  void _showApiKeyDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent, // Glass effect background
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'API Key Required',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'You need to set up your Gemini API key to use the chat feature.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            context.go('/');
                          },
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.blueAccent.withValues(alpha: 0.8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                          ),
                          onPressed: () async {
                            Navigator.of(context).pop();

                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const ApiKeyPage(),
                              ),
                            );
                          },
                          child: const Text(
                            'Setup API Key',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
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
    if (!mounted) return;
    if (apiKey.isEmpty) {
      _showApiKeyDialog(context);
      return;
    }

    setState(() {
      isTyping = true;
      allMessages.insert(0, message);
    });

    try {
      final botText =
          await _chat.reply(apiKey: apiKey, context: _getChatContext());
      if (!mounted) return;
      final botMessage = ChatMessage(
        text: botText,
        user: bot,
        createdAt: DateTime.now(),
      );
      if (mounted) {
        setState(() {
          allMessages.insert(0, botMessage);
        });
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error: $e');
      final errorMessage = ChatMessage(
        text: 'Sorry, I encountered an error. Please try again.',
        user: bot,
        createdAt: DateTime.now(),
      );
      if (mounted) {
        setState(() {
          allMessages.insert(0, errorMessage);
        });
      }
    } finally {
      if (mounted) setState(() => isTyping = false);
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
          bottom: const AppBarDivider()),
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
                      fillColor: Colors.black.withValues(alpha: 0.5),
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
                        child: SharedMarkdownViewer(
                          enableDefaultLinks: false,
                          markdownData: message.text,
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
