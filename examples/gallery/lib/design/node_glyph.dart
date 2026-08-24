import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// One icon in the set, expressed the way it was designed: circles for nodes,
/// lines for edges. Dashed strokes mean the thing is generated, replaced or
/// torn down.
///
/// Built as two paths rather than a list of shapes because Flutter has no dash
/// support on a `Paint` — the dashed path is re-cut through [_dash] at paint
/// time, and cutting one path is cheaper than cutting many.
@immutable
class NodeGlyph {
  const NodeGlyph({required this.solid, required this.dashed});

  final Path solid;
  final Path dashed;
}

/// Draws on a 24×24 grid; [NodeGlyphIcon] scales it to whatever size it is given.
class GlyphBuilder {
  final Path _solid = Path();
  final Path _dashed = Path();

  Path _pick({required bool dashed}) => dashed ? _dashed : _solid;

  void node(double x, double y, {double r = 2.1, bool dashed = false}) {
    _pick(dashed: dashed)
        .addOval(Rect.fromCircle(center: Offset(x, y), radius: r));
  }

  void edge(double x1, double y1, double x2, double y2, {bool dashed = false}) {
    _pick(dashed: dashed)
      ..moveTo(x1, y1)
      ..lineTo(x2, y2);
  }

  void polyline(List<Offset> points, {bool dashed = false}) {
    final path = _pick(dashed: dashed)
      ..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
  }

  void arc(double cx, double cy, double r, double startDeg, double sweepDeg) {
    _solid.addArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      startDeg * math.pi / 180,
      sweepDeg * math.pi / 180,
    );
  }

  void curve(Offset from, Offset control, Offset to) {
    _solid
      ..moveTo(from.dx, from.dy)
      ..quadraticBezierTo(control.dx, control.dy, to.dx, to.dy);
  }

  void box(double x, double y, double w, double h, {bool dashed = false}) {
    _pick(dashed: dashed).addRect(Rect.fromLTWH(x, y, w, h));
  }

  NodeGlyph build() => NodeGlyph(solid: _solid, dashed: _dashed);
}

class NodeGlyphIcon extends StatelessWidget {
  const NodeGlyphIcon({
    required this.glyph,
    required this.color,
    this.size = 24,
    this.strokeWidth = 1.6,
    super.key,
  });

  final NodeGlyph glyph;
  final Color color;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: _GlyphPainter(
        glyph: glyph,
        color: color,
        strokeWidth: strokeWidth,
      ),
    ),
  );
}

class _GlyphPainter extends CustomPainter {
  const _GlyphPainter({
    required this.glyph,
    required this.color,
    required this.strokeWidth,
  });

  final NodeGlyph glyph;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 24;
    canvas
      ..save()
      ..scale(scale);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      // Divided by the scale so the stroke stays 1.6 grid units at any size,
      // rather than thickening with the icon.
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas
      ..drawPath(glyph.solid, paint)
      ..drawPath(_dash(glyph.dashed), paint)
      ..restore();
  }

  /// Flutter paints no dashes, so the path is re-cut into on/off runs.
  static Path _dash(Path source, {double on = 2.5, double off = 2.3}) {
    final result = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      var draw = true;
      while (distance < metric.length) {
        final step = draw ? on : off;
        final next = math.min(distance + step, metric.length);
        if (draw) {
          result.addPath(metric.extractPath(distance, next), Offset.zero);
        }
        distance = next;
        draw = !draw;
      }
    }
    return result;
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.color != color ||
      old.glyph != glyph ||
      old.strokeWidth != strokeWidth;
}
