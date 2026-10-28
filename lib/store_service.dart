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
        .where((a) => a.packageName.isNotEmpty && a.name.isNotEmpty)
        .toList();

    apps.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return apps;
  }
}
