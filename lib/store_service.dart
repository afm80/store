import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';
import 'models.dart';

class StoreService {
  /// يقرأ قائمة التطبيقات من data/apps.json في المستودع.
  /// الرقم في آخر الرابط يتغير كل دقيقة لتجنب التخزين المؤقت القديم.
  static Future<List<AppItem>> fetchApps() async {
    final stamp = DateTime.now().millisecondsSinceEpoch ~/ 60000;
    final res = await http.get(Uri.parse('${StoreConfig.appsJsonUrl}?t=$stamp'));

    if (res.statusCode == 404) return [];
    if (res.statusCode != 200) {
      throw Exception('تعذّر تحميل قائمة التطبيقات (رمز ${res.statusCode})');
    }

    final decoded = jsonDecode(utf8.decode(res.bodyBytes));
    if (decoded is! List) return [];

    final apps = decoded
        .whereType<Map<String, dynamic>>()
        .map(AppItem.fromJson)
        .where((a) =>
            a.packageName.isNotEmpty && a.name.isNotEmpty && !a.hidden)
        .toList();

    // الترتيب اليدوي من لوحة التحكم أولًا، ثم الأحدث تحديثًا.
    apps.sort((a, b) {
      final ao = a.order, bo = b.order;
      if (ao != null && bo != null && ao != bo) return ao.compareTo(bo);
      if (ao != null && bo == null) return -1;
      if (ao == null && bo != null) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return apps;
  }

  /// يقرأ الملف الشخصي للمطوّر (data/developer.json)، أو null إن لم يوجد.
  static Future<DeveloperProfile?> fetchDeveloper() async {
    try {
      final stamp = DateTime.now().millisecondsSinceEpoch ~/ 60000;
      final res =
          await http.get(Uri.parse('${StoreConfig.developerJsonUrl}?t=$stamp'));
      if (res.statusCode != 200) return null;
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      if (decoded is! Map<String, dynamic>) return null;
      final p = DeveloperProfile.fromJson(decoded);
      return p.name.isEmpty ? null : p;
    } catch (_) {
      return null;
    }
  }
}
