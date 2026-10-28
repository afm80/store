// نسخة الويب: لا يوجد تنزيل/تثبيت داخل المتجر (يُفتح الرابط في المتصفح).

class DownloadCancelled implements Exception {}

class ChecksumMismatch implements Exception {}

bool get supportsInAppInstall => false;

Future<String> downloadApk(
  String url, {
  required String fileName,
  String sha256Hex = '',
  required void Function(double) onProgress,
  required bool Function() isCancelled,
}) async =>
    throw UnsupportedError('in-app install is Android only');

Future<bool> installApk(String path) async => false;
