import 'package:flutter/material.dart';

/// The UniPal mark: a U of two halves. Same geometry as unipal-brand/scripts/logos.mjs (64x64 box,
/// stroke 12). The left half uses [color] (ink, or sand on dark), the right half the brand accent.
class Mark extends StatelessWidget {
  const Mark({super.key, this.size = 40, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CustomPaint(
      size: Size.square(size),
      painter: _MarkPainter(left: color ?? scheme.onSurface, right: scheme.secondary),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter({required this.left, required this.right});

  final Color left;
  final Color right;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 64);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    final arc = Rect.fromCircle(center: const Offset(32, 33), radius: 15);
    canvas.drawPath(
      Path()
        ..moveTo(17, 8)
        ..lineTo(17, 33)
        ..arcTo(arc, 3.14159265, -3.14159265 / 2, false),
      stroke..color = left,
    );
    canvas.drawPath(
      Path()
        ..moveTo(32, 48)
        ..arcTo(arc, 3.14159265 / 2, -3.14159265 / 2, false)
        ..lineTo(47, 8),
      stroke..color = right,
    );
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.left != left || old.right != right;
}
