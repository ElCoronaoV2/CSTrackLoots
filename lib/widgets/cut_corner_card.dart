import 'package:flutter/material.dart';

/// Genera un path rectangular con las 4 esquinas cortadas en diagonal,
/// estilo "tech frame" gamer/CS2.
Path buildCutCornerPath(Size size, {double cut = 14.0}) {
  final path = Path();
  final w = size.width;
  final h = size.height;
  final c = cut;

  path.moveTo(c, 0);
  path.lineTo(w - c, 0);
  path.lineTo(w, c);
  path.lineTo(w, h - c);
  path.lineTo(w - c, h);
  path.lineTo(c, h);
  path.lineTo(0, h - c);
  path.lineTo(0, c);
  path.close();
  return path;
}

/// Tarjeta con esquinas angulares y borde naranja/dorado.
///
/// Implementación: `CustomPaint(child: ...)` toma el tamaño natural del
/// child y pinta fondo + borde con un path angular en su `RepaintBoundary`.
///
/// Esta forma es SEGURA dentro de `ListView` y otros contextos de altura
/// no acotada (a diferencia de `Stack(fit: StackFit.expand)`), y permite
/// que los gestos (`InkWell` externo, `GestureDetector`, etc.) lleguen al
/// contenido sin necesidad de `ClipPath` ni `Material.shape` (que en
/// versiones recientes de Flutter interceptan hit-tests en las zonas de
/// las esquinas).
class CutCornerCard extends StatelessWidget {
  const CutCornerCard({
    super.key,
    required this.child,
    this.color,
    this.borderColor,
    this.borderWidth = 1.4,
    this.cut = 14.0,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;
  final double cut;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final fill = color ?? const Color(0xFF14171C);
    final border = borderColor ?? const Color(0xFFF59E0B).withValues(alpha: 0.55);

    return CustomPaint(
      // CustomPaint se auto-dimensiona al tamaño natural del child,
      // lo que evita el crash "BoxConstraints forces an infinite height"
      // que se producía al usar `Stack(fit: StackFit.expand)` dentro de
      // un ListView.
      painter: _CutCornerCardPainter(
        fillColor: fill,
        borderColor: border,
        borderWidth: borderWidth,
        cut: cut,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _CutCornerCardPainter extends CustomPainter {
  _CutCornerCardPainter({
    required this.fillColor,
    required this.borderColor,
    required this.borderWidth,
    required this.cut,
  });

  final Color fillColor;
  final Color borderColor;
  final double borderWidth;
  final double cut;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final path = buildCutCornerPath(size, cut: cut);
    canvas.drawPath(path, Paint()..color = fillColor);
    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth,
    );
  }

  @override
  bool shouldRepaint(covariant _CutCornerCardPainter old) =>
      old.fillColor != fillColor ||
      old.borderColor != borderColor ||
      old.borderWidth != borderWidth ||
      old.cut != cut;
}
