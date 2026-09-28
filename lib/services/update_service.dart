import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

/// Info de una versión más nueva publicada como GitHub Release.
class UpdateInfo {
  final int buildNumber;
  final String label;
  final String downloadUrl;

  const UpdateInfo({
    required this.buildNumber,
    required this.label,
    required this.downloadUrl,
  });
}

/// Comprueba si hay una versión del APK más reciente que la instalada,
/// publicada como GitHub Release (ver .github/workflows/build-apk.yml),
/// y permite descargarla e instalarla sobre la app actual sin perder datos
/// (misma clave de firma en todos los builds de CI).
class UpdateService {
  UpdateService()
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
          headers: const {'Accept': 'application/vnd.github+json'},
        ));

  final Dio _dio;

  static const _releasesUrl =
      'https://api.github.com/repos/ElCoronaoV2/CSTrackLoots/releases/latest';

  /// Devuelve la última versión disponible si es más nueva que la instalada,
  /// o `null` si ya está al día o la consulta falla (sin conexión, rate
  /// limit de GitHub, etc. — se ignora en silencio, nunca rompe el arranque).
  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

      final response =
          await _dio.get<Map<String, dynamic>>(_releasesUrl);
      final data = response.data;
      if (data == null) return null;

      final latestBuild = int.tryParse(data['tag_name'] as String? ?? '');
      if (latestBuild == null || latestBuild <= currentBuild) return null;

      String? downloadUrl;
      for (final asset in (data['assets'] as List? ?? const [])) {
        final map = asset as Map<String, dynamic>;
        final name = map['name'] as String?;
        if (name != null && name.endsWith('.apk')) {
          downloadUrl = map['browser_download_url'] as String?;
          break;
        }
      }
      if (downloadUrl == null) return null;

      return UpdateInfo(
        buildNumber: latestBuild,
        label: (data['name'] as String?) ?? 'build $latestBuild',
        downloadUrl: downloadUrl,
      );
    } catch (_) {
      return null;
    }
  }

  /// Descarga el APK a un archivo temporal y abre el instalador del sistema.
  /// [onProgress] recibe un valor entre 0 y 1.
  Future<void> downloadAndInstall(
    String url, {
    void Function(double progress)? onProgress,
  }) async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/cs2_tracker_update.apk';
    await _dio.download(
      url,
      path,
      onReceiveProgress: (received, total) {
        if (total > 0) onProgress?.call(received / total);
      },
    );
    await OpenFile.open(path);
  }
}
