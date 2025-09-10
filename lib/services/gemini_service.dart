import 'dart:async';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  static final _apiKey = dotenv.env['GEMINI_API_KEY'];

  /// Clean and normalize text
  static String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'\n+'), ' ')
        .trim();
  }

  /// Split large text into chunks
  static List<String> _chunkText(String text, {int chunkSize = 1500}) {
    List<String> chunks = [];
    for (int i = 0; i < text.length; i += chunkSize) {
      int end = (i + chunkSize > text.length) ? text.length : i + chunkSize;
      chunks.add(text.substring(i, end));
    }
    return chunks;
  }

  /// Summarize text into clear bullet points
  static Future<List<String>> summarizeText(String text) async {
    if (_apiKey == null) return ['⚠️ API key not found.'];
    final cleanedText = _cleanText(text);
    final chunks = _chunkText(cleanedText);

    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey!,
    );

    List<String> allBullets = [];

    for (String chunk in chunks) {
      try {
        final prompt = '''
You are an AI summarizer. Summarize the following text into concise, precise bullet points:

Rules:
- Each bullet must be short (1–2 lines max)
- Use clear, simple language
- No introductions, conclusions, or filler
- Format: • point

Text:
$chunk
''';

        final response = await model
            .generateContent([Content.text(prompt)])
            .timeout(const Duration(seconds: 25));

        final rawText = response.text ?? '';
        final bullets = rawText
            .split(RegExp(r'[\n•]+'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty && e.length > 10)
            .toList();

        allBullets.addAll(bullets);
      } on TimeoutException {
        allBullets.add('⚠️ Chunk summarization timed out.');
      } catch (e) {
        print("Gemini summarization chunk error: $e");
      }
    }

    // Remove duplicates and return
    final uniqueBullets = allBullets.toSet().toList();
    return uniqueBullets.isNotEmpty
        ? uniqueBullets
        : ['⚠️ The AI could not generate a useful summary.'];
  }

  /// Extract top 7 keywords from summarized bullet points
  static Future<List<String>> extractKeywordsFromSummary(List<String> bullets) async {
    if (_apiKey == null) return [];

    if (bullets.isEmpty) return [];

    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey!,
    );

    final combinedText = bullets.join('. ');

    try {
      final prompt = '''
Extract exactly **7 important keywords or key phrases** (1–3 words each) from the text below.
- Return keywords only, separated by commas
- No numbering, explanations, or extra words

Text:
$combinedText
''';

      final response = await model
          .generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: 25));

      final output = response.text ?? '';
      final keywords = output
          .split(',')
          .map((e) => e.trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toSet()
          .take(7)
          .toList();

      return keywords;
    } on TimeoutException {
      return ['⚠️ Timeout'];
    } catch (e) {
      print("Gemini keyword extraction error: $e");
      return [];
    }
  }
}
