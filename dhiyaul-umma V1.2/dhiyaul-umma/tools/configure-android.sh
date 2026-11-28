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

# Ikon kecil notifikasi (siluet sujud, putih transparan) -> res/drawable-*
for d in mdpi hdpi xhdpi xxhdpi xxxhdpi; do
  mkdir -p android/app/src/main/res/drawable-$d
  cp "assets/notif/ic_stat_sujud_$d.png" "android/app/src/main/res/drawable-$d/ic_stat_sujud.png"
done

# Saluran adzan memakai aliran ALARM (volume keras, mengikuti volume alarm, tidak mudah terpotong)
MA=$(find android/app/src/main/java -name MainActivity.java | head -1)
if [ -n "$MA" ]; then
PKG=$(grep -m1 '^package' "$MA" | sed 's/package //; s/;//')
cat > "$MA" <<JAVA
package $PKG;

import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.media.AudioAttributes;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import com.getcapacitor.BridgeActivity;

public class MainActivity extends BridgeActivity {
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        makeAzanChannels();
    }

    private void makeAzanChannels() {
        if (Build.VERSION.SDK_INT < 26) return;
        NotificationManager nm = getSystemService(NotificationManager.class);
        if (nm == null) return;
        makeChannel(nm, "azan_v3", "Adzan (Dzuhur, Ashar, Maghrib, Isya)", "adzan");
        makeChannel(nm, "azan_subuh_v3", "Adzan Subuh", "adzan_subuh");
    }

    private void makeChannel(NotificationManager nm, String id, String name, String raw) {
        int res = getResources().getIdentifier(raw, "raw", getPackageName());
        if (res == 0) return;
        Uri sound = Uri.parse("android.resource://" + getPackageName() + "/" + res);
        AudioAttributes aa = new AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build();
        NotificationChannel ch = new NotificationChannel(id, name, NotificationManager.IMPORTANCE_HIGH);
        ch.setDescription("Suara adzan saat masuk waktu sholat");
        ch.setSound(sound, aa);
        ch.enableVibration(true);
        ch.setLockscreenVisibility(1);
        nm.createNotificationChannel(ch);
    }
}
JAVA
echo "MainActivity: saluran adzan (alarm) dipasang"
fi

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
