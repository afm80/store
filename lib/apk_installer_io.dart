// أندرويد: تنزيل الـ APK داخل المتجر مع شريط تقدّم ثم فتح مثبّت النظام.
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class DownloadCancelled implements Exception {}

class ChecksumMismatch implements Exception {}

bool get supportsInAppInstall => Platform.isAndroid;

/// ينزّل الملف ويعيد مساره. يتحقق من بصمة SHA-256 إن كانت متوفرة.
Future<String> downloadApk(
  String url, {
  required String fileName,
  String sha256Hex = '',
  int expectedSize = 0,
  required void Function(double) onProgress,
  required bool Function() isCancelled,
}) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$fileName');
  if (await file.exists()) await file.delete();

  final client = http.Client();
  IOSink? sink;
  try {
    final res = await client.send(http.Request('GET', Uri.parse(url)));
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}');
    }
    var total = res.contentLength ?? 0;
    if (total <= 0) total = expectedSize; // الحجم المسجّل إن لم يرسله الخادم
    var received = 0;
    sink = file.openWrite();
    await for (final chunk in res.stream) {
      if (isCancelled()) throw DownloadCancelled();
      sink.add(chunk);
      received += chunk.length;
      if (total > 0) onProgress((received / total).clamp(0.0, 1.0));
    }
    await sink.close();
    sink = null;

    if (sha256Hex.isNotEmpty) {
      final d = await sha256.bind(file.openRead()).first;
      if (d.toString().toLowerCase() != sha256Hex.trim().toLowerCase()) {
        throw ChecksumMismatch();
      }
    }
    return file.path;
  } catch (_) {
    try {
      await sink?.close();
    } catch (_) {}
    if (await file.exists()) await file.delete();
    rethrow;
  } finally {
    client.close();
  }
}

/// يفتح مثبّت أندرويد للملف.
Future<bool> installApk(String path) async {
  final r = await OpenFilex.open(
    path,
    type: 'application/vnd.android.package-archive',
  );
  return r.type == ResultType.done;
}
