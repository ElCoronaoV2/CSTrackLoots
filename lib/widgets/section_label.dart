import 'package:flutter/material.dart';

/// Etiqueta de sección estilo gamer: barra naranja diagonal + texto blanco bold.
///
///   "/" INVENTARIO GENERAL
///   "/" MIS CUENTAS
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Slash naranja estilizado (dos barras diagonales finas).
        SizedBox(
          width: 14,
          height: 22,
          child: CustomPaint(painter: _SlashPainter()),
        ),
        const SizedBox(width: 6),
        Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.6,
            color: Colors.white,
            fontSize: 15,
          ),
        ),
        if (trailing != null) ...[
          const Spacer(),
          trailing!,
        ],
      ],
    );
  }
}

class _SlashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(
      Offset(size.width * 0.1, size.height),
      Offset(size.width, size.height * 0.05),
      paint,
    );
    // Sombra naranja sutil.
    final glow = Paint()
      ..color = const Color(0xFFF59E0B).withValues(alpha: 0.4)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.square
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawLine(
      Offset(size.width * 0.1, size.height),
      Offset(size.width, size.height * 0.05),
      glow,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
