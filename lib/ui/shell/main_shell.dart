import 'package:flutter/material.dart';
import '../sidebar/sidebar_widget.dart';
import '../studio/studio_panel.dart';
import '../workspace/workspace_panel.dart';
import '../player/bottom_player_widget.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

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
