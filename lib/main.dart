import 'dart:async';
import 'dart:ui' show PointerDeviceKind;

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import 'apk_installer_stub.dart'
    if (dart.library.io) 'apk_installer_io.dart';
import 'config.dart';
import 'models.dart';
import 'store_service.dart';

// ═══════════════════════════════════════════════════════════════
// ثوابت الهوية البصرية
// ═══════════════════════════════════════════════════════════════
const Color kBrand = Color(0xFF08874A);      // أخضر الشعار (أغمق قليلًا لوضوح النص)
const Color kBrandLight = Color(0xFFDDF5E7);
const Color kSurface = Color(0xFFF8F9FA);

class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double pill = 24;
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alfaham Store',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: kBrand,
        scaffoldBackgroundColor: kSurface,
        textTheme: GoogleFonts.cairoTextTheme(),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 1,
          elevation: 0,
          shadowColor: Colors.black26,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
          iconTheme: IconThemeData(color: Color(0xFF3C4043)),
          titleTextStyle: TextStyle(
            color: Color(0xFF202124),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      scrollBehavior: const _DragScrollBehavior(),
      home: const MainLayout(),
      // دائماً نبدأ من الرئيسية؛ صفحة التطبيق تُفتح من ?app=... في _initLinks
      onGenerateInitialRoutes: (_) => [
        MaterialPageRoute(builder: (_) => const MainLayout()),
      ],
    );
  }
}

// مسار التبويب الحالي (يُكتب في رابط المتصفح ليبقى التحديث على نفس الصفحة)
String _currentTabPath = '/';

void _reportUrl(String path) {
  if (!kIsWeb) return;
  SystemNavigator.routeInformationUpdated(uri: Uri.parse(path), replace: true);
}

void openApp(BuildContext context, AppItem app) {
  final path = '/app/${Uri.encodeComponent(app.packageName)}';
  Navigator.push(
    context,
    MaterialPageRoute(
      settings: RouteSettings(name: path),
      builder: (_) => AppDetailsScreen(app: app),
    ),
  ).then((_) => _reportUrl(_currentTabPath));
}

