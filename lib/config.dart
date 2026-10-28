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
      '$storeUrl/#/app/${Uri.encodeComponent(packageName)}';

  /// مسار الصفحة داخل الرابط (بعد #)، مثل: /games أو /app/اسم.الحزمة
  static Uri? _fragmentUri(Uri u) {
    final f = u.fragment;
    if (f.isEmpty) return null;
    return Uri.tryParse(f.startsWith('/') ? f : '/$f');
  }

  /// يستخرج اسم الحزمة من رابط (يدعم #/app/pkg و ?app=pkg القديم).
  static String packageFromUri(Uri u) {
    final fu = _fragmentUri(u);
    if (fu != null) {
      final segs = fu.pathSegments;
      if (segs.length >= 2 && segs.first == 'app') return segs[1];
      return fu.queryParameters['app'] ?? '';
    }
    return u.queryParameters['app'] ?? '';
  }

  /// اسم الحزمة القادم من رابط الصفحة الحالية أو '' إذا لم يوجد.
  static String get sharedPackage => packageFromUri(Uri.base);

  /// مسارات التبويبات الرئيسية (للتحديث على نفس التبويب).
  static const List<String> tabPaths = ['/', '/apps', '/games', '/search'];

  static int get initialTab {
    final fu = _fragmentUri(Uri.base);
    if (fu == null) return 0;
    final i = tabPaths.indexOf(fu.path);
    return i < 0 ? 0 : i;
  }

  /// مفاتيح التفعيل: غيّرها إلى true عند الجاهزية.
  static const bool showDownloads = true; // عدد التحميلات
  static const bool showRating = true; // التقييم

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
