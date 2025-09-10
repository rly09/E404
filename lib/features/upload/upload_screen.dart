import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../../screens/result_screen.dart';
import '../../services/gemini_service.dart';
import '../../widgets/ask_brain.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> with SingleTickerProviderStateMixin {
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  String extractedText = ""; // Full PDF text for chatbot
  List<String> summaryPoints = [];
  List<String> keywords = [];

  /// Pick PDF → Extract text → Summarize + Keywords → Navigate
  Future<void> pickAndExtractText() async {
    isLoading.value = true;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result?.files.first.bytes == null) {
        _showSnackBar('❗ No PDF selected. Please try again.');
        return;
      }

      final Uint8List pdfBytes = result!.files.first.bytes!;
      final PdfDocument document = PdfDocument(inputBytes: pdfBytes);
      extractedText = PdfTextExtractor(document).extractText();
      document.dispose();

      if (extractedText.trim().isEmpty) {
        _showSnackBar('⚠️ This PDF looks empty. Try another file!');
        return;
      }

      // Generate AI summary
      summaryPoints = await GeminiService.summarizeText(extractedText);

      // Extract keywords from summary for better relevance
      keywords = await GeminiService.extractKeywordsFromSummary(summaryPoints);

      // Fallback if AI could not generate bullets
      if (summaryPoints.isEmpty) {
        summaryPoints.add('⚠️ The AI could not generate a useful summary.');
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResultScreen(
              summaryPoints: summaryPoints,
              keywords: keywords,
              pdfText: extractedText, // Full text for chatbot
            ),
          ),
        );
      }
    } catch (e) {
      _showSnackBar('❌ Something went wrong: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    isLoading.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Brain 🧠'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6A5AE0), Color(0xFF00C9A7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          Center(
            child: ValueListenableBuilder<bool>(
              valueListenable: isLoading,
              builder: (context, loading, _) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Main UI
                    Opacity(
                      opacity: loading ? 0.2 : 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.picture_as_pdf_rounded,
                            size: 100,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32.0),
                            child: Text(
                              "🚀 Upload any PDF and let PDF Brain transform it into crisp AI-powered summaries, highlight the key insights, and unlock instant knowledge!",
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 35),
                          ElevatedButton.icon(
                            onPressed: pickAndExtractText,
                            icon: const Icon(Icons.upload_file, color: Colors.white),
                            label: const Text("Upload PDF"),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 30),
                              backgroundColor: Colors.white.withOpacity(0.15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              shadowColor: Colors.black26,
                              elevation: 8,
                              textStyle: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Loading Indicator
                    if (loading)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6A5AE0), Color(0xFF00C9A7)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.6),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                )
                              ],
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Analyzing your PDF with AI magic... ✨",
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                  ],
                );
              },
            ),
          ),

          // Floating chatbot button
          Positioned(
            bottom: 80,
            right: 20,
            child: ValueListenableBuilder<bool>(
              valueListenable: isLoading,
              builder: (context, loading, _) {
                return loading ? const SizedBox() : AskBrain(pdfText: extractedText);
              },
            ),
          ),
        ],
      ),
    );
  }
}