// ═══════════════════════════════════════════════════════════════
// الهيكل الأساسي
// ═══════════════════════════════════════════════════════════════
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = StoreConfig.initialTab;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late Future<List<AppItem>> _future;
  late final Future<DeveloperProfile?> _devFuture =
      StoreService.fetchDeveloper();

  void _setTab(int i) {
    setState(() => _currentIndex = i);
    _currentTabPath = StoreConfig.tabPaths[i];
    _reportUrl(_currentTabPath);
  }

  @override
  void initState() {
    super.initState();
    _currentTabPath = StoreConfig.tabPaths[_currentIndex];
    _future = StoreService.fetchApps();
    _initLinks();
  }

  StreamSubscription<Uri>? _linkSub;

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  // فتح صفحة تطبيق من رابط مشاركة (?app=اسم.الحزمة)
  Future<void> _openPackage(String pkg) async {
    if (pkg.isEmpty) return;
    try {
      final apps = await _future;
      if (!mounted) return;
      final match = apps.where((a) => a.packageName == pkg);
      if (match.isNotEmpty) openApp(context, match.first);
    } catch (_) {}
  }

  Future<void> _initLinks() async {
    // الويب: الرابط الحالي في المتصفح
    await _openPackage(StoreConfig.sharedPackage);
    if (kIsWeb) return;
    // أندرويد: الروابط التي تفتح التطبيق
    try {
      final links = AppLinks();
      final initial = await links.getInitialLink();
      if (initial != null) {
        await _openPackage(StoreConfig.packageFromUri(initial));
      }
      _linkSub = links.uriLinkStream.listen(
        (u) => _openPackage(StoreConfig.packageFromUri(u)),
      );
    } catch (_) {}
  }

  Future<void> _reload() async {
    final next = StoreService.fetchApps();
    setState(() => _future = next);
    try {
      await next;
    } catch (_) {}
  }

  void _push(Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 1000;
    final index = _currentIndex;
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Image.asset(
                'assets/logo.png',
                width: 34,
                height: 34,
                errorBuilder: (_, __, ___) => Container(
                  width: 34,
                  height: 34,
                  color: kBrandLight,
                  child: const Icon(Icons.storefront, size: 20, color: kBrand),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text('Alfaham Store'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'القائمة',
            icon: const Icon(Icons.menu),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              height: 180,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [kBrand, Color(0xFF2FB765)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: Image.asset(
                          'assets/logo.png',
                          width: 60,
                          height: 60,
                          errorBuilder: (_, __, ___) => Container(
                            width: 60,
                            height: 60,
                            color: Colors.white24,
                            child: const Icon(Icons.storefront,
                                size: 34, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Alfaham Store',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'تحميل مباشر وآمن',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: kBrand),
              title: const Text('من نحن'),
              onTap: () => _push(const InfoPage(
                title: 'من نحن',
                text:
                    'هذا المتجر هو منصتك الرقمية الخاصة لتحميل وتثبيت تطبيقات الأندرويد بشكل مباشر وسهل، وبدون أي إعلانات مزعجة أو روابط وهمية.',
              )),
            ),
            FutureBuilder<DeveloperProfile?>(
              future: _devFuture,
              builder: (context, snap) {
                final dev = snap.data;
                if (dev == null) return const SizedBox.shrink();
                return ListTile(
                  leading: const Icon(Icons.person_outline, color: kBrand),
                  title: Text(dev.name),
                  subtitle: const Text('الملف الشخصي للمطوّر'),
                  onTap: () => _push(const DeveloperScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined, color: Colors.orange),
              title: const Text('سياسة الخصوصية'),
              onTap: () => _push(const InfoPage(
                title: 'سياسة الخصوصية',
                text:
                    'نحن نحترم خصوصية المستخدمين. هذا التطبيق لا يجمع أي بيانات شخصية حساسة، وجميع ملفات الـ APK يتم تحميلها من مصادر موثوقة ومباشرة.',
              )),
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<AppItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final apps = snapshot.data!;
            final screens = <Widget>[
              HomeScreen(
                apps: apps,
                onRefresh: _reload,
                onSeeApps: () => _setTab(1),
                onSeeGames: () => _setTab(2),
              ),
              CatalogScreen(
                apps: apps.where((a) => !a.isGame).toList(),
                emptyText: 'لا توجد تطبيقات بعد',
                onRefresh: _reload,
              ),
              CatalogScreen(
                apps: apps.where((a) => a.isGame).toList(),
                emptyText: 'لا توجد ألعاب بعد',
                onRefresh: _reload,
              ),
              SearchScreen(apps: apps),
            ];
            Widget page = screens[index];
            if (!wide) return page;
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: page,
              ),
            );
          }
          if (snapshot.hasError) {
            return ErrorView(
              message:
                  snapshot.error.toString().replaceFirst('Exception: ', ''),
              onRetry: _reload,
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _setTab,
        backgroundColor: Colors.white,
        indicatorColor: kBrandLight,
        elevation: 3,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: kBrand),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.apps_outlined),
            selectedIcon: Icon(Icons.apps, color: kBrand),
            label: 'تطبيقات',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_esports_outlined),
            selectedIcon: Icon(Icons.sports_esports, color: kBrand),
            label: 'ألعاب',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            selectedIcon: Icon(Icons.search, color: kBrand),
            label: 'بحث',
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// عناصر مشتركة
// ═══════════════════════════════════════════════════════════════
class AppIcon extends StatelessWidget {
  final AppItem app;
  final double size;

  const AppIcon({super.key, required this.app, this.size = 56});

  Widget _fallback() {
    return Container(
      color: kBrandLight,
      alignment: Alignment.center,
      child: Icon(Icons.android, color: kBrand, size: size * 0.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = app.iconUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: SizedBox(
        width: size,
        height: size,
        child: url.isEmpty
            ? _fallback()
            : Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: kBrandLight,
                    alignment: Alignment.center,
                    child: const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: kBrand,
                      ),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => _fallback(),
              ),
      ),
    );
  }
}

class AppTile extends StatelessWidget {
  final AppItem app;

  const AppTile({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      if (app.genre.isNotEmpty) app.genre,
      app.sizeLabel,
    ].join(' • ');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => openApp(context, app),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              AppIcon(app: app, size: 50),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      app.shortDescription.isEmpty
                          ? subtitle
                          : '${app.shortDescription}\n$subtitle',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: kBrand,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
                onPressed: () => openApp(context, app),
                child: const Text('عرض'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const ErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  final String text;

  const EmptyView({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.inbox_outlined, size: 56, color: Colors.grey),
        const SizedBox(height: 12),
        Center(child: Text(text, style: const TextStyle(color: Colors.grey))),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// الشاشات الأساسية
// ═══════════════════════════════════════════════════════════════
class AppSquareCard extends StatelessWidget {
  final AppItem app;
  final double size;

  const AppSquareCard({super.key, required this.app, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => openApp(context, app),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIcon(app: app, size: size),
            const SizedBox(height: 8),
            Text(
              app.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13, height: 1.25),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                if (app.rating > 0) ...[
                  Text(app.ratingLabel,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade700)),
                  const SizedBox(width: 2),
                  Icon(Icons.star, size: 11, color: Colors.grey.shade700),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    app.sizeLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class BannerCarousel extends StatefulWidget {
  final List<AppItem> apps;

  const BannerCarousel({super.key, required this.apps});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final PageController _controller = PageController(viewportFraction: 0.92);
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_controller.hasClients || widget.apps.length < 2) return;
      final next = (_page + 1) % widget.apps.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final apps = widget.apps;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 2,
              child: PageView.builder(
                controller: _controller,
                itemCount: apps.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) {
                  final app = apps[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: GestureDetector(
                      onTap: () => openApp(context, app),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              app.bannerUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: kBrandLight,
                                child: const Icon(Icons.image_outlined,
                                    color: kBrand, size: 40),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(12, 24, 12, 10),
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Colors.transparent, Colors.black54],
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    AppIcon(app: app, size: 36),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        app.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (apps.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < apps.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _page ? 16 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i == _page ? kBrand : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final List<AppItem> apps;
  final Future<void> Function() onRefresh;
  final VoidCallback? onSeeApps;
  final VoidCallback? onSeeGames;

  const HomeScreen({
    super.key,
    required this.apps,
    required this.onRefresh,
    this.onSeeApps,
    this.onSeeGames,
  });

  Widget _row(String title, List<AppItem> list, {VoidCallback? onMore}) {
    if (list.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onMore,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                  if (onMore != null)
                    const Icon(Icons.arrow_back, size: 20, color: kBrand),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 205,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, i) => AppSquareCard(app: list[i]),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (apps.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child:
            const EmptyView(text: 'لا توجد تطبيقات بعد، أضف أول تطبيق من لوحة التحكم'),
      );
    }

    final featured = apps.where((a) => a.featured).toList();
    final highlighted = featured.isNotEmpty ? featured : apps.take(6).toList();
    final banners = (featured.isNotEmpty ? featured : apps)
        .where((a) => a.banner.isNotEmpty)
        .take(8)
        .toList();
    final onlyApps = apps.where((a) => !a.isGame).toList();
    final games = apps.where((a) => a.isGame).toList();

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 16, bottom: 16),
        children: [
          if (banners.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: BannerCarousel(apps: banners),
            ),
          _row('تطبيقات مميزة', highlighted),
          _row(
              'أحدث الإضافات',
              ([...apps]..sort((x, y) => y.updatedAt.compareTo(x.updatedAt)))
                  .take(10)
                  .toList()),
          _row('تطبيقات', onlyApps, onMore: onSeeApps),
          _row('ألعاب', games, onMore: onSeeGames),
        ],
      ),
    );
  }
}

class CatalogScreen extends StatefulWidget {
  final List<AppItem> apps;
  final String emptyText;
  final Future<void> Function() onRefresh;

  const CatalogScreen({
    super.key,
    required this.apps,
    required this.emptyText,
    required this.onRefresh,
  });

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  String? _genre;

  @override
  void didUpdateWidget(covariant CatalogScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_genre != null && !widget.apps.any((a) => a.genre == _genre)) {
      _genre = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final genres = widget.apps
        .map((a) => a.genre)
        .where((g) => g.isNotEmpty)
        .toSet()
        .toList();
    final selected = genres.contains(_genre) ? _genre : null;
    final shown = selected == null
        ? widget.apps
        : widget.apps.where((a) => a.genre == selected).toList();

    if (widget.apps.isEmpty) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: EmptyView(text: widget.emptyText),
      );
    }

    return Column(
      children: [
        if (genres.isNotEmpty)
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: ChoiceChip(
                    label: const Text('الكل'),
                    selected: selected == null,
                    onSelected: (_) => setState(() => _genre = null),
                    selectedColor: kBrandLight,
                    labelStyle: TextStyle(
                      color: selected == null ? kBrand : Colors.black87,
                      fontWeight: selected == null
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: selected == null ? kBrand : Colors.grey.shade300,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
                for (final g in genres)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                      label: Text(g),
                      selected: selected == g,
                      onSelected: (_) => setState(() => _genre = g),
                      selectedColor: kBrandLight,
                      labelStyle: TextStyle(
                        color: selected == g ? kBrand : Colors.black87,
                        fontWeight: selected == g
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: selected == g ? kBrand : Colors.grey.shade300,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: widget.onRefresh,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: shown.length,
              itemBuilder: (_, i) => AppTile(app: shown[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class SearchScreen extends StatefulWidget {
  final List<AppItem> apps;
  final String? query; // عند تمريره (نسخة الويب) يُخفى حقل البحث الداخلي

  const SearchScreen({super.key, required this.apps, this.query});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _query = '';
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = (widget.query ?? _query).trim().toLowerCase();
    final results = q.isEmpty
        ? <AppItem>[]
        : widget.apps.where((a) {
            return a.name.toLowerCase().contains(q) ||
                a.shortDescription.toLowerCase().contains(q) ||
                a.genre.toLowerCase().contains(q) ||
                a.packageName.toLowerCase().contains(q);
          }).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (widget.query == null)
          TextField(
            controller: _controller,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'ابحث عن تطبيق أو لعبة...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _controller.clear();
                        setState(() => _query = '');
                      },
                    ),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: kBrand, width: 1.5),
              ),
            ),
          ),
          SizedBox(height: widget.query == null ? 16 : 0),
          Expanded(
            child: q.isEmpty
                ? const Center(
                    child: Text('اكتب اسم التطبيق للبحث عنه...',
                        style: TextStyle(color: Colors.grey)),
                  )
                : results.isEmpty
                    ? const Center(
                        child: Text('لا توجد نتائج مطابقة',
                            style: TextStyle(color: Colors.grey)),
                      )
                    : ListView.builder(
                        itemCount: results.length,
                        itemBuilder: (_, i) => AppTile(app: results[i]),
                      ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// صفحات القائمة الجانبية
// ═══════════════════════════════════════════════════════════════
class InfoPage extends StatelessWidget {
  final String title;
  final String text;

  const InfoPage({super.key, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(text, style: const TextStyle(fontSize: 16, height: 1.6)),
      ),
    );
  }
}

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  Future<void> _open(BuildContext context, String url) async {
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر فتح الرابط')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اتصل بنا')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'إذا كان لديك أي تطبيق تريد إضافته أو واجهتك مشكلة، تواصل معنا عبر:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            _ContactTile(
              icon: Icons.send,
              label: 'تليجرام: @YourChannel',
              onTap: () => _open(context, 'https://t.me/YourChannel'),
            ),
            const SizedBox(height: 10),
            _ContactTile(
              icon: Icons.email_outlined,
              label: 'البريد الإلكتروني: support@store.com',
              onTap: () => _open(context, 'mailto:support@store.com'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ContactTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Icon(icon, color: kBrand),
        title: Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing:
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// صفحة تفاصيل التطبيق — بنمط Google Play
// ═══════════════════════════════════════════════════════════════
class AppDetailsScreen extends StatefulWidget {
  final AppItem app;

  const AppDetailsScreen({super.key, required this.app});

  @override
  State<AppDetailsScreen> createState() => _AppDetailsScreenState();
}

class _AppDetailsScreenState extends State<AppDetailsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showPinnedInstall = false;
  bool _playing = false;
  YoutubePlayerController? _yt;
  double? _dl;           // تقدّم التنزيل (0..1) أو null إذا لا يوجد تنزيل
  bool _cancelDl = false;

  AppItem get app => widget.app;

  List<AppItem> _similar = const [];

  Future<void> _loadSimilar() async {
    try {
      final all = await StoreService.fetchApps();
      final others =
          all.where((a) => a.packageName != app.packageName).toList();
      final sameGenre = app.genre.isEmpty
          ? <AppItem>[]
          : others.where((a) => a.genre == app.genre).toList();
      final sameCategory = others
          .where((a) => a.category == app.category && !sameGenre.contains(a))
          .toList();
      final list = [...sameGenre, ...sameCategory].take(10).toList();
      if (mounted) setState(() => _similar = list);
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _loadSimilar();
    _scrollController.addListener(() {
      final shouldPin = _scrollController.offset > 240;
      if (shouldPin != _showPinnedInstall) {
        setState(() => _showPinnedInstall = shouldPin);
      }
    });
  }

  @override
  void dispose() {
    _yt?.close();
    _scrollController.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _openInBrowser() async {
    final ok = await launchUrl(
      Uri.parse(app.apkUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!ok) _snack('تعذّر فتح رابط التحميل');
  }

  Future<void> _download() async {
    if (_dl != null) return;
    // الويب (أو أي نظام غير أندرويد): فتح الرابط في المتصفح
    if (!supportsInAppInstall) return _openInBrowser();

    _cancelDl = false;
    setState(() => _dl = 0);
    try {
      final path = await downloadApk(
        app.apkUrl,
        fileName: '${app.packageName}.apk',
        sha256Hex: app.sha256,
        onProgress: (p) {
          if (mounted) setState(() => _dl = p);
        },
        isCancelled: () => _cancelDl,
      );
      if (mounted) setState(() => _dl = null);
      final opened = await installApk(path);
      if (!opened) _snack('تعذّر فتح المثبّت، حاول مرة أخرى');
    } on DownloadCancelled {
      if (mounted) setState(() => _dl = null);
    } on ChecksumMismatch {
      if (mounted) setState(() => _dl = null);
      _snack('الملف غير مطابق للبصمة الأصلية، تم إلغاء التثبيت');
    } catch (_) {
      if (mounted) setState(() => _dl = null);
      _snack('تعذّر التنزيل داخل المتجر، سيُفتح الرابط في المتصفح');
      await _openInBrowser();
    }
  }

  // ─── شريط الوسائط ───
  void _openGallery(List<String> urls, int index) {
    Navigator.of(context).push(PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) =>
          MediaViewer(urls: urls, initialIndex: index),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    ));
  }

  Widget _mediaPlaceholder() => Container(
        color: kSurface,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: kBrand),
        ),
      );

  // ─── الغلاف العلوي (على نمط Google Play): البانر + تشغيل الفيديو داخل الصفحة ───
  void _startVideo() {
    if (kIsWeb) {
      _yt ??= YoutubePlayerController.fromVideoId(
        videoId: app.youtubeId,
        autoPlay: true,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          strictRelatedVideos: true,
        ),
      );
    }
    setState(() => _playing = true);
  }

  // ─── شريط الوسائط على نمط Google Play ───
  // أول عنصر: الفيديو (أو البنر إن لم يوجد فيديو) ثم لقطات الشاشة بجانبه.
  Widget _mediaCarousel() {
    final shots = app.screenshotUrls;
    final hasVideo = app.youtubeId.isNotEmpty;
    final banners = app.bannerUrls;
    final hasBanner = banners.isNotEmpty;
    if (!hasVideo && !hasBanner && shots.isEmpty) return const SizedBox.shrink();

    // المعرض (ملء الشاشة): صور البانر ثم لقطات الشاشة.
    final gallery = <String>[...banners, ...shots];
    final offset = banners.length;

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: LayoutBuilder(
        builder: (context, c) {
          final h = (c.maxWidth * 0.62).clamp(200.0, 340.0);
          final leadW = h * 16 / 9;
          final count = (hasVideo ? 1 : 0) + banners.length + shots.length;

          return SizedBox(
            height: h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: count,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                var k = i;
                if (hasVideo) {
                  if (k == 0) {
                    return _leadMedia(h, leadW, true, hasBanner, gallery);
                  }
                  k--;
                }
                if (k < banners.length) {
                  return GestureDetector(
                    onTap: () => _openGallery(gallery, k),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: SizedBox(
                        width: leadW,
                        height: h,
                        child: Image.network(
                          banners[k],
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, p) =>
                              p == null ? child : _mediaPlaceholder(),
                          errorBuilder: (_, __, ___) =>
                              Container(color: Colors.grey.shade200),
                        ),
                      ),
                    ),
                  );
                }
                k -= banners.length;
                return GestureDetector(
                  onTap: () => _openGallery(gallery, k + offset),
                  child: _shotImage(shots[k], h),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _shotImage(String url, double h) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: h * 9 / 16),
        child: Image.network(
          url,
          height: h,
          fit: BoxFit.fitHeight,
          loadingBuilder: (_, child, p) => p == null
              ? child
              : SizedBox(
                  width: h * 9 / 16, height: h, child: _mediaPlaceholder()),
          errorBuilder: (_, __, ___) => Container(
            width: h * 9 / 16,
            height: h,
            color: Colors.grey.shade200,
            child: const Icon(Icons.image_not_supported, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  // العنصر الأول في الشريط: فيديو يوتيوب (يُشغَّل مكانه) أو صورة البنر.
  Widget _leadMedia(double h, double w, bool hasVideo, bool hasBanner,
      List<String> gallery) {
    final poster = hasVideo
        ? 'https://img.youtube.com/vi/${app.youtubeId}/hqdefault.jpg'
        : app.bannerUrl;

    Widget content;
    if (hasVideo && _playing) {
      content = kIsWeb
          ? YoutubePlayer(controller: _yt!, aspectRatio: 16 / 9)
          : _AndroidYoutube(videoId: app.youtubeId);
    } else {
      content = Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            poster,
            fit: BoxFit.cover,
            loadingBuilder: (_, child, p) =>
                p == null ? child : _mediaPlaceholder(),
            errorBuilder: (_, __, ___) => Container(color: Colors.black87),
          ),
          if (hasVideo) ...[
            Container(color: Colors.black26),
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black38, blurRadius: 8),
                  ],
                ),
                child: const Icon(Icons.play_arrow,
                    color: Colors.white, size: 38),
              ),
            ),
          ],
        ],
      );
      content = GestureDetector(
        onTap: hasVideo ? _startVideo : () => _openGallery(gallery, 0),
        child: content,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: SizedBox(width: w, height: h, child: content),
    );
  }

  void _showFullText(String title, String text) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Text(text,
                style: const TextStyle(
                    fontSize: 15, height: 1.6, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _installButton() {
    if (_dl != null) {
      return SizedBox(
        height: 40,
        child: Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    LinearProgressIndicator(
                      value: _dl! > 0 ? _dl : null,
                      minHeight: 40,
                      backgroundColor: kBrandLight,
                      color: kBrand.withOpacity(0.45),
                    ),
                    Center(
                      child: Text(
                        _dl! > 0
                            ? 'جارٍ التنزيل ${(_dl! * 100).round()}%'
                            : 'جارٍ التنزيل...',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'إلغاء',
              onPressed: () => _cancelDl = true,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: kBrand,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
        onPressed: (app.apkUrl.isEmpty || _dl != null) ? null : _download,
        child: Text(
          app.apkUrl.isEmpty ? 'غير متاح حالياً' : 'تثبيت',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _statsRow() {
    final items = <Widget>[];

    void addStat(IconData? icon, String value, String label) {
      if (items.isNotEmpty) {
        items.add(Container(width: 1, height: 32, color: Colors.black12));
      }
      items.add(
        Expanded(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 14, color: Colors.black54),
                    const SizedBox(width: 4),
                  ],
                  Flexible(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(label,
                  style:
                      const TextStyle(fontSize: 11, color: Colors.black54)),
            ],
          ),
        ),
      );
    }

    if (StoreConfig.showRating && app.rating > 0) {
      addStat(Icons.star, app.ratingLabel, 'التقييم');
    }
    if (StoreConfig.showDownloads && app.downloads > 0) {
      addStat(null, app.downloadsLabel, 'التحميلات');
    }
    addStat(null, app.sizeLabel, 'الحجم');
    if (app.genre.isNotEmpty) {
      addStat(null, app.genre, 'التصنيف');
    }
    if (app.ageRating.isNotEmpty) {
      addStat(null, app.ageRating, 'العمر');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(children: items),
    );
  }

  Widget _infoChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: kBrand),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: Colors.black54)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _section(String title, {Widget? trailing, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600)),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shortD = app.shortDescription.trim();
    final longD = app.longDescription.trim();
    final description = [
      if (shortD.isNotEmpty) shortD,
      if (longD.isNotEmpty) longD,
    ].join('\n\n');
    final kind = app.isGame ? 'لعبة' : 'تطبيق';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF3C4043),
        surfaceTintColor: Colors.transparent,
        elevation: _showPinnedInstall ? 1 : 0,
        scrolledUnderElevation: 1,
        title: AnimatedOpacity(
          opacity: _showPinnedInstall ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: Row(
            children: [
              AppIcon(app: app, size: 30),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  app.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF202124)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'مشاركة',
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              Clipboard.setData(
                  ClipboardData(text: StoreConfig.shareUrl(app.packageName)));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم نسخ رابط التطبيق')),
              );
            },
          ),
          if (_showPinnedInstall && app.apkUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: SizedBox(
                width: 100,
                height: 36,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: kBrand,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  onPressed: (app.apkUrl.isEmpty || _dl != null) ? null : _download,
                  child: const Text('تثبيت',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // ─── هيدر: أيقونة + اسم + مطوّر + تصنيف ───
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppIcon(app: app, size: 64),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            height: 1.2),
                      ),
                      if (app.developer.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const DeveloperScreen()),
                          ),
                          child: Text(
                            app.developer.trim(),
                            style: const TextStyle(
                                fontSize: 13,
                                color: kBrand,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        '$kind • ${app.sizeLabel}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ─── صف الإحصائيات ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _statsRow(),
          ),

          // ─── زر التثبيت الرئيسي ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _installButton(),
          ),

          // ─── الوسائط: فيديو/بانر + لقطات الشاشة ───
          _mediaCarousel(),

          // ─── عن هذا التطبيق ───
          _section(
            'عن هذا التطبيق',
            trailing: description.isNotEmpty
                ? IconButton(
                    tooltip: 'المزيد',
                    onPressed: () =>
                        _showFullText('عن هذا التطبيق', description),
                    icon: const Icon(Icons.arrow_back),
                  )
                : null,
            child: description.isEmpty
                ? const Text('—', style: TextStyle(color: Colors.black54))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (shortD.isNotEmpty)
                        Text(
                          shortD,
                          style: const TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87),
                        ),
                      if (shortD.isNotEmpty && longD.isNotEmpty)
                        const SizedBox(height: 12),
                      if (longD.isNotEmpty)
                        Text(
                          longD,
                          style: const TextStyle(
                              fontSize: 14, height: 1.6, color: Colors.black87),
                        ),
                    ],
                  ),
          ),

          // ─── بيانات التطبيق ───
          _section(
            'بيانات التطبيق',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (app.version.isNotEmpty)
                  _infoChip(Icons.system_update, 'الإصدار', app.version),
                if (app.dateLabel.isNotEmpty)
                  _infoChip(Icons.update, 'آخر تحديث', app.dateLabel),
              ],
            ),
          ),

          // ─── ما الجديد ───
          if (app.whatsNew.isNotEmpty)
            _section(
              'ما الجديد',
              trailing: IconButton(
                tooltip: 'المزيد',
                onPressed: () =>
                    _showFullText('ما الجديد', app.whatsNew),
                icon: const Icon(Icons.arrow_back),
              ),
              child: Text(
                app.whatsNew,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 14, height: 1.6, color: Colors.black87),
              ),
            ),

          // ─── تطبيقات مشابهة ───
          if (_similar.isNotEmpty)
            _section(
              'تطبيقات مشابهة',
              child: SizedBox(
                height: 195,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: _similar.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (_, i) => AppSquareCard(app: _similar[i]),
                ),
              ),
            ),

        ],
      ),
        ),
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════════════
// سحب بالماوس/اللمس لكل القوائم الأفقية (مهم لنسخة الويب)
// ═══════════════════════════════════════════════════════════════
class _DragScrollBehavior extends MaterialScrollBehavior {
  const _DragScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}

// ═══════════════════════════════════════════════════════════════
// عارض الصور بملء الشاشة: تمرير بين الصور + تكبير بالقرصة/الدبل-تاب/العجلة
// ═══════════════════════════════════════════════════════════════
class MediaViewer extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;

  const MediaViewer({super.key, required this.urls, this.initialIndex = 0});

  @override
  State<MediaViewer> createState() => _MediaViewerState();
}

class _MediaViewerState extends State<MediaViewer> {
  late final PageController _pc;
  late int _index;
  bool _zoomed = false;

  int get _count => widget.urls.length;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.urls.length - 1);
    _pc = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _go(int delta) {
    final t = _index + delta;
    if (t < 0 || t >= _count) return;
    _pc.animateToPage(t,
        duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final wide = MediaQuery.of(context).size.width >= 700;

    Widget arrow(IconData icon, int delta, bool enabled) {
      return Material(
        color: Colors.black45,
        shape: const CircleBorder(),
        child: IconButton(
          icon: Icon(icon, color: enabled ? Colors.white : Colors.white24),
          onPressed: enabled ? () => _go(delta) : null,
        ),
      );
    }

    return Focus(
      autofocus: true,
      onKeyEvent: (node, e) {
        if (e is! KeyDownEvent) return KeyEventResult.ignored;
        if (e.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.pop(context);
          return KeyEventResult.handled;
        }
        if (e.logicalKey == LogicalKeyboardKey.arrowRight) {
          _go(rtl ? -1 : 1);
          return KeyEventResult.handled;
        }
        if (e.logicalKey == LogicalKeyboardKey.arrowLeft) {
          _go(rtl ? 1 : -1);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            PageView.builder(
              controller: _pc,
              physics: _zoomed
                  ? const NeverScrollableScrollPhysics()
                  : const PageScrollPhysics(),
              itemCount: _count,
              onPageChanged: (i) => setState(() {
                _index = i;
                _zoomed = false;
              }),
              itemBuilder: (_, i) => _ZoomableImage(
                key: ValueKey(widget.urls[i]),
                url: widget.urls[i],
                onZoomChanged: (z) {
                  if (z != _zoomed) setState(() => _zoomed = z);
                },
              ),
            ),
            // الشريط العلوي: إغلاق + العدّاد
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'إغلاق',
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      if (_count > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text('${_index + 1} / $_count',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13)),
                        ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
            ),
            // أسهم التنقل لشاشات الكمبيوتر
            if (wide && _count > 1) ...[
              Positioned(
                left: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: rtl
                      ? arrow(Icons.chevron_left, 1, _index < _count - 1)
                      : arrow(Icons.chevron_left, -1, _index > 0),
                ),
              ),
              Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: rtl
                      ? arrow(Icons.chevron_right, -1, _index > 0)
                      : arrow(Icons.chevron_right, 1, _index < _count - 1),
                ),
              ),
            ],
            // نقاط المؤشر
            if (_count > 1 && _count <= 12)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _count,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _index ? 18 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: i == _index ? Colors.white : Colors.white38,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ZoomableImage extends StatefulWidget {
  final String url;
  final ValueChanged<bool> onZoomChanged;

  const _ZoomableImage({super.key, required this.url, required this.onZoomChanged});

  @override
  State<_ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<_ZoomableImage> {
  final TransformationController _tc = TransformationController();
  Offset _tapPos = Offset.zero;
  bool _zoomed = false;

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  void _setZoomed(bool z) {
    if (z == _zoomed) return;
    setState(() => _zoomed = z);
    widget.onZoomChanged(z);
  }

  void _toggleZoom() {
    if (_zoomed) {
      _tc.value = Matrix4.identity();
      _setZoomed(false);
    } else {
      const s = 2.5;
      final m = Matrix4.identity();
      m.setEntry(0, 0, s);
      m.setEntry(1, 1, s);
      m.setEntry(0, 3, -_tapPos.dx * (s - 1));
      m.setEntry(1, 3, -_tapPos.dy * (s - 1));
      _tc.value = m;
      _setZoomed(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: (d) => _tapPos = d.localPosition,
      onDoubleTap: _toggleZoom,
      child: InteractiveViewer(
        transformationController: _tc,
        minScale: 1,
        maxScale: 5,
        panEnabled: _zoomed,
        onInteractionUpdate: (_) =>
            _setZoomed(_tc.value.getMaxScaleOnAxis() > 1.02),
        onInteractionEnd: (_) =>
            _setZoomed(_tc.value.getMaxScaleOnAxis() > 1.02),
        child: SizedBox.expand(
          child: Image.network(
            widget.url,
            fit: BoxFit.contain,
            loadingBuilder: (_, child, p) => p == null
                ? child
                : const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  ),
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.image_not_supported,
                  color: Colors.white54, size: 48),
            ),
          ),
        ),
      ),
    );
  }
}


/// مشغّل يوتيوب داخل التطبيق على أندرويد/iOS عبر WebView مع origin صحيح
/// (يوتيوب يرفض التضمين بدون Referer/origin حقيقي: خطأ 150/153).
class _AndroidYoutube extends StatefulWidget {
  final String videoId;
  const _AndroidYoutube({required this.videoId});

  @override
  State<_AndroidYoutube> createState() => _AndroidYoutubeState();
}

class _AndroidYoutubeState extends State<_AndroidYoutube> {
  static const _origin = 'https://alfahamstore.web.app';
  late final WebViewController _c;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    final id = widget.videoId;
    final html = '''
<!DOCTYPE html><html><head>
<meta name="viewport" content="width=device-width,initial-scale=1">
<style>html,body{margin:0;height:100%;background:#000;overflow:hidden}
#p{position:absolute;inset:0;width:100%;height:100%}</style></head>
<body><div id="p"></div>
<script src="https://www.youtube.com/iframe_api"></script>
<script>
function onYouTubeIframeAPIReady(){
  new YT.Player('p',{
    videoId:'$id', width:'100%', height:'100%',
    playerVars:{autoplay:1,playsinline:1,rel:0,modestbranding:1,origin:'$_origin'},
    events:{onError:function(e){Err.postMessage(String(e.data));}}
  });
}
</script></body></html>''';
    _c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..addJavaScriptChannel('Err', onMessageReceived: (_) {
        if (mounted) setState(() => _failed = true);
      })
      ..loadHtmlString(html, baseUrl: _origin);
  }

  Future<void> _openExternal() => launchUrl(
        Uri.parse('https://www.youtube.com/watch?v=${widget.videoId}'),
        mode: LaunchMode.externalApplication,
      );

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        WebViewWidget(controller: _c),
        if (_failed)
          Container(
            color: Colors.black,
            alignment: Alignment.center,
            child: TextButton.icon(
              onPressed: _openExternal,
              icon: const Icon(Icons.open_in_new, color: Colors.white),
              label: const Text('فتح في يوتيوب',
                  style: TextStyle(color: Colors.white)),
            ),
          ),
      ],
    );
  }
}


