import 'dart:async';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:pdf_brain/secrets.dart';
import 'package:url_launcher/url_launcher.dart';

class GeminiServiceChatbot {
  final GenerativeModel _model;

  GeminiServiceChatbot(String apiKey)
      : _model = GenerativeModel(
    model: 'gemini-1.5-flash', // ✅ AI Studio model
    apiKey: AppSecrets.geminiApiKey,
  );

  /// Send a message to AI. Optional: include PDF context.
  Future<String> sendMessage(String prompt, {String pdfContext = ""}) async {
    try {
      final fullPrompt = pdfContext.isEmpty
          ? prompt
          : "You are a helpful assistant. Use the following PDF text as context:\n"
          "$pdfContext\n\nUser question:\n$prompt";

      // ---------------- STEP 1: CLASSIFY INTENT ----------------
      final classificationPrompt = """
You are an AI assistant. Classify this request into:
1. CASUAL_CHAT - general conversation, jokes, advice, etc.
2. LEARNING_REQUEST - wants to learn something with resources.

If LEARNING_REQUEST, also suggest the best platform:
YouTube, Udemy, Coursera, or GeeksforGeeks.

Request: "$fullPrompt"

Reply ONLY in format:
CATEGORY | PLATFORM | QUERY
""";

      final classifyResponse = await _model
          .generateContent([Content.text(classificationPrompt)])
          .timeout(const Duration(seconds: 15));

      final classification =
          classifyResponse.text ?? "CASUAL_CHAT | None | $fullPrompt";

      final parts = classification.split('|').map((e) => e.trim()).toList();
      final category =
      parts.isNotEmpty ? parts[0].toUpperCase() : "CASUAL_CHAT";
      final platform = parts.length > 1 ? parts[1] : "None";
      final query = parts.length > 2 ? parts[2] : fullPrompt;

      // ---------------- STEP 2: HANDLE LEARNING REQUEST ----------------
      if (category.contains("LEARNING")) {
        final encodedQuery = Uri.encodeComponent(query);
        Uri url;

        switch (platform.toLowerCase()) {
          case "youtube":
            url = Uri.parse(
                "https://www.youtube.com/results?search_query=$encodedQuery");
            break;
          case "udemy":
            url =
                Uri.parse("https://www.udemy.com/courses/search/?q=$encodedQuery");
            break;
          case "coursera":
            url = Uri.parse("https://www.coursera.org/search?query=$encodedQuery");
            break;
          case "geeksforgeeks":
            url = Uri.parse("https://www.geeksforgeeks.org/search/?q=$encodedQuery");
            break;
          default:
            url = Uri.parse("https://www.google.com/search?q=$encodedQuery");
        }

        await _launchUrl(url);
        return "🔗 Redirecting you to $platform for: $query";
      }

      // ---------------- STEP 3: CASUAL CHAT OR PDF CONTEXT ----------------
      final chatResponse = await _model
          .generateContent([Content.text(fullPrompt)])
          .timeout(const Duration(seconds: 20));

      return chatResponse.text?.trim() ??
          "🤔 I couldn’t generate a response. Try rephrasing.";
    } on TimeoutException {
      return "⚠️ AI request timed out. Please try again.";
    } catch (e) {
      print("Chatbot error: $e");
      return "❌ AI request failed. Check your API key or network.";
    }
  }

  Future<void> _launchUrl(Uri url) async {
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw "Could not launch $url";
    }
  }
}
