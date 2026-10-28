import 'config.dart';

class AppItem {
  final String packageName;
  final String name;
  final String category; // app | game
  final String genre;
  final String shortDescription;
  final String longDescription;
  final String version;
  final String whatsNew;
  final String sha256;
  final String icon;
  final String banner;
  final String apkUrl;
  final String updatedAt;
  final int size;
  final bool featured;
  final List<String> screenshots;

  const AppItem({
    required this.packageName,
    required this.name,
    required this.category,
    required this.genre,
    required this.shortDescription,
    required this.longDescription,
    required this.version,
    required this.whatsNew,
    required this.sha256,
    required this.icon,
    required this.banner,
    required this.apkUrl,
    required this.updatedAt,
    required this.size,
    required this.featured,
    required this.screenshots,
  });

  factory AppItem.fromJson(Map<String, dynamic> j) {
    String s(String key) => (j[key] ?? '').toString();
    final shots = j['screenshots'];
    final rawSize = j['size'];
    return AppItem(
      packageName: s('packageName'),
      name: s('name'),
      category: s('category').isEmpty ? 'app' : s('category'),
      genre: s('genre'),
      shortDescription: s('shortDescription'),
      longDescription: s('longDescription'),
      version: s('version'),
      whatsNew: s('whatsNew'),
      sha256: s('sha256'),
      icon: s('icon'),
      banner: s('banner'),
      apkUrl: s('apkUrl'),
      updatedAt: s('updatedAt'),
      size: rawSize is num ? rawSize.toInt() : 0,
      featured: j['featured'] == true,
      screenshots: shots is List ? shots.map((e) => e.toString()).toList() : const [],
    );
  }

  bool get isGame => category == 'game';

  String get iconUrl => StoreConfig.media(icon);
  String get bannerUrl => StoreConfig.media(banner);
  List<String> get screenshotUrls => screenshots.map(StoreConfig.media).toList();

  String get sizeLabel {
    if (size <= 0) return '—';
    final mb = size / 1048576;
    if (mb >= 1) return '${mb.toStringAsFixed(1)} MB';
    return '${(size / 1024).toStringAsFixed(0)} KB';
  }

  /// التاريخ بصيغة yyyy-mm-dd.
  String get dateLabel => updatedAt.length >= 10 ? updatedAt.substring(0, 10) : '';
}
