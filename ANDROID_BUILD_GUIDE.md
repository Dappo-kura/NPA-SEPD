# Android APK ビルドガイド — NPA-SEPD

## 概要

GodotエディタのヘッドレスエクスポートはAndroidでは動作しないため、
`android_source.zip` テンプレートを使った **Gradleビルド方式** を採用している。

---

## 必要なツール・パス（確認済み）

| ツール | パス |
|--------|------|
| Java (JBR) | `C:/Program Files/Android/Android Studio/jbr/bin/` |
| Android SDK | `C:/Users/datepo/AppData/Local/Android/Sdk/` |
| Build Tools | `C:/Users/datepo/AppData/Local/Android/Sdk/build-tools/35.0.0/` |
| デバッグキーストア | `C:/Users/datepo/.android/debug.keystore` |
| Godot export templates | `C:/Users/datepo/AppData/Roaming/Godot/export_templates/4.5.1.stable/` |
| Gradleビルドディレクトリ | `C:/Users/datepo/AppData/Local/Temp/godot_android_build/` |

### デバッグキーストアの情報
- alias: `androiddebugkey`
- storepass/keypass: `android`

---

## ビルド手順

### Step 1: ビルドディレクトリのセットアップ（初回 or 環境が壊れたとき）

```python
# extract_and_build.py を実行
# android_source.zip を godot_android_build/ に展開する
import zipfile, shutil, os

src_zip = 'C:/Users/datepo/AppData/Roaming/Godot/export_templates/4.5.1.stable/android_source.zip'
build_dir = 'C:/Users/datepo/AppData/Local/Temp/godot_android_build'

if os.path.exists(build_dir):
    shutil.rmtree(build_dir)
os.makedirs(build_dir)

with zipfile.ZipFile(src_zip, 'r') as z:
    z.extractall(build_dir)
```

展開後、**必ず以下の追加設定を適用すること**（次のセクション参照）。

---

### Step 2: ビルドディレクトリへの必須修正

> ⚠️ この修正をしないと動作しない。再展開するたびに必要。

#### 2-A: `build.gradle` — PCKを非圧縮に設定

`godot_android_build/build.gradle` の `defaultConfig` 内の `aaptOptions` ブロックを探して
`noCompress '.pck'` を追加する：

```groovy
aaptOptions {
    ignoreAssetsPattern "!.svn:!.git:!.gitignore:!.ds_store:!*.scc:<dir>_*:!CVS:!thumbs.db:!picasa.ini:!*~"
    noCompress '.pck'   // ← この行を追加
}
```

**理由**: GodotエンジンはPCKファイルをメモリマップで読むため、非圧縮必須。
圧縮されていると "Couldn't load project data at path '.'" エラーが出る。

#### 2-B: `src/com/godot/game/GodotApp.java` — `--main-pack` を渡す

ファイル全体を以下の内容に置き換える：

```java
package com.godot.game;

import org.godotengine.godot.Godot;
import org.godotengine.godot.GodotActivity;

import android.os.Bundle;
import android.util.Log;

import androidx.activity.EdgeToEdge;
import androidx.core.splashscreen.SplashScreen;

import java.util.ArrayList;
import java.util.List;

public class GodotApp extends GodotActivity {
    static {
        if (BuildConfig.FLAVOR.equals("mono")) {
            try {
                Log.v("GODOT", "Loading System.Security.Cryptography.Native.Android library");
                System.loadLibrary("System.Security.Cryptography.Native.Android");
            } catch (UnsatisfiedLinkError e) {
                Log.e("GODOT", "Unable to load System.Security.Cryptography.Native.Android library");
            }
        }
    }

    private final Runnable updateWindowAppearance = () -> {
        Godot godot = getGodot();
        if (godot != null) {
            godot.enableImmersiveMode(godot.isInImmersiveMode(), true);
            godot.enableEdgeToEdge(godot.isInEdgeToEdgeMode(), true);
            godot.setSystemBarsAppearance();
        }
    };

    @Override
    public void onCreate(Bundle savedInstanceState) {
        SplashScreen.installSplashScreen(this);
        EdgeToEdge.enable(this);
        super.onCreate(savedInstanceState);
    }

    @Override
    public void onResume() {
        super.onResume();
        updateWindowAppearance.run();
    }

    @Override
    public void onGodotMainLoopStarted() {
        super.onGodotMainLoopStarted();
        runOnUiThread(updateWindowAppearance);
    }

    // PCKファイルのパスを明示的に渡す
    // これがないとGodot 4.5 Androidは "--main-pack" を設定しないため
    // "Couldn't load project data at path '.'" エラーが発生する
    @Override
    public List<String> getCommandLine() {
        List<String> commandLine = new ArrayList<>(super.getCommandLine());
        commandLine.add("--main-pack");
        commandLine.add("res://NPA-SEPD.pck");
        return commandLine;
    }
}
```

**理由**: Godot 4.5のAndroid実装はOBBファイルがない場合`--main-pack`を自動設定しない。
`res://NPA-SEPD.pck` は `assets/NPA-SEPD.pck` にマップされる。

#### 2-C: `res/values*/godot_project_name_string.xml` — アプリ名修正

`res/` 以下の全42ファイルのアプリ名を修正する（Pythonで一括）：

```python
import os

build_dir = 'C:/Users/datepo/AppData/Local/Temp/godot_android_build'
xml_content = '''<?xml version="1.0" encoding="utf-8"?>
<!-- WARNING: THIS FILE WILL BE OVERWRITTEN AT BUILD TIME-->
<resources>
    <string name="godot_project_name_string">NPA-SEPD</string>
</resources>
'''

for root, dirs, files in os.walk(build_dir + '/res'):
    for f in files:
        if f == 'godot_project_name_string.xml':
            with open(os.path.join(root, f), 'w', encoding='utf-8') as fp:
                fp.write(xml_content)
```

