# متجري الرقمي

متجر تطبيقات أندرويد شخصي يشبه Google Play، **مجاني بالكامل**:

| المكوّن | أين يُحفظ |
|---|---|
| واجهة المتجر | Firebase Hosting: `https://alfahamstore.web.app` |
| لوحة التحكم | ملف `admin.html` على جهازك فقط (خارج المشروع ولا يُرفع) |
| ملفات APK | GitHub Releases (حتى 2 جيجابايت للملف) |
| الأيقونات واللقطات | مجلد `data/media/` في مستودع `afm80/store` |
| بيانات التطبيقات | الملف `data/apps.json` في نفس المستودع |

لا يوجد خادم ولا قاعدة بيانات. اللوحة تتحدث مع GitHub API من المتصفح، والمتجر يقرأ `apps.json` مباشرة.

## 1) رفع المشروع إلى GitHub

يجب أن يكون المستودع `afm80/store` **عامًا (Public)** ليقرأ المتجر ملفاته.

```bash
git init -b main
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/afm80/store.git
git push -u origin main
```

## 2) تجهيز Flutter (مرة واحدة)

```bash
flutter create . --platforms web --project-name apps_store
flutter pub get
```

إن استبدل الأمر ملف `lib/main.dart` بنسخة تجريبية فأعد نسخ ملفات `lib/` من المشروع الأصلي.

ثم طبّق أيقونة المتجر على الموقع (بعد `flutter create` مباشرة):

```bash
cp brand/favicon.png web/favicon.png
cp brand/icons/*.png web/icons/
```

الشعار داخل التطبيق هو `assets/logo.png`. لتغيير الأيقونة لاحقًا استبدل هذه الملفات بنفس الأسماء وأعد النشر.

## 3) النشر على Firebase Hosting

```bash
npm i -g firebase-tools
firebase login
flutter build web --release
firebase deploy --only hosting
```

بعدها يعمل الرابط `https://alfahamstore.web.app`. وعند أي تعديل في كود المتجر كرّر آخر أمرين فقط.
(نشر تطبيقات جديدة من لوحة التحكم لا يحتاج إعادة نشر.)

## 4) رمز الوصول (Token)

GitHub ← Settings ← Developer settings ← Personal access tokens ← **Fine-grained tokens**:
- Repository access: *Only select repositories* ← `afm80/store` فقط.
- Permissions ← Repository ← **Contents: Read and write**.
- ضع مدة انتهاء مناسبة.

## 5) نشر تطبيق

1. افتح ملف `admin.html` بالنقر المزدوج عليه. يعمل مباشرة من جهازك، ولا يُرفع مع المشروع.
2. من "إعدادات GitHub" الصق الرمز، واضغط **حفظ** ثم **اختبار الاتصال**.
3. املأ الخطوات الثلاث واضغط **نشر**.
4. يظهر التطبيق في المتجر خلال دقائق (التخزين المؤقت لدى GitHub حتى 5 دقائق). زر التحديث في المتجر يعيد القراءة.

من تبويب **تطبيقاتي** تعدّل أو تحذف. نشر نفس البكج بإصدار جديد يحدّث التطبيق.

## ملاحظات مهمة

- **الرمز** يُحفظ في متصفح جهازك فقط. لا تضعه في أي ملف ولا ترفعه. إن تسرّب فاحذفه فورًا من إعدادات GitHub.
- رابط المتجر عام. أما لوحة التحكم فعلى جهازك فقط، ولا يستطيع أحد فتحها غيرك. احتفظ بنسخة من `admin.html`.
- إذا تعذّر رفع الـ APK من المتصفح، تنشئ اللوحة صفحة الإصدار؛ أرفق الملف بها يدويًا من GitHub ثم الصق رابطه في خانة "رابط APK خارجي" وأعد النشر.
- حجم أي ملف داخل المستودع (الصور) أقل من 100 ميجابايت، ويُفضّل أن تبقى صغيرة.
- على الأندرويد يحتاج المستخدم إلى السماح بالتثبيت من مصادر غير معروفة. وزّع التطبيق من رابطك وليس عبر Google Play.
- بصمة SHA-256 تظهر في صفحة كل تطبيق ليتحقق المستخدم من سلامة الملف.

## بنية المشروع

```
lib/                 كود المتجر (Flutter)
assets/logo.png      شعار المتجر
brand/               أيقونات الموقع (favicon وأيقونات التثبيت)
data/apps.json       قاعدة بيانات التطبيقات
data/media/          الأيقونات واللقطات
firebase.json        إعداد الاستضافة
.firebaserc          مشروع Firebase: alfahamstore
```
