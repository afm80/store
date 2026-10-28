import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models.dart';
import 'store_service.dart';

const Color kBrand = Color(0xFF075C55);
const Color kBrandLight = Color(0xFFD3E8E5);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'متجري الرقمي',
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
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        textTheme: GoogleFonts.cairoTextTheme(),
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

// -------------------------------------------------------------
// الهيكل الأساسي: الهيدر، الشريط السفلي، القائمة الجانبية
// -------------------------------------------------------------
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
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
    } catch (_) {
      // يظهر الخطأ في الواجهة.
    }
  }

  void _push(Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset('assets/logo.png', width: 34, height: 34),
            ),
            const SizedBox(width: 10),
            const Text(
              'متجري الرقمي',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'تحديث القائمة',
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _reload,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: kBrand),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                    child: Image(
                      image: AssetImage('assets/logo.png'),
                      width: 60,
                      height: 60,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'متجري الرقمي للـ APK',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'تحميل مباشر وآمن',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
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
              HomeScreen(apps: apps, onRefresh: _reload),
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
              message: snapshot.error.toString().replaceFirst('Exception: ', ''),
              onRetry: _reload,
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: kBrand,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.apps_outlined),
            activeIcon: Icon(Icons.apps),
            label: 'تطبيقات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_esports_outlined),
            activeIcon: Icon(Icons.sports_esports),
            label: 'ألعاب',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'بحث',
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// عناصر مشتركة
// -------------------------------------------------------------
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: SizedBox(
        width: size,
        height: size,
        child: app.icon.isEmpty
            ? _fallback()
            : Image.network(
                app.iconUrl,
                fit: BoxFit.cover,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () => openApp(context, app),
        contentPadding: const EdgeInsetsDirectional.only(start: 12, end: 12),
        leading: AppIcon(app: app, size: 50),
        title: Text(
          app.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          app.shortDescription.isEmpty ? subtitle : '${app.shortDescription}\n$subtitle',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: kBrand,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () => openApp(context, app),
          child: const Text('عرض'),
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

// -------------------------------------------------------------
// الشاشات الأساسية (الرئيسية، تطبيقات/ألعاب، بحث)
// -------------------------------------------------------------
class HomeScreen extends StatelessWidget {
  final List<AppItem> apps;
  final Future<void> Function() onRefresh;

  const HomeScreen({super.key, required this.apps, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (apps.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: const EmptyView(text: 'لا توجد تطبيقات بعد، أضف أول تطبيق من لوحة التحكم'),
      );
    }

    final featured = apps.where((a) => a.featured).toList();
    final highlighted = featured.isNotEmpty ? featured : apps.take(6).toList();

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          const Text('تطبيقات مميزة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: highlighted.length,
              itemBuilder: (context, index) {
                final app = highlighted[index];
                return GestureDetector(
                  onTap: () => openApp(context, app),
                  child: Container(
                    width: 130,
                    margin: const EdgeInsetsDirectional.only(end: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 5)],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppIcon(app: app, size: 60),
                        const SizedBox(height: 8),
                        Text(
                          app.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(app.sizeLabel,
                            style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          const Text('أحدث الإضافات',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          for (final app in apps.take(10)) AppTile(app: app),
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
  Widget build(BuildContext context) {
    final genres = widget.apps
        .map((a) => a.genre)
        .where((g) => g.isNotEmpty)
        .toSet()
        .toList();
    final selected = genres.contains(_genre) ? _genre : null;
    final shown =
        selected == null ? widget.apps : widget.apps.where((a) => a.genre == selected).toList();

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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: ChoiceChip(
                    label: const Text('الكل'),
                    selected: selected == null,
                    onSelected: (_) => setState(() => _genre = null),
                  ),
                ),
                for (final g in genres)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                      label: Text(g),
                      selected: selected == g,
                      onSelected: (_) => setState(() => _genre = g),
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
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'ابحث عن تطبيق أو لعبة...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
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

// -------------------------------------------------------------
// صفحات القائمة الجانبية
// -------------------------------------------------------------
class InfoPage extends StatelessWidget {
  final String title;
  final String text;

  const InfoPage({super.key, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(text, style: const TextStyle(fontSize: 16, height: 1.6)),
      ),
    );
  }
}

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اتصل بنا')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('إذا كان لديك أي تطبيق تريد إضافته أو واجهتك مشكلة، تواصل معنا عبر:',
                style: TextStyle(fontSize: 16)),
            SizedBox(height: 15),
            Text('• تليجرام: @YourChannel',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kBrand)),
            SizedBox(height: 10),
            Text('• البريد الإلكتروني: support@store.com',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// صفحة تفاصيل التطبيق
// -------------------------------------------------------------
class AppDetailsScreen extends StatelessWidget {
  final AppItem app;

  const AppDetailsScreen({super.key, required this.app});

  Future<void> _download(BuildContext context) async {
    final ok = await launchUrl(
      Uri.parse(app.apkUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر فتح رابط التحميل')),
      );
    }
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: SelectableText(value.isEmpty ? '—' : value),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final description =
        app.longDescription.isNotEmpty ? app.longDescription : app.shortDescription;
    final shots = app.screenshotUrls;

    return Scaffold(
      appBar: AppBar(title: Text(app.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (app.banner.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 2,
                child: Image.network(
                  app.bannerUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              AppIcon(app: app, size: 80),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(app.name,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (app.version.isNotEmpty) 'الإصدار: ${app.version}',
                        'الحجم: ${app.sizeLabel}',
                      ].join(' • '),
                      style: const TextStyle(color: Colors.grey),
                    ),
                    if (app.genre.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(app.genre,
                          style: TextStyle(color: kBrand, fontWeight: FontWeight.w600)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: kBrand,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: app.apkUrl.isEmpty ? null : () => _download(context),
              icon: const Icon(Icons.download),
              label: const Text('تحميل ملف APK مباشرة',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          if (shots.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text('لقطات الشاشة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SizedBox(
              height: 340,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: shots.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsetsDirectional.only(end: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      shots[i],
                      height: 340,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        width: 160,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image_not_supported, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (app.whatsNew.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text('ما الجديد',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(app.whatsNew, style: const TextStyle(color: Colors.black87, height: 1.5)),
          ],
          if (description.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text('وصف التطبيق',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(description, style: const TextStyle(color: Colors.black54, height: 1.6)),
          ],
          const SizedBox(height: 24),
          const Text('معلومات التطبيق',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          _infoRow('الحزمة', app.packageName),
          _infoRow('الإصدار', app.version),
          _infoRow('الحجم', app.sizeLabel),
          _infoRow('آخر تحديث', app.dateLabel),
          if (app.sha256.isNotEmpty) ...[
            _infoRow('SHA-256', app.sha256),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: app.sha256));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم نسخ البصمة')),
                  );
                },
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('نسخ البصمة للتحقق من الملف'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
