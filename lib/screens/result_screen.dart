import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:pdf_brain/widgets/ask_brain.dart';

class ResultScreen extends StatefulWidget {
  final List<String> summaryPoints;
  final List<String> keywords;
  final String pdfText;

  const ResultScreen({
    super.key,
    required this.summaryPoints,
    required this.keywords,
    required this.pdfText,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final FlutterTts flutterTts = FlutterTts();
  final List<String> selectedKeywords = [];

  int currentReadIndex = -1;
  bool isReading = false;

  /// ---------------- CLEANED SUMMARY ----------------
  List<String> get cleanedSummary => widget.summaryPoints
      .map((e) => e
      .replaceAll(RegExp(r'•+'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim())
      .where((e) => e.isNotEmpty)
      .toList();

  /// ---------------- FILTERED SUMMARY ----------------
  List<String> get filteredSummary {
    if (selectedKeywords.isEmpty) return cleanedSummary;

    return cleanedSummary.where((point) {
      final lowerPoint = point.toLowerCase();
      return selectedKeywords.any((keyword) {
        final lowerKeyword = keyword.toLowerCase();
        // Whole word OR partial match
        return lowerPoint.contains(" $lowerKeyword ") ||
            lowerPoint.startsWith(lowerKeyword) ||
            lowerPoint.endsWith(lowerKeyword) ||
            lowerPoint.contains(lowerKeyword);
      });
    }).toList();
  }

  @override
  void initState() {
    super.initState();

    flutterTts
      ..setLanguage("en-US")
      ..setSpeechRate(0.45)
      ..setPitch(1.0);

    flutterTts.setCompletionHandler(() {
      setState(() => currentReadIndex++);
      if (currentReadIndex < filteredSummary.length) {
        _speak(filteredSummary[currentReadIndex]);
      } else {
        setState(() {
          currentReadIndex = -1;
          isReading = false;
        });
      }
    });
  }

  Future<void> _speak(String text) async {
    await flutterTts.speak(text);
  }

  Future<void> _pauseSpeaking() async {
    await flutterTts.pause();
    setState(() => isReading = false);
  }

  void _resumeSpeaking() {
    if (currentReadIndex >= 0 &&
        currentReadIndex < filteredSummary.length) {
      setState(() => isReading = true);
      _speak(filteredSummary[currentReadIndex]);
    } else {
      _startSpeaking();
    }
  }

  void _startSpeaking() {
    if (filteredSummary.isEmpty) return;
    setState(() {
      currentReadIndex = 0;
      isReading = true;
    });
    _speak(filteredSummary[0]);
  }

  /// ---------------- SAVE AS PDF ----------------
  Future<void> _saveAsPdf() async {
    final pdf = PdfDocument();
    final page = pdf.pages.add();
    final content = cleanedSummary.map((e) => '• $e').join('\n');

    page.graphics.drawString(
      content,
      PdfStandardFont(PdfFontFamily.helvetica, 12),
    );

    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/summary_$timestamp.pdf');
    await file.writeAsBytes(bytes, flush: true);
    pdf.dispose();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Saved as summary_$timestamp.pdf')),
      );
    }
  }

  /// ---------------- SHARE ----------------
  Future<void> _shareSummary() async {
    final text = cleanedSummary.map((e) => '• $e').join('\n');
    await Share.share(text);
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Stop words for filtering
    final stopWords = {
      'a', 'an', 'the', 'is', 'are', 'was', 'were', 'be', 'been',
      'in', 'on', 'at', 'to', 'for', 'with', 'of', 'and', 'or', 'but',
      'so', 'if', 'then', 'this', 'that', 'these', 'those',
      'here', 'there', 'from', 'by', 'as', 'it', 'its', 'they', 'them', 'you',
    };

    final filteredKeywords = widget.keywords
        .expand((k) => k.split(RegExp(r'\s+')))
        .map((k) => k.trim().toLowerCase().replaceAll(RegExp(r'[^\w]'), ''))
        .where((k) => k.isNotEmpty && !stopWords.contains(k))
        .toSet()
        .take(10)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("📄 Summary Insights"),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "💡 Filter by Keywords",
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      filteredKeywords.isEmpty
                          ? const Text("No keywords found.",
                          style: TextStyle(color: Colors.grey))
                          : Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: filteredKeywords.map((keyword) {
                          final isSelected =
                          selectedKeywords.contains(keyword);
                          return FilterChip(
                            label: Text(
                              keyword,
                              style: TextStyle(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : null,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: theme.colorScheme.primary
                                .withOpacity(0.15),
                            onSelected: (value) {
                              setState(() {
                                isSelected
                                    ? selectedKeywords.remove(keyword)
                                    : selectedKeywords.add(keyword);
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "📌 Summary Points",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      filteredSummary.isEmpty
                          ? const Center(
                          child: Text("No summary points to display."))
                          : ListView.separated(
                        itemCount: filteredSummary.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        separatorBuilder: (_, __) =>
                        const Divider(height: 8, thickness: 0.5),
                        itemBuilder: (_, index) {
                          final isCurrent = index == currentReadIndex;
                          return AnimatedContainer(
                            duration:
                            const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? theme.colorScheme.primary
                                  .withOpacity(0.1)
                                  : theme.brightness ==
                                  Brightness.dark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            child: Row(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                const Text("- ",
                                    style: TextStyle(fontSize: 18)),
                                Expanded(
                                  child: Text(
                                    filteredSummary[index],
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isCurrent
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf_rounded,
                          color: Colors.white),
                      label: const Text("Save"),
                      onPressed: _saveAsPdf,
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        isReading ? _pauseSpeaking() : _resumeSpeaking();
                      },
                      child: Icon(
                        isReading
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.share_rounded,
                          color: Colors.white),
                      label: const Text("Share"),
                      onPressed: _shareSummary,
                    ),
                  ],
                ),
              ),
            ],
          ),

          /// 🔥 Floating chatbot button (uses full PDF text for accuracy)
          Positioned(
            bottom: 80,
            right: 20,
            child: AskBrain(
              pdfText: widget.pdfText, // full extracted PDF text
            ),
          ),
        ],
      ),
    );
  }
}
