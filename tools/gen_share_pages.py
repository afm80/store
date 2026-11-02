#!/usr/bin/env python3
"""يولّد صفحات مشاركة ثابتة لكل تطبيق داخل build/web/s/<package>/
حتى تظهر الأيقونة والاسم والوصف عند مشاركة الرابط (واتساب، تيليجرام، فيسبوك...).

السبب: الروابط التي تحتوي # لا تصل للسيرفر، والمنصات لا تشغّل جافاسكربت،
لذلك نحتاج صفحة حقيقية لكل تطبيق فيها وسوم Open Graph ثم تحوّل الزائر للمتجر.
"""
import html
import json
import os
import re
import shutil
import sys
from urllib.parse import quote

STORE_URL = os.environ.get("STORE_URL", "https://alfahamstore.web.app").rstrip("/")
OUT = os.environ.get("OUT_DIR", "build/web")
APPS = "data/apps.json"
SITE_NAME = "Alfaham Store"
DEFAULT_DESC = "متجر تطبيقات الفحام — تحميل مباشر وآمن"

try:
    from PIL import Image
except Exception:  # Pillow غير متوفر: ننسخ الأيقونة كما هي
    Image = None


def esc(s):
    return html.escape(str(s or ""), quote=True)


def describe(app):
    for key in ("shortDescription", "longDescription"):
        t = re.sub(r"\s+", " ", str(app.get(key) or "")).strip()
        if t:
            return t if len(t) <= 160 else t[:157].rstrip() + "..."
    return DEFAULT_DESC


def make_icon(src, dst_png):
    """يحوّل الأيقونة إلى PNG مربع بحجم لا يتجاوز 512 (صيغة تدعمها كل المنصات)."""
    if Image is None:
        shutil.copyfile(src, dst_png)
        return True
    try:
        im = Image.open(src).convert("RGBA")
        im.thumbnail((512, 512))
        im.save(dst_png, "PNG", optimize=True)
        return True
    except Exception as e:
        print(f"  ! تعذّر تحويل {src}: {e}")
        return False


PAGE = """<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{title} - {site}</title>
<meta name="description" content="{desc}">
<meta property="og:type" content="website">
<meta property="og:site_name" content="{site}">
<meta property="og:title" content="{title}">
<meta property="og:description" content="{desc}">
<meta property="og:url" content="{page_url}">
{image_tags}<meta name="twitter:card" content="summary">
<meta name="twitter:title" content="{title}">
<meta name="twitter:description" content="{desc}">
{twitter_image}<link rel="canonical" href="{page_url}">
<meta http-equiv="refresh" content="0; url={target}">
<script>location.replace({target_js});</script>
</head>
<body style="font-family:sans-serif;text-align:center;padding:40px">
<p><a href="{target}">{title}</a></p>
</body>
</html>
"""


def main():
    if not os.path.isfile(APPS):
        print("لا يوجد data/apps.json")
        return 0
    with open(APPS, encoding="utf-8") as f:
        apps = json.load(f)
    if not isinstance(apps, list):
        return 0

    count = 0
    for app in apps:
        if not isinstance(app, dict) or app.get("hidden") is True:
            continue
        pkg = str(app.get("packageName") or "").strip()
        name = str(app.get("name") or "").strip()
        if not pkg or not name or not re.fullmatch(r"[A-Za-z0-9._-]+", pkg):
            continue

        folder = os.path.join(OUT, "s", pkg)
        os.makedirs(folder, exist_ok=True)

        image_tags = ""
        twitter_image = ""
        icon = str(app.get("icon") or "")
        if icon and not icon.startswith("http") and os.path.isfile(icon):
            if make_icon(icon, os.path.join(folder, "icon.png")):
                img = f"{STORE_URL}/s/{quote(pkg)}/icon.png"
                image_tags = (
                    f'<meta property="og:image" content="{esc(img)}">\n'
                    '<meta property="og:image:type" content="image/png">\n'
                    '<meta property="og:image:width" content="512">\n'
                    '<meta property="og:image:height" content="512">\n'
                )
                twitter_image = f'<meta name="twitter:image" content="{esc(img)}">\n'
        elif icon.startswith("http"):
            image_tags = f'<meta property="og:image" content="{esc(icon)}">\n'
            twitter_image = f'<meta name="twitter:image" content="{esc(icon)}">\n'

        target = f"{STORE_URL}/#/app/{quote(pkg)}"
        page = PAGE.format(
            title=esc(name),
            site=esc(SITE_NAME),
            desc=esc(describe(app)),
            page_url=esc(f"{STORE_URL}/s/{quote(pkg)}/"),
            image_tags=image_tags,
            twitter_image=twitter_image,
            target=esc(target),
            target_js=json.dumps("/#/app/" + quote(pkg)),
        )
        with open(os.path.join(folder, "index.html"), "w", encoding="utf-8") as f:
            f.write(page)
        count += 1

    # وسوم المشاركة للصفحة الرئيسية للمتجر
    index = os.path.join(OUT, "index.html")
    if os.path.isfile(index):
        with open(index, encoding="utf-8") as f:
            src = f.read()
        if 'property="og:title"' not in src and "</head>" in src:
            tags = (
                f'<meta property="og:type" content="website">\n'
                f'<meta property="og:site_name" content="{SITE_NAME}">\n'
                f'<meta property="og:title" content="{SITE_NAME}">\n'
                f'<meta property="og:description" content="{DEFAULT_DESC}">\n'
                f'<meta property="og:url" content="{STORE_URL}/">\n'
                f'<meta property="og:image" content="{STORE_URL}/icons/Icon-512.png">\n'
                f'<meta name="twitter:card" content="summary">\n'
            )
            src = src.replace("</head>", tags + "</head>", 1)
            with open(index, "w", encoding="utf-8") as f:
                f.write(src)

    print(f"تم توليد {count} صفحة مشاركة في {OUT}/s/")
    return 0


if __name__ == "__main__":
    sys.exit(main())
