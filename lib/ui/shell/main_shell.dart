import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/legacy.dart';
import 'package:window_manager/window_manager.dart' as wm;
import '../sidebar/sidebar_widget.dart';
import '../studio/studio_panel.dart';
import '../workspace/workspace_panel.dart';
import '../player/bottom_player_widget.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  @override
  void initState() {
    super.initState();
    _applyFrameless();
  }

  Future<void> _applyFrameless() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      try {
        final win = wm.WindowManager.instance.getCurrent();
        if (win != null) {
          win.titleBarStyle = wm.TitleBarStyle.hidden;
          win.isWindowControlButtonsVisible = false;
          win.setFrameless(true);
        }
        await windowManager.setTitleBarStyle(TitleBarStyle.hidden, windowButtonVisibility: false);
        await windowManager.setAsFrameless();
      } catch (e) {
        debugPrint('[MainShell] Error setting frameless: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        children: [
          // 3-Panel Main Area
          Expanded(
            child: Row(
              children: [
                // 1. Left Navigation Sidebar
                SidebarWidget(),

                // 2. Middle Creation Studio Panel
                StudioPanel(),

                // 3. Right Workspace / Library Panel
                Expanded(
                  child: WorkspacePanel(),
                ),
              ],
            ),
          ),

          // 4. Sticky Bottom Audio Player
          BottomPlayerWidget(),
        ],
      ),
    );
  }
}
