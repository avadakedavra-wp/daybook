import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A hand-drawn sunrise printed on the cover of the journal.
class Sunrise extends CustomPainter {
  const Sunrise();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 180, size.height / 130);
    final ink = Paint()..color = const Color(0xff254b3c);
    final line = Paint()
      ..color = ink.color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const center = Offset(103, 52);
    canvas.drawCircle(center, 24, Paint()..color = const Color(0xffffb866));
    canvas.drawCircle(center, 24, line);
    for (int i = 0; i < 12; i++) {
      final angle = i * math.pi / 6;
      final unit = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(center + unit * 30, center + unit * 35, line);
    }
    for (final x in [97.0, 110.0]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, 51), width: 2.8, height: 4),
        ink,
      );
    }
    canvas.drawPath(
      Path()
        ..moveTo(99, 59)
        ..quadraticBezierTo(104, 64, 109, 58),
      line,
    );
    final hill = Path()
      ..moveTo(-12, 116)
      ..quadraticBezierTo(50, 54, 103, 83)
      ..quadraticBezierTo(143, 99, 190, 64)
      ..lineTo(190, 150)
      ..lineTo(-12, 150)
      ..close();
    canvas.drawPath(hill, Paint()..color = const Color(0xffa9be76));
    canvas.drawPath(hill, line);
    final front = Path()
      ..moveTo(45, 138)
      ..quadraticBezierTo(112, 74, 187, 85)
      ..lineTo(187, 140)
      ..close();
    canvas.drawPath(front, Paint()..color = const Color(0xff6e9567));
    canvas.drawPath(front, line);
    canvas.drawPath(
      Path()
        ..moveTo(-4, 126)
        ..quadraticBezierTo(34, 85, 72, 86),
      line,
    );
    canvas.drawPath(
      Path()
        ..moveTo(7, 133)
        ..quadraticBezierTo(45, 92, 77, 94),
      line,
    );
    for (final p in [
      const Offset(132, 108),
      const Offset(150, 101),
      const Offset(165, 117),
    ]) {
      canvas.drawLine(p, p + const Offset(-3, -5), line);
      canvas.drawLine(p, p + const Offset(2, -7), line);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(Sunrise oldDelegate) => false;
}
