/// إعدادات المتجر.
///
/// عند نشر المتجر على GitHub Pages يتم اكتشاف اسم المستخدم واسم المستودع
/// تلقائيًا من رابط الصفحة، فلا تحتاج لتعديل شيء.
/// القيم الثابتة بالأسفل تُستخدم فقط عند التشغيل محليًا أو كتطبيق أندرويد.
class StoreConfig {
  static const String _owner = 'afm80';
  static const String _repo = 'store';
  static const String branch = 'main';

  /// رابط المتجر (يُستخدم في مشاركة رابط التطبيق).
  static const String storeUrl = 'https://alfahamstore.web.app';

  /// رابط مباشر لصفحة تطبيق معيّن.
  static String shareUrl(String packageName) =>
      '$storeUrl/?app=${Uri.encodeQueryComponent(packageName)}';

  /// اسم الحزمة القادم من الرابط (?app=...) أو '' إذا لم يوجد.
  static String get sharedPackage => Uri.base.queryParameters['app'] ?? '';

  /// مفاتيح التفعيل: غيّرها إلى true عند الجاهزية.
  static const bool showDownloads = false; // عدد التحميلات
  static const bool showRating = false; // التقييم

  static String get owner {
    final host = Uri.base.host;
    if (host.endsWith('.github.io')) return host.split('.').first;
    return _owner;
  }

  static String get repo {
    final host = Uri.base.host;
    if (host.endsWith('.github.io')) {
      final segments = Uri.base.pathSegments.where((s) => s.isNotEmpty);
      if (segments.isNotEmpty) return segments.first;
    }
    return _repo;
  }

  /// رابط ملف داخل المستودع (قراءة مباشرة بدون إعادة بناء الموقع).
  static String raw(String path) =>
      'https://raw.githubusercontent.com/$owner/$repo/$branch/$path';

  static String get appsJsonUrl => raw('data/apps.json');

  /// يحوّل مسار صورة محفوظ في apps.json إلى رابط كامل.
  static String media(String pathOrUrl) {
    if (pathOrUrl.isEmpty) return '';
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return pathOrUrl;
    }
    return raw(pathOrUrl);
  }
}
