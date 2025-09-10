import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;

class ChatbotScreen extends StatefulWidget {
  final String pdfText;

  const ChatbotScreen({super.key, required this.pdfText});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];

  bool _loading = false;
  bool _isAIEnabled = true; // default AI mode on
  late stt.SpeechToText _speech;
  bool _isListening = false;

  static const String _geminiApiKey = "AIzaSyAJUEPYaU8h30agKiKX2Bzf1qU7gx0sXi8";

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  /// ---------------- OFFLINE ANSWER ----------------
  Future<Map<String, dynamic>> _offlineAnswer(String question) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final sentences = widget.pdfText.split(RegExp(r'[.\n]'));
    final words = question.toLowerCase().split(RegExp(r'\s+'));
    final matches = sentences.where((s) {
      final lower = s.toLowerCase();
      return words.any((w) => lower.contains(w));
    }).toList();
    final answer = matches.isNotEmpty
        ? matches.join(". ").trim()
        : "📄 Sorry, I couldn’t find anything in the PDF.";
    return {"text": answer};
  }

  /// ---------------- GEMINI AI ANSWER ----------------
  Future<Map<String, dynamic>> _aiAnswer(String question) async {
    try {
      // Limit PDF text to max 2000 characters per chunk to avoid API failure
      final chunks = <String>[];
      String remaining = widget.pdfText;
      while (remaining.isNotEmpty) {
        final take = remaining.length > 2000 ? 2000 : remaining.length;
        chunks.add(remaining.substring(0, take));
        remaining = remaining.substring(take);
      }

      String combinedAnswer = "";
      for (final chunk in chunks) {
        final url = Uri.parse(
            "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_geminiApiKey");

        final body = jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text":
                  "You are a helpful assistant. Use the following PDF text to answer clearly and concisely:\n\n$chunk\n\nUser Question: $question"
                }
              ]
            }
          ]
        });

        final res = await http
            .post(url, headers: {"Content-Type": "application/json"}, body: body)
            .timeout(const Duration(seconds: 20));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final reply = data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"];
          if (reply != null && reply.trim().isNotEmpty) {
            combinedAnswer += reply.trim() + " ";
          }
        } else {
          return {
            "text":
            "⚠️ AI request failed (${res.statusCode}). Try again or use Offline Mode."
          };
        }
      }

      return {
        "text": combinedAnswer.isNotEmpty
            ? combinedAnswer.trim()
            : "🤖 AI could not generate an answer."
      };
    } on TimeoutException {
      return {"text": "⚠️ AI request timed out. Please try again."};
    } catch (e) {
      return {"text": "⚠️ AI Error: $e"};
    }
  }

  /// ---------------- SEND MESSAGE ----------------
  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "text": text});
      _loading = true;
    });
    _controller.clear();
    _scrollToBottom();

    final botResponse =
    _isAIEnabled ? await _aiAnswer(text) : await _offlineAnswer(text);

    await Future.delayed(const Duration(milliseconds: 500)); // typing delay

    setState(() {
      _messages.add(botResponse);
      _loading = false;
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// ---------------- SPEECH TO TEXT ----------------
  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {},
        onError: (error) => debugPrint("Speech error: $error"),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(onResult: (result) {
          _controller.text = result.recognizedWords;
          if (result.finalResult) {
            _sendMessage(result.recognizedWords.trim());
            setState(() => _isListening = false);
          }
        });
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  /// ---------------- MESSAGE BUBBLES ----------------
  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final isUser = msg["role"] == "user";
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: isUser ? Colors.blueAccent : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isUser ? 12 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 12),
          ),
        ),
        child: Text(
          msg["text"] ?? "",
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ask Brain"),
        centerTitle: true,
        actions: [
          Row(
            children: [
              const Text("AI Mode"),
              Switch(
                value: _isAIEnabled,
                onChanged: (v) {
                  setState(() => _isAIEnabled = v);
                },
              ),
            ],
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) =>
                  _buildMessageBubble(_messages[index]),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: "Type your message...",
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening ? Colors.red : Colors.grey,
                    ),
                    onPressed: _listen,
                  ),
                  IconButton(
                    icon: _loading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                      CircularProgressIndicator(strokeWidth: 2.5),
                    )
                        : const Icon(Icons.send),
                    onPressed: _loading
                        ? null
                        : () => _sendMessage(_controller.text.trim()),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
