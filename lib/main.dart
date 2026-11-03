import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/legacy.dart';

import 'core/theme/app_theme.dart';
import 'providers/app_state_provider.dart';
import 'ui/shell/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Desktop window configuration
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: Size(1360, 860),
      minimumSize: Size(1100, 720),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      title: 'Sonicall: AI Music & Cover Studio — Trunçgil Teknoloji',
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setTitleBarStyle(TitleBarStyle.hidden, windowButtonVisibility: false);
      await windowManager.setAsFrameless();
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
      ],
      child: const SonicallApp(),
    ),
  );
}

class SonicallApp extends StatelessWidget {
  const SonicallApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();

    return MaterialApp(
      title: 'Sonicall: AI Music & Cover Studio',
      debugShowCheckedModeBanner: false,
      themeMode: state.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      builder: (context, child) {
        final windowChild = VirtualWindowFrameInit()(context, child);
        // ExcludeSemantics prevents Flutter Windows desktop embedder's accessibility_bridge.cc
        // from desynchronizing ui::AXTree (Nodes left pending by the update)
        // during rapid progress animations and overlay/dialog transitions.
        return ExcludeSemantics(child: windowChild);
      },
      home: const MainShell(),
    );
  }
}
