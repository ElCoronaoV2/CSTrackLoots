import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/services_providers.dart';
import '../theme/app_theme.dart';

/// Aviso compacto que aparece cuando la última consulta a Steam Market
/// falló (sin red, timeout o rate-limit sostenido), para dejar claro que
/// los precios mostrados vienen de caché y no son en tiempo real.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final market = ref.watch(steamMarketServiceProvider);
    return ValueListenableBuilder<bool>(
      valueListenable: market.offline,
      builder: (context, isOffline, _) {
        if (!isOffline) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.csRed.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.csRed.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.cloud_off, size: 18, color: AppTheme.csRed),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Sin conexión con Steam ahora mismo: mostrando precios en caché, puede que no estén actualizados.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
