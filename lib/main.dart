import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/theme.dart' show AppTheme;
import 'features/upload/upload_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables with error handling
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("⚠️ Failed to load .env file: $e");
  }

  // Lock orientation to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar with adaptive brightness
  final brightness = WidgetsBinding.instance.window.platformBrightness;
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness:
    brightness == Brightness.dark ? Brightness.light : Brightness.dark,
    statusBarBrightness: brightness,
  ));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Brain',
      debugShowCheckedModeBanner: false,

      // Themes
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // SafeArea applied globally
      builder: (context, child) => SafeArea(child: child ?? const SizedBox.shrink()),

      // Initial screen
      home: const UploadScreen(),

      // Global smooth page transitions
      onGenerateRoute: (settings) {
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, __, ___) => const UploadScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const beginOffset = Offset(0.05, 0.1);
            const endOffset = Offset.zero;

            final offsetTween = Tween(begin: beginOffset, end: endOffset)
                .chain(CurveTween(curve: Curves.easeOutCubic));

            return SlideTransition(
              position: animation.drive(offsetTween),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
        );
      },
    );
  }
}
