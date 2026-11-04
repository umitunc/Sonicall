import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import '../sidebar/sidebar_widget.dart';
import '../studio/studio_panel.dart';
import '../studio/instrument_transform_panel.dart';
import '../studio/vocal_mastering_panel.dart';
import '../workspace/workspace_panel.dart';
import '../player/bottom_player_widget.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final activeTab = context.select<AppStateProvider, String>((p) => p.activeTab);

    final panelIndex = activeTab == 'vocal_master'
        ? 2
        : (activeTab == 'instrument' ? 1 : 0);

    return Scaffold(
      body: Column(
        children: [
          // 3-Panel Main Area
          Expanded(
            child: Row(
              children: [
                // 1. Left Navigation Sidebar
                const SidebarWidget(),

                // 2. Middle Creation Studio, Instrument or Vocal Master Panel
                IndexedStack(
                  index: panelIndex,
                  children: const [
                    StudioPanel(),
                    InstrumentTransformPanel(),
                    VocalMasteringPanel(),
                  ],
                ),

                // 3. Right Workspace / Library Panel
                const Expanded(
                  child: WorkspacePanel(),
                ),
              ],
            ),
          ),

          // 4. Sticky Bottom Audio Player
          const BottomPlayerWidget(),
        ],
      ),
    );
  }
}
