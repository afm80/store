import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models.dart';
import 'store_service.dart';

// ═══════════════════════════════════════════════════════════════
// ثوابت الهوية البصرية
// ═══════════════════════════════════════════════════════════════
const Color kBrand = Color(0xFF075C55);
const Color kBrandLight = Color(0xFFD3E8E5);
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
          backgroundColor: kBrand,
          surfaceTintColor: Colors.transparent,
          elevation: 0.5,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      home: const MainLayout(),
    );
  }
}

void openApp(BuildContext context, AppItem app) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => AppDetailsScreen(app: app)),
  );
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
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late Future<List<AppItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = StoreService.fetchApps();
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
            tooltip: 'تحديث القائمة',
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
          ),
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
                  colors: [kBrand, Color(0xFF0A7A71)],
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
            ListTile(
              leading: const Icon(Icons.contact_support_outlined, color: kBrand),
              title: const Text('اتصل بنا / تواصل معي'),
              onTap: () => _push(const ContactScreen()),
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
            const Divider(),
            ListTile(
              leading: const Icon(Icons.code, color: Colors.purple),
              title: const Text('للمطورين'),
              onTap: () => _push(const InfoPage(
                title: 'للمطورين',
                text:
                    'تم تصميم وبرمجة هذا المتجر باستخدام تقنية Flutter ليعمل بكفاءة عالية كتطبيق موبايل وموقع ويب في آنٍ واحد.',
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
                onSeeApps: () => setState(() => _currentIndex = 1),
                onSeeGames: () => setState(() => _currentIndex = 2),
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
            return screens[_currentIndex];
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
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
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
          _row('أحدث الإضافات', apps.take(10).toList()),
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

  const SearchScreen({super.key, required this.apps});

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
    final q = _query.trim().toLowerCase();
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
          const SizedBox(height: 16),
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
  bool _expandedDescription = false;
  bool _showPinnedInstall = false;

  AppItem get app => widget.app;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final shouldPin = _scrollController.offset > 420;
      if (shouldPin != _showPinnedInstall) {
        setState(() => _showPinnedInstall = shouldPin);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _download() async {
    final ok = await launchUrl(
      Uri.parse(app.apkUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر فتح رابط التحميل')),
      );
    }
  }

  void _openImage(String url) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(8),
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
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
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: kBrand,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
        onPressed: app.apkUrl.isEmpty ? null : _download,
        child: const Text(
          'تثبيت',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

    if (app.rating > 0) {
      addStat(Icons.star, app.ratingLabel, 'التقييم');
    }
    if (app.downloads > 0) {
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

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: kBrandLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 12,
              color: kBrand,
              fontWeight: FontWeight.w600)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final description = app.longDescription.isNotEmpty
        ? app.longDescription
        : app.shortDescription;
    final shots = app.screenshotUrls;
    final kind = app.isGame ? 'لعبة' : 'تطبيق';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: kBrand,
        foregroundColor: Colors.white,
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
                      color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (_showPinnedInstall)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: SizedBox(
                width: 100,
                height: 36,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: kBrand,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  onPressed: app.apkUrl.isEmpty ? null : _download,
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
                AppIcon(app: app, size: 80),
                const SizedBox(width: 16),
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
                      const SizedBox(height: 4),
                      if (app.developer.isNotEmpty)
                        Text(
                          app.developer,
                          style: const TextStyle(
                              fontSize: 13,
                              color: kBrand,
                              fontWeight: FontWeight.w600),
                        )
                      else if (app.genre.isNotEmpty)
                        Text(
                          app.genre,
                          style: const TextStyle(
                              fontSize: 13,
                              color: kBrand,
                              fontWeight: FontWeight.w600),
                        ),
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

          // ─── لقطات الشاشة (مقاس موحّد يتكيف مع عرض الشاشة) ───
          if (shots.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: LayoutBuilder(
                builder: (context, c) {
                  final w = (c.maxWidth * 0.42).clamp(130.0, 210.0);
                  final h = w * 16 / 9;
                  return SizedBox(
                    height: h,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: shots.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) => GestureDetector(
                        onTap: () => _openImage(shots[i]),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: SizedBox(
                            width: w,
                            height: h,
                            child: Image.network(
                              shots[i],
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  color: kSurface,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: kBrand),
                                  ),
                                );
                              },
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.image_not_supported,
                                    color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

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
                : GestureDetector(
                    onTap: () => setState(
                        () => _expandedDescription = !_expandedDescription),
                    child: Text(
                      description,
                      maxLines: _expandedDescription ? null : 5,
                      overflow: _expandedDescription
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14, height: 1.6, color: Colors.black87),
                    ),
                  ),
          ),

          // ─── وسوم ───
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (app.genre.isNotEmpty) _tag(app.genre),
                _tag(kind),
                if (app.rating > 0) _tag('⭐ ${app.ratingLabel}'),
                if (app.ageRating.isNotEmpty) _tag(app.ageRating),
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
                _infoChip(Icons.straighten, 'الحجم', app.sizeLabel),
                if (app.dateLabel.isNotEmpty)
                  _infoChip(Icons.update, 'آخر تحديث', app.dateLabel),
                if (app.packageName.isNotEmpty)
                  _infoChip(Icons.android, 'الحزمة', app.packageName),
              ],
            ),
          ),

          // ─── الأمان ───
          _section(
            'الأمان',
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_user,
                          size: 20, color: kBrand),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'تم التحقق من البيانات',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'يتم تحميل الملف من مصدر مباشر وموثوق. يمكنك التحقق من البصمة أدناه.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  if (app.sha256.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.fingerprint,
                              size: 16, color: Colors.black45),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text(
                                app.sha256,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                    color: Colors.black54),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'نسخ',
                            icon: const Icon(Icons.copy, size: 16),
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: app.sha256));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('تم نسخ البصمة')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
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

          // ─── بطاقة معلومات الأمان الإضافية ───
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined,
                      color: kBrand, size: 22),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'هذا التطبيق يتبع سياسة الأمان لدينا. لا يتم جمع أي بيانات شخصية.',
                      style: TextStyle(
                          fontSize: 12, color: Colors.black54, height: 1.4),
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
  }
}
