import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';
import 'models.dart';

class StoreService {
  /// يقرأ قائمة التطبيقات من data/apps.json في المستودع.
  /// الرقم في آخر الرابط يتغير كل دقيقة لتجنب التخزين المؤقت القديم.
  static Future<List<AppItem>> fetchApps() async {
    final countsFuture = fetchDownloadCounts();
    final stamp = DateTime.now().millisecondsSinceEpoch ~/ 60000;
    final res = await http.get(Uri.parse('${StoreConfig.appsJsonUrl}?t=$stamp'));

    if (res.statusCode == 404) return [];
    if (res.statusCode != 200) {
      throw Exception('تعذّر تحميل قائمة التطبيقات (رمز ${res.statusCode})');
    }

    final decoded = jsonDecode(utf8.decode(res.bodyBytes));
    if (decoded is! List) return [];

    final counts = await countsFuture;
    final apps = decoded
        .whereType<Map<String, dynamic>>()
        .map((j) => AppItem.fromJson(j,
            real: counts[(j['packageName'] ?? '').toString()] ?? 0))
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


  /// يقرأ عدّاد التحميلات الحقيقي لكل التطبيقات (مجموعة downloads في Firestore).
  static Future<Map<String, int>> fetchDownloadCounts() async {
    final out = <String, int>{};
    try {
      String? token;
      for (var i = 0; i < 10; i++) {
        final url = StoreConfig.downloadsListUrl +
            (token == null ? '' : '&pageToken=${Uri.encodeComponent(token)}');
        final res =
            await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
        if (res.statusCode != 200) break;
        final j = jsonDecode(utf8.decode(res.bodyBytes));
        if (j is! Map) break;
        final docs = j['documents'];
        if (docs is List) {
          for (final d in docs) {
            if (d is! Map) continue;
            final id = Uri.decodeComponent(d['name'].toString().split('/').last);
            final f = d['fields'];
            final c = (f is Map && f['count'] is Map)
                ? (f['count'] as Map)['integerValue']
                : null;
            final n = int.tryParse('${c ?? ''}');
            if (n != null) out[id] = n;
          }
        }
        token = j['nextPageToken'] as String?;
        if (token == null || token.isEmpty) break;
      }
    } catch (_) {}
    return out;
  }

  static final Set<String> _counted = {};

  /// يزيد عدّاد التحميلات بمقدار 1 (مرة واحدة لكل تطبيق/إصدار في الجلسة الواحدة).
  static Future<void> countDownload(String pkg, String version) async {
    final key = '$pkg@$version';
    if (_counted.contains(key)) return;
    if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,150}$').hasMatch(pkg)) return;
    _counted.add(key);
    try {
      await http
          .post(
            Uri.parse(StoreConfig.commitUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'writes': [
                {
                  'transform': {
                    'document': StoreConfig.downloadDocPath(pkg),
                    'fieldTransforms': [
                      {
                        'fieldPath': 'count',
                        'increment': {'integerValue': '1'}
                      }
                    ]
                  }
                }
              ]
            }),
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      _counted.remove(key);
    }
  }

  /// يقرأ الملف الشخصي للمطوّر (data/developer.json)، أو null إن لم يوجد.
  /// [name] اختياري: إن كان مطورًا إضافيًا يُقرأ ملفه من data/developers.json.
  static Future<DeveloperProfile?> fetchDeveloper({String? name}) async {
    try {
      final wanted = (name ?? '').trim();
      if (wanted.isNotEmpty) {
        final main = await _fetchMainDeveloper();
        if (main != null && main.name == wanted) return main;
        final extra = await _fetchExtraDeveloper(wanted);
        if (extra != null) return extra;
        return main != null && main.name == wanted
            ? main
            : DeveloperProfile(name: wanted);
      }
      return await _fetchMainDeveloper();
    } catch (_) {
      return null;
    }
  }

  static Future<DeveloperProfile?> _fetchExtraDeveloper(String name) async {
    try {
      final stamp = DateTime.now().millisecondsSinceEpoch ~/ 60000;
      final res = await http
          .get(Uri.parse('${StoreConfig.developersJsonUrl}?t=$stamp'));
      if (res.statusCode != 200) return null;
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      if (decoded is! List) return null;
      for (final e in decoded.whereType<Map<String, dynamic>>()) {
        final p = DeveloperProfile.fromJson(e);
        if (p.name == name) return p;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<DeveloperProfile?> _fetchMainDeveloper() async {
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

  /// يقرأ عناصر القائمة الجانبية (data/menu.json). إن لم يوجد الملف تُستخدم الافتراضية.
  static Future<List<SideMenuItem>> fetchMenu() async {
    try {
      final stamp = DateTime.now().millisecondsSinceEpoch ~/ 60000;
      final res =
          await http.get(Uri.parse('${StoreConfig.menuJsonUrl}?t=$stamp'));
      if (res.statusCode != 200) return SideMenuItem.defaults;
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      if (decoded is! List) return SideMenuItem.defaults;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(SideMenuItem.fromJson)
          .where((m) => m.title.isNotEmpty && (m.url.isNotEmpty || m.text.isNotEmpty))
          .toList();
    } catch (_) {
      return SideMenuItem.defaults;
    }
  }
}
