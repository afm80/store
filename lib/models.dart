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
  final List<String> banners; // صور بانر متعددة (اختياري)
  final String apkUrl;
  final String updatedAt;
  final int size;
  final bool featured;
  final List<String> screenshots;
  final String youtubeUrl;   // رابط فيديو يوتيوب (اختياري)

  // ─── حقول جديدة (اختيارية) لجعل التصميم يشبه Google Play ───
  final double rating;       // 0.0 إذا غير متوفر
  final int downloads;       // 0 إذا غير متوفر
  final String developer;    // اسم المطوّر
  final String ageRating;    // مثل: "+3"، "+12"، "الجميع"
  final bool hidden;         // مخفي من المتجر (من لوحة التحكم)
  final int? order;          // ترتيب العرض من لوحة التحكم

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
    this.banners = const [],
    required this.apkUrl,
    required this.updatedAt,
    required this.size,
    required this.featured,
    required this.screenshots,
    this.youtubeUrl = '',
    this.rating = 0,
    this.downloads = 0,
    this.developer = '',
    this.ageRating = '',
    this.hidden = false,
    this.order,
  });

  factory AppItem.fromJson(Map<String, dynamic> j) {
    String s(String key) => (j[key] ?? '').toString();
    final shots = j['screenshots'];
    final bans = j['banners'];
    final rawSize = j['size'];
    final rawRating = j['rating'];
    final rawDownloads = j['downloads'];
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
      banners: bans is List
          ? bans.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
          : const [],
      apkUrl: s('apkUrl'),
      updatedAt: s('updatedAt'),
      size: rawSize is num ? rawSize.toInt() : 0,
      featured: j['featured'] == true,
      screenshots: shots is List ? shots.map((e) => e.toString()).toList() : const [],
      youtubeUrl: s('youtubeUrl'),
      rating: rawRating is num ? rawRating.toDouble() : 0,
      downloads: rawDownloads is num ? rawDownloads.toInt() : 0,
      developer: s('developer'),
      ageRating: s('ageRating'),
      hidden: j['hidden'] == true,
      order: j['order'] is num ? (j['order'] as num).toInt() : null,
    );
  }

  /// معرّف فيديو يوتيوب (11 حرفًا) المستخرج من الرابط، أو '' إذا لم يوجد/غير صالح.
  String get youtubeId {
    final u = Uri.tryParse(youtubeUrl.trim());
    if (u == null) return '';
    final id = RegExp(r'^[A-Za-z0-9_-]{11}$');
    String c = '';
    if (u.host.contains('youtu.be')) {
      c = u.pathSegments.isNotEmpty ? u.pathSegments.first : '';
    } else if (u.host.contains('youtube.com') || u.host.contains('youtube-nocookie.com')) {
      c = u.queryParameters['v'] ?? '';
      if (c.isEmpty && u.pathSegments.length >= 2 &&
          ['embed', 'shorts', 'live', 'v'].contains(u.pathSegments.first)) {
        c = u.pathSegments[1];
      }
    }
    return id.hasMatch(c) ? c : '';
  }

  bool get isGame => category == 'game';

  String get iconUrl => StoreConfig.media(icon);
  String get bannerUrl => StoreConfig.media(banner);

  /// كل صور البانر (banners إن وُجدت، وإلا banner الوحيد).
  List<String> get bannerUrls {
    final list = banners.isNotEmpty
        ? banners
        : (banner.isNotEmpty ? [banner] : const <String>[]);
    return list.map(StoreConfig.media).toList();
  }
  List<String> get screenshotUrls => screenshots.map(StoreConfig.media).toList();

  String get sizeLabel {
    if (size <= 0) return '—';
    final mb = size / 1048576;
    if (mb >= 1) return '${mb.toStringAsFixed(1)} MB';
    return '${(size / 1024).toStringAsFixed(0)} KB';
  }

  /// التاريخ بصيغة yyyy-mm-dd.
  String get dateLabel => updatedAt.length >= 10 ? updatedAt.substring(0, 10) : '';

  /// صيغة عدد التحميلات (مثل Google Play: 1K+, 1M+).
  String get downloadsLabel {
    if (downloads <= 0) return '—';
    if (downloads >= 1000000) return '${(downloads / 1000000).toStringAsFixed(1)}M+';
    if (downloads >= 1000) return '${(downloads / 1000).toStringAsFixed(0)}K+';
    return '$downloads+';
  }

  /// نص التقييم (مثل "4.5")، أو "—" إذا غير متوفر.
  String get ratingLabel => rating > 0 ? rating.toStringAsFixed(1) : '—';
}


/// الملف الشخصي للمطوّر (data/developer.json) — يُدار من لوحة التحكم.
class DeveloperProfile {
  final String name;
  final String bio;
  final String avatar;
  final String cover;
  final String website;
  final String telegram;
  final String youtube;
  final String facebook;
  final String instagram;
  final String email;

  const DeveloperProfile({
    this.name = '',
    this.bio = '',
    this.avatar = '',
    this.cover = '',
    this.website = '',
    this.telegram = '',
    this.youtube = '',
    this.facebook = '',
    this.instagram = '',
    this.email = '',
  });

  factory DeveloperProfile.fromJson(Map<String, dynamic> j) {
    String s(String k) => (j[k] ?? '').toString().trim();
    return DeveloperProfile(
      name: s('name'),
      bio: s('bio'),
      avatar: s('avatar'),
      cover: s('cover'),
      website: s('website'),
      telegram: s('telegram'),
      youtube: s('youtube'),
      facebook: s('facebook'),
      instagram: s('instagram'),
      email: s('email'),
    );
  }

  String get avatarUrl => StoreConfig.media(avatar);
  String get coverUrl => StoreConfig.media(cover);

  static String _link(String v, String base) {
    if (v.isEmpty) return '';
    if (v.startsWith('http://') || v.startsWith('https://')) return v;
    return base + v.replaceFirst(RegExp(r'^@'), '');
  }

  String get websiteLink => _link(website, 'https://');
  String get telegramLink => _link(telegram, 'https://t.me/');
  String get youtubeLink => _link(youtube, 'https://');
  String get facebookLink => _link(facebook, 'https://');
  String get instagramLink => _link(instagram, 'https://instagram.com/');
  String get emailLink => email.isEmpty ? '' : 'mailto:$email';
}
