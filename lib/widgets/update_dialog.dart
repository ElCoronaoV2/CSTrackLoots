import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/services_providers.dart';
import '../services/update_service.dart';
import '../theme/app_theme.dart';

/// Muestra el diálogo de "nueva versión disponible" y gestiona la descarga
/// e instalación (o el "ahora no" para quedarse en la versión actual).
void showUpdateDialog(BuildContext context, UpdateInfo info) {
  showDialog<void>(
    context: context,
    builder: (_) => _UpdateDialog(info: info),
  );
}

class _UpdateDialog extends ConsumerStatefulWidget {
  const _UpdateDialog({required this.info});

  final UpdateInfo info;

  @override
  ConsumerState<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends ConsumerState<_UpdateDialog> {
  double? _progress;
  String? _error;

  bool get _downloading => _progress != null;

  Future<void> _download() async {
    setState(() {
      _progress = 0;
      _error = null;
    });
    try {
      await ref.read(updateServiceProvider).downloadAndInstall(
            widget.info.downloadUrl,
            onProgress: (p) {
              if (mounted) setState(() => _progress = p);
            },
          );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _progress = null;
        _error =
            'No se pudo descargar la actualización. Inténtalo de nuevo más tarde.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva versión disponible'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.info.label, style: const TextStyle(color: Colors.white70)),
          if (_downloading) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _progress! > 0 ? _progress : null,
              color: AppTheme.csOrange,
              backgroundColor: AppTheme.borderStrong,
            ),
            const SizedBox(height: 8),
            Text(
              _progress! > 0
                  ? '${(_progress! * 100).toStringAsFixed(0)}%'
                  : 'Descargando…',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppTheme.csRed)),
          ],
        ],
      ),
      actions: _downloading
          ? null
          : [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Ahora no'),
              ),
              FilledButton(
                onPressed: _download,
                child: const Text('Actualizar'),
              ),
            ],
    );
  }
}