// ═══════════════════════════════════════════════════════════════
// صفحة المطوّر (الملف الشخصي) — تُدار من لوحة التحكم
// ═══════════════════════════════════════════════════════════════
class DeveloperScreen extends StatefulWidget {
  const DeveloperScreen({super.key});

  @override
  State<DeveloperScreen> createState() => _DeveloperScreenState();
}

class _DeveloperScreenState extends State<DeveloperScreen> {
  late final Future<DeveloperProfile?> _profile = StoreService.fetchDeveloper();
  late final Future<List<AppItem>> _apps = StoreService.fetchApps();

  Future<void> _open(String url) async {
    final ok = await launchUrl(Uri.parse(url),
        mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تعذّر فتح الرابط')));
    }
  }

  Widget _avatar(DeveloperProfile p) {
    Widget fallback() => Container(
          color: kBrandLight,
          alignment: Alignment.center,
          child: const Icon(Icons.person, color: kBrand, size: 48),
        );
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
      ),
      child: ClipOval(
        child: p.avatarUrl.isEmpty
            ? fallback()
            : Image.network(p.avatarUrl,
                fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المطوّر')),
      body: FutureBuilder<DeveloperProfile?>(
        future: _profile,
        builder: (context, ps) {
          if (ps.connectionState != ConnectionState.done) {
            return const Center(
                child: CircularProgressIndicator(color: kBrand));
          }
          final p = ps.data;
          if (p == null) {
            return const EmptyView(text: 'لم يتم إعداد ملف المطوّر بعد');
          }
          final links = <MapEntry<IconData, MapEntry<String, String>>>[
            if (p.websiteLink.isNotEmpty)
              MapEntry(Icons.language, MapEntry('الموقع', p.websiteLink)),
            if (p.telegramLink.isNotEmpty)
              MapEntry(Icons.send, MapEntry('تيليجرام', p.telegramLink)),
            if (p.youtubeLink.isNotEmpty)
              MapEntry(Icons.smart_display, MapEntry('يوتيوب', p.youtubeLink)),
            if (p.facebookLink.isNotEmpty)
              MapEntry(Icons.facebook, MapEntry('فيسبوك', p.facebookLink)),
            if (p.instagramLink.isNotEmpty)
              MapEntry(Icons.camera_alt_outlined,
                  MapEntry('إنستغرام', p.instagramLink)),
            if (p.emailLink.isNotEmpty)
              MapEntry(Icons.email_outlined,
                  MapEntry('البريد الإلكتروني', p.emailLink)),
          ];
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AspectRatio(
                        aspectRatio: 1024 / 400,
                        child: p.coverUrl.isEmpty
                            ? Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [kBrand, Color(0xFF2FB765)],
                                    begin: Alignment.topRight,
                                    end: Alignment.bottomLeft,
                                  ),
                                ),
                              )
                            : Image.network(p.coverUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    Container(color: kBrandLight)),
                      ),
                      PositionedDirectional(
                        start: 16,
                        bottom: -48,
                        child: _avatar(p),
                      ),
                    ],
                  ),
                  const SizedBox(height: 56),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name,
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w700)),
                        if (p.bio.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(p.bio,
                              style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.6,
                                  color: Colors.black87)),
                        ],
                        if (links.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final l in links)
                                ActionChip(
                                  avatar: Icon(l.key, size: 18, color: kBrand),
                                  label: Text(l.value.key),
                                  backgroundColor: Colors.white,
                                  side: BorderSide(color: Colors.grey.shade300),
                                  onPressed: () => _open(l.value.value),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  FutureBuilder<List<AppItem>>(
                    future: _apps,
                    builder: (context, asn) {
                      final apps = asn.data ?? const <AppItem>[];
                      if (apps.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('تطبيقات ${p.name} (${apps.length})',
                                style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 10),
                            for (final a in apps) AppTile(app: a),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
