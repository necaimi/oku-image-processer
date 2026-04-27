import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'theme.dart';
import 'layout/main_layout.dart';
import 'providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Run App
  runApp(
    const ProviderScope(
      child: OkuApp(),
    ),
  );

  // 3. Bitsdojo Window Configuration
  doWhenWindowReady(() {
    final win = appWindow;
    const initialSize = Size(1200, 800);
    win.minSize = const Size(800, 600);
    win.size = initialSize;
    win.alignment = Alignment.center;
    win.title = "Oku Image Processor";
    
    // Explicitly show the window now that the native frame is removed
    win.show();
  });
}

class OkuApp extends ConsumerWidget {
  const OkuApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Oku Image Processor',
      theme: getAppTheme(ThemeMode.light),
      darkTheme: getAppTheme(ThemeMode.dark),
      themeMode: settings.themeMode,
      locale: Locale(settings.language),
      home: const MainLayout(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(settings.fontSizeFactor),
          ),
          child: child!,
        );
      },
    );
  }
}
