import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/legacy.dart';

class WindowControlsWidget extends StatefulWidget {
  final double height;

  const WindowControlsWidget({
    super.key,
    this.height = 48,
  });

  @override
  State<WindowControlsWidget> createState() => _WindowControlsWidgetState();
}

class _WindowControlsWidgetState extends State<WindowControlsWidget> with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      windowManager.addListener(this);
      _checkMaximized();
    }
  }

  Future<void> _checkMaximized() async {
    try {
      final isMax = await windowManager.isMaximized();
      if (mounted) setState(() => _isMaximized = isMax);
    } catch (_) {}
  }

  @override
  void dispose() {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  void onWindowMaximize() {
    if (mounted) setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    if (mounted) setState(() => _isMaximized = false);
  }

  @override
  void onWindowRestore() {
    if (mounted) setState(() => _isMaximized = false);
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || !(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white70 : Colors.black87;
    final hoverColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.06);

    return SizedBox(
      height: widget.height,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Minimize Button
          _WindowButton(
            tooltip: 'Simge Durumuna Küçült',
            hoverColor: hoverColor,
            onPressed: () => windowManager.minimize(),
            child: Icon(Icons.remove_rounded, size: 16, color: iconColor),
          ),

          // Maximize / Restore Button
          _WindowButton(
            tooltip: _isMaximized ? 'Önceki Boyut' : 'Ekranı Kapla',
            hoverColor: hoverColor,
            onPressed: () async {
              if (await windowManager.isMaximized()) {
                await windowManager.unmaximize();
              } else {
                await windowManager.maximize();
              }
            },
            child: Icon(
              _isMaximized ? Icons.filter_none_rounded : Icons.crop_square_rounded,
              size: _isMaximized ? 13 : 15,
              color: iconColor,
            ),
          ),

          // Close Button
          _WindowButton(
            tooltip: 'Kapat',
            hoverColor: const Color(0xFFE81123),
            hoverIconColor: Colors.white,
            onPressed: () => windowManager.close(),
            child: Icon(Icons.close_rounded, size: 16, color: iconColor),
          ),
        ],
      ),
    );
  }
}

class _WindowButton extends StatefulWidget {
  final String tooltip;
  final Widget child;
  final Color hoverColor;
  final Color? hoverIconColor;
  final VoidCallback onPressed;

  const _WindowButton({
    required this.tooltip,
    required this.child,
    required this.hoverColor,
    this.hoverIconColor,
    required this.onPressed,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 600),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          child: Container(
            width: 46,
            color: _isHovered ? widget.hoverColor : Colors.transparent,
            alignment: Alignment.center,
            child: widget.hoverIconColor != null && _isHovered
                ? IconTheme(
                    data: IconThemeData(color: widget.hoverIconColor),
                    child: widget.child,
                  )
                : widget.child,
          ),
        ),
      ),
    );
  }
}