**理由**: デフォルトは "godot-project-name-ja" になっているため修正必要。

---

### Step 3: PCKファイルのエクスポート

Godot で PCK を事前にエクスポートしておく：

```
Godot_v4.5.1-stable_win64.exe --headless --export-pack "Android" "C:/Users/datepo/AppData/Local/Temp/NPA-SEPD.pck" --path "C:/Users/datepo/OneDrive/ドキュメント/NPA-SEPD"
```

または `C:/Users/datepo/AppData/Local/Temp/run_gradle.py` の前に手動エクスポートしてから実行。

---

### Step 4: PCKをassetsにコピー

```python
import shutil
shutil.copy2(
    'C:/Users/datepo/AppData/Local/Temp/NPA-SEPD.pck',
    'C:/Users/datepo/AppData/Local/Temp/godot_android_build/assets/NPA-SEPD.pck'
)
```

---

### Step 5: Gradleビルド実行

```python
import subprocess, os

build_dir = 'C:/Users/datepo/AppData/Local/Temp/godot_android_build'
java_bin = 'C:/Program Files/Android/Android Studio/jbr/bin'
android_sdk = 'C:/Users/datepo/AppData/Local/Android/Sdk'
keystore = 'C:/Users/datepo/.android/debug.keystore'

env = os.environ.copy()
env['PATH'] = java_bin + ';' + env.get('PATH', '')
env['JAVA_HOME'] = 'C:/Program Files/Android/Android Studio/jbr'
env['ANDROID_SDK_ROOT'] = android_sdk
env['ANDROID_HOME'] = android_sdk

cmd = [
    build_dir + '/gradlew.bat',
    'assembleDebug',
    '--no-daemon',
    '-Pexport_package_name=com.npasepd.game',
    '-Pexport_version_name=1.0',
    '-Pexport_version_code=1',
    '-Pexport_enabled_abis=arm64-v8a',
    '-Pgodot_editor_version=4.5.1.stable',
    '-Pperform_signing=true',
    '-Pperform_zipalign=true',
    f'-Pdebug_keystore_file={keystore}',
    '-Pdebug_keystore_password=android',
    '-Pdebug_keystore_alias=androiddebugkey',
]

result = subprocess.run(cmd, env=env, cwd=build_dir,
                        capture_output=True, text=True,
                        encoding='utf-8', errors='replace', timeout=300)
print(result.stdout[-3000:])
print(result.stderr[-1000:])
print('Exit:', result.returncode)
```

ビルド成功時: `BUILD SUCCESSFUL` が表示される（初回約2分、2回目以降約15秒）。

---

### Step 6: APKをコピー

```python
import shutil
shutil.copy2(
    'C:/Users/datepo/AppData/Local/Temp/godot_android_build/build/outputs/apk/standard/debug/android_debug.apk',
    'C:/Users/datepo/Documents/NPA-SEPD-debug.apk'
)
```

---

## 通常ビルド（2回目以降）

ビルドディレクトリがすでに設定済みの場合は **Step 3〜6 だけ** 実行すればよい。

```
Step 3: PCKエクスポート
Step 4: PCKをassetsにコピー
Step 5: Gradleビルド
Step 6: APKをDocumentsにコピー
```

---

## トラブルシューティング

### ❌ "Couldn't load project data at path '.'"

**原因A**: `GodotApp.java` に `getCommandLine()` オーバーライドがない
→ **対処**: Step 2-B を適用

**原因B**: `assets/NPA-SEPD.pck` がAPK内で圧縮されている
→ **対処**: Step 2-A (`noCompress '.pck'`) を適用し再ビルド

---

### ❌ "アプリがインストールされていません"

**原因**: APKが署名されていない
→ **対処**: Gradleコマンドに `-Pperform_signing=true` と `-Pdebug_keystore_file=` を追加

---

### ❌ アプリ名が "godot-project-name-ja"

**原因**: `res/values-ja/godot_project_name_string.xml` が未修正
→ **対処**: Step 2-C のPythonスクリプトを実行してから再ビルド

---

### ❌ `apksigner: ZIP End of Central Directory record not found`

**原因**: PCKをZIPのEOCD（終端）の後ろに追記してからapksignerを実行しようとした
→ **対処**: `apksigner` を実行する前にPCKを追記してはいけない。
　　　　本ガイドのassetsベース方式（Step 2-A + 2-B）を使うこと

---

### ❌ ビルドディレクトリが壊れた / 初回セットアップ

→ Step 1（再展開）→ Step 2（必須修正3つ）→ Step 3〜6 の順に実行

---

## 技術的背景メモ

### なぜGodotエディタのヘッドレスエクスポートは使えないか
Godot 4.5 の `--export-debug` はAndroid設定エラーをGUIシステムにしか出力しないため、
ヘッドレスモードでは常に「設定エラー（メッセージなし）」で失敗する。

### なぜ `--main-pack` の手動設定が必要か
Godot 4.5の`Godot.java`（AARライブラリ）は、`--use_apk_expansion` フラグと
有効なOBBファイルが存在する場合だけ `--main-pack` を自動設定する。
OBBを使わないビルドでは、ネイティブエンジンが実行パス `"."` でPCKを探して失敗する。

### PCKが非圧縮でなければならない理由
AndroidのAssetManagerはランダムアクセス（シーク）が必要なファイルには
非圧縮（STORED）が必要。GodotのPCK読み込みはシークを多用するため、
deflate圧縮されたPCKは読み込めない。
