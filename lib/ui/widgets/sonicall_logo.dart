import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Apple HIG 1:1 Squircle Icon with Lightning & Headphones Motif
class SonicallLogo extends StatelessWidget {
  final double size;
  final bool isDarkSurface;
  final bool showSoundwaves;
  final VoidCallback? onTap;

  const SonicallLogo({
    super.key,
    this.size = 36,
    this.isDarkSurface = false,
    this.showSoundwaves = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Apple continuous squircle corner radius is ~22.5% of dimension
    final cornerRadius = size * 0.225;

    Widget iconBox = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(cornerRadius),
        gradient: LinearGradient(
          colors: isDarkSurface
              ? const [Color(0xFF22222B), Color(0xFF141418)]
              : const [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: isDarkSurface
            ? Border.all(
                color: AppColors.primary.withValues(alpha: 0.55),
                width: size * 0.035,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: isDarkSurface
                ? AppColors.primary.withValues(alpha: 0.2)
                : AppColors.primary.withValues(alpha: 0.38),
            blurRadius: size * 0.3,
            offset: Offset(0, size * 0.1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cornerRadius),
        child: CustomPaint(
          size: Size(size, size),
          painter: _LightningHeadphonePainter(
            isDarkSurface: isDarkSurface,
            showSoundwaves: showSoundwaves,
          ),
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: iconBox);
    }
    return iconBox;
  }
}

class _LightningHeadphonePainter extends CustomPainter {
  final bool isDarkSurface;
  final bool showSoundwaves;

  _LightningHeadphonePainter({
    required this.isDarkSurface,
    required this.showSoundwaves,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Color definitions
    final primaryColor = isDarkSurface ? const Color(0xFFFF7A1A) : Colors.white;
    final secondaryColor = isDarkSurface ? const Color(0xFFEE0979) : const Color(0xE6FFFFFF);

    // 1. Equalizer / Soundwaves on flanks (optional)
    if (showSoundwaves && w >= 32) {
      final wavePaint = Paint()
        ..color = isDarkSurface
            ? const Color(0xB3FF6A00)
            : const Color(0xBFFFFFFF)
        ..style = PaintingStyle.fill;

      final barW = w * 0.022;
      final waveR = barW / 2;

      // Left bars
      _drawBar(canvas, wavePaint, w * 0.15, h * 0.5, barW, h * 0.08, waveR);
      _drawBar(canvas, wavePaint, w * 0.20, h * 0.5, barW, h * 0.18, waveR);
      _drawBar(canvas, wavePaint, w * 0.25, h * 0.5, barW, h * 0.12, waveR);

      // Right bars
      _drawBar(canvas, wavePaint, w * 0.75, h * 0.5, barW, h * 0.12, waveR);
      _drawBar(canvas, wavePaint, w * 0.80, h * 0.5, barW, h * 0.18, waveR);
      _drawBar(canvas, wavePaint, w * 0.85, h * 0.5, barW, h * 0.08, waveR);
    }

    // 2. Headphone Headband Arch
    final headbandPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.065
      ..strokeCap = StrokeCap.round;

    final headArc = Path()
      ..moveTo(w * 0.34, h * 0.52)
      ..cubicTo(
        w * 0.34, h * 0.26,
        w * 0.66, h * 0.26,
        w * 0.66, h * 0.52,
      );
    canvas.drawPath(headArc, headbandPaint);

    // 3. Headphone Ear Cups
    final earCupPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    final cupW = w * 0.09;
    final cupH = h * 0.20;
    final cupRadius = Radius.circular(cupW * 0.5);

    // Left Cup
    final leftCupRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w * 0.32, h * 0.52), width: cupW, height: cupH),
      cupRadius,
    );
    canvas.drawRRect(leftCupRect, earCupPaint);

    // Right Cup
    final rightCupRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w * 0.68, h * 0.52), width: cupW, height: cupH),
      cupRadius,
    );
    canvas.drawRRect(rightCupRect, earCupPaint);

    // Ear cup accent strip
    if (w >= 36) {
      final innerCupPaint = Paint()
        ..color = isDarkSurface ? const Color(0xFFEE0979) : const Color(0xCCFF6A00)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(w * 0.345, h * 0.52), width: cupW * 0.3, height: cupH * 0.7),
          Radius.circular(cupW * 0.15),
        ),
        innerCupPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(w * 0.655, h * 0.52), width: cupW * 0.3, height: cupH * 0.7),
          Radius.circular(cupW * 0.15),
        ),
        innerCupPaint,
      );
    }

    // 4. Central Dynamic Lightning Bolt
    final boltPaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.fill;

    final boltPath = Path();
    boltPath.moveTo(w * 0.53, h * 0.28); // top point
    boltPath.lineTo(w * 0.42, h * 0.52); // left jog
    boltPath.lineTo(w * 0.50, h * 0.52); // horizontal in
    boltPath.lineTo(w * 0.46, h * 0.74); // bottom sharp point
    boltPath.lineTo(w * 0.60, h * 0.48); // right jog
    boltPath.lineTo(w * 0.52, h * 0.48); // horizontal in
    boltPath.close();

    canvas.drawPath(boltPath, boltPaint);

    // Inner bright core highlight
    if (w >= 36) {
      final corePaint = Paint()
        ..color = const Color(0xE6FFFFFF)
        ..style = PaintingStyle.fill;

      final corePath = Path();
      corePath.moveTo(w * 0.525, h * 0.32);
      corePath.lineTo(w * 0.445, h * 0.51);
      corePath.lineTo(w * 0.50, h * 0.51);
      corePath.lineTo(w * 0.48, h * 0.68);
      corePath.lineTo(w * 0.57, h * 0.49);
      corePath.lineTo(w * 0.52, h * 0.49);
      corePath.close();
      canvas.drawPath(corePath, corePaint);
    }
  }

  void _drawBar(
    Canvas canvas,
    Paint paint,
    double cx,
    double cy,
    double width,
    double height,
    double radius,
  ) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: width, height: height),
        Radius.circular(radius),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _LightningHeadphonePainter oldDelegate) {
    return oldDelegate.isDarkSurface != isDarkSurface ||
        oldDelegate.showSoundwaves != showSoundwaves;
  }
}
