import 'package:flutter/material.dart';

/// Fondo decorativo del Scaffold: gradiente lineal diagonal muy sutil
/// estilo gamer. Se aplica como `decoration` de un `DecoratedBox` para no
/// añadir capas que intercepten gestos.
class BackgroundPattern extends StatelessWidget {
  const BackgroundPattern({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B0E12),
            Color(0xFF10141A),
            Color(0xFF0B0E12),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: child,
    );
  }
}
