#!/usr/bin/env python3
"""يُشغَّل بعد: flutter create . --platforms android
يعدّل ملفات الأندرويد المولّدة:
  - صلاحية الإنترنت + queries لفتح روابط التحميل
  - اسم التطبيق الظاهر
  - minSdk = 23 (مطلوب لعرض فيديو يوتيوب)
  - التوقيع من android/key.properties إن وُجد (وإلا يُستخدم مفتاح debug)
آمن للتشغيل أكثر من مرة.
"""
import re
import sys
from pathlib import Path

APP_LABEL = "متجري الرقمي"
MIN_SDK = "23"

root = Path("android")
manifest = root / "app/src/main/AndroidManifest.xml"
if not manifest.exists():
    sys.exit("android/ غير موجود. شغّل أولاً: flutter create . --platforms android")

# ───────── AndroidManifest.xml ─────────
m = manifest.read_text(encoding="utf-8")

if "android.permission.INTERNET" not in m:
    m = re.sub(
        r"(<manifest[^>]*>)",
        r'\1\n    <uses-permission android:name="android.permission.INTERNET"/>',
        m, count=1)

if "<queries>" not in m:
    queries = (
        "\n    <queries>\n"
        "        <intent>\n"
        '            <action android:name="android.intent.action.VIEW"/>\n'
        '            <data android:scheme="https"/>\n'
        "        </intent>\n"
        "    </queries>\n"
    )
    m = m.replace("</manifest>", queries + "</manifest>")

m = re.sub(r'android:label="[^"]*"', f'android:label="{APP_LABEL}"', m, count=1)
manifest.write_text(m, encoding="utf-8")

# ───────── build.gradle(.kts) ─────────
kts = root / "app/build.gradle.kts"
groovy = root / "app/build.gradle"
gradle = kts if kts.exists() else groovy
if not gradle.exists():
    sys.exit("لم أجد android/app/build.gradle(.kts)")
g = gradle.read_text(encoding="utf-8")
is_kts = gradle == kts

if "keystoreProperties" not in g:
    # minSdk
    g = re.sub(r"minSdk(Version)?\s*=\s*flutter\.minSdkVersion", f"minSdk = {MIN_SDK}", g)
    g = re.sub(r"minSdkVersion\s+flutter\.minSdkVersion", f"minSdkVersion {MIN_SDK}", g)
    if is_kts:
        g = g.replace("minSdk = flutter.minSdkVersion", f"minSdk = {MIN_SDK}")

    if is_kts:
        load = (
            "val keystoreProperties = Properties()\n"
            'val keystorePropertiesFile = rootProject.file("key.properties")\n'
            "if (keystorePropertiesFile.exists()) {\n"
            "    keystoreProperties.load(FileInputStream(keystorePropertiesFile))\n"
            "}\n\n"
        )
        signing = (
            "    signingConfigs {\n"
            '        create("release") {\n'
            "            if (keystorePropertiesFile.exists()) {\n"
            '                keyAlias = keystoreProperties["keyAlias"] as String\n'
            '                keyPassword = keystoreProperties["keyPassword"] as String\n'
            '                storeFile = file(keystoreProperties["storeFile"] as String)\n'
            '                storePassword = keystoreProperties["storePassword"] as String\n'
            "            }\n"
            "        }\n"
            "    }\n\n"
        )
        g = re.sub(r'signingConfig\s*=\s*signingConfigs\.getByName\("debug"\)',
                   'signingConfig = if (keystorePropertiesFile.exists()) '
                   'signingConfigs.getByName("release") else signingConfigs.getByName("debug")', g)
    else:
        load = (
            "def keystoreProperties = new Properties()\n"
            "def keystorePropertiesFile = rootProject.file('key.properties')\n"
            "if (keystorePropertiesFile.exists()) {\n"
            "    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))\n"
            "}\n\n"
        )
        signing = (
            "    signingConfigs {\n"
            "        release {\n"
            "            if (keystorePropertiesFile.exists()) {\n"
            "                keyAlias keystoreProperties['keyAlias']\n"
            "                keyPassword keystoreProperties['keyPassword']\n"
            "                storeFile file(keystoreProperties['storeFile'])\n"
            "                storePassword keystoreProperties['storePassword']\n"
            "            }\n"
            "        }\n"
            "    }\n\n"
        )
        g = re.sub(r"signingConfig\s+signingConfigs\.debug",
                   "signingConfig keystorePropertiesFile.exists() ? "
                   "signingConfigs.release : signingConfigs.debug", g)

    if is_kts:  # الاستيراد يجب أن يكون في أول الملف تمامًا
        g = "import java.io.FileInputStream\nimport java.util.Properties\n\n" + g
    # قراءة key.properties قبل كتلة android
    g, n1 = re.subn(r"(?m)^android\s*\{", lambda mo: load + "android {", g, count=1)
    # كتلة التوقيع قبل buildTypes
    g, n2 = re.subn(r"(?m)^(\s*)buildTypes\s*\{", lambda mo: signing + mo.group(0), g, count=1)
    if not (n1 and n2):
        sys.exit("تعذّر تعديل ملف gradle تلقائياً (بنية غير متوقعة).")
    gradle.write_text(g, encoding="utf-8")

print("تم تجهيز مشروع الأندرويد ✔")
