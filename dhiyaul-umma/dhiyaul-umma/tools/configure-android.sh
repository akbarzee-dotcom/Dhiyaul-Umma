#!/usr/bin/env bash
# Dijalankan setelah "npx cap add android": izin lokasi, orientasi potret, ikon, dan splash.
set -e
M=android/app/src/main/AndroidManifest.xml

if ! grep -q POST_NOTIFICATIONS "$M"; then
  sed -i 's#</manifest>#    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />\n    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />\n    <uses-permission android:name="android.permission.VIBRATE" />\n    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />\n    <uses-permission android:name="android.permission.USE_EXACT_ALARM" />\n    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" android:maxSdkVersion="32" />\n    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />\n</manifest>#' "$M"
fi
if ! grep -q screenOrientation "$M"; then
  sed -i '0,/<activity/s#<activity#<activity android:screenOrientation="portrait"#' "$M"
fi

# Suara adzan -> res/raw (nama harus huruf kecil/angka/underscore)
mkdir -p android/app/src/main/res/raw
for f in adzan adzan_subuh; do
  if [ -f "assets/audio/$f.mp3" ]; then cp "assets/audio/$f.mp3" "android/app/src/main/res/raw/$f.mp3"; echo "Suara $f.mp3 dimasukkan"; else echo "PERINGATAN: assets/audio/$f.mp3 tidak ditemukan, notifikasi memakai suara bawaan"; fi
done

pip install --quiet pillow || true
python3 - <<'PY' || echo "Ikon/splash dilewati (APK tetap dibuat dengan ikon bawaan)"
import os, glob
from PIL import Image
res = 'android/app/src/main/res'
icon = Image.open('assets/icon-192.png').convert('RGBA')
fg = Image.open('assets/icon-foreground.png').convert('RGBA')
legacy = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}
for d, px in legacy.items():
    folder = f'{res}/mipmap-{d}'
    if not os.path.isdir(folder): continue
    for name in ('ic_launcher.png', 'ic_launcher_round.png'):
        icon.resize((px, px), Image.LANCZOS).save(f'{folder}/{name}')
    f = int(px * 108 / 48)
    fg.resize((f, f), Image.LANCZOS).save(f'{folder}/ic_launcher_foreground.png')
os.makedirs(f'{res}/values', exist_ok=True)
open(f'{res}/values/ic_launcher_background.xml', 'w').write('<?xml version="1.0" encoding="utf-8"?>\n<resources>\n    <color name="ic_launcher_background">#022C22</color>\n</resources>\n')
logo = Image.open('assets/logo.png').convert('RGBA')
for p in glob.glob(f'{res}/drawable*/splash.png'):
    w, h = Image.open(p).size
    bg = Image.new('RGBA', (w, h), (2, 44, 34, 255))
    lw = int(min(w, h) * 0.42)
    l = logo.resize((lw, int(lw * logo.height / logo.width)), Image.LANCZOS)
    bg.alpha_composite(l, ((w - l.width) // 2, (h - l.height) // 2))
    bg.convert('RGB').save(p)
PY
