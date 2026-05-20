# NPA-SEPD 開発ログ

---

## 2026-05-20（本日）

### ジャンプスケアシステム刷新

#### 素材管理
- 素材置き場を `res://resources/jumpscare/` に統一
- `jumpscare_N.png` + `jumpscare_N.mp3` の連番ペア管理方式に変更
- 現在 `jumpscare_1` / `jumpscare_2` の 2 セット収録済み
- **追加方法**: ファイルを置くだけ。コード変更不要。

#### シェーダー刷新
- ノイズシェーダー（`noise.gdshader`）→ グリッチシェーダー（`glitch.gdshader`）に変更
- 水平ブロックずらし + RGB チャンネル分離 + スキャンライン
- `jump_scare.tscn` の `shader_parameter/intensity = 0.5`、`speed = 25.0` で調整可能

#### SE 音量フェードアウト
- 再生開始と同時に `volume_db: 0 → -80` を 3 秒でフェード
- `_set_audio_db()` メソッドで `tween_method` を使用（`tween_property` より安定）
- 演出終了時に `stop()` + `volume_db = 0.0` リセット

#### エクスポートビルド対応（重要）
- **原因**: `DirAccess.open("res://...")` はエクスポートビルド（PCK内）で `null` を返す
- **修正1**: `DirAccess` → `load()` による直接スキャンに変更
- **修正2**: 画像ロード失敗時も黒フラッシュ演出は必ず実行（トリガーとリソースを分離）

```gdscript
# 現在の trigger() ロジック
func trigger() -> void:
    if _is_playing:
        return
    var idx: int = -1
    if not _available_indices.is_empty():
        idx = _available_indices[randi() % _available_indices.size()]
    _play_effect(idx)  # idx=-1 でも演出は実行される
```

---

### UIFont AutoLoad 追加（恒久対応）

- `autoload/ui_font.gd` 新規作成
- `project.godot` に `UIFont` AutoLoad として登録
- 全 Control ノードに `HGRME.TTC` を適用（Web 版日本語豆腐の恒久対応）
- 前回 Web 版ビルド時は一時ビルドで対応していたが、今回から本体に組み込み

---

### Web 版更新

- `gh-pages` ブランチの `index.pck` を最新版に差し替え
- UIFont 対応・ジャンプスケア修正を含むビルドを反映
- 公開 URL: https://dappo-kura.github.io/NPA-SEPD/
- `.html`/`.js`/`.wasm` は変更なし（`index.pck` のみ差し替え）

---

### APK ビルド

- `C:/Users/datepo/Documents/NPA-SEPD-debug.apk` に出力（172.1 MB）
- ジャンプスケア演出の動作を実機確認済み

---

### GitHub コミット

| ハッシュ | 内容 |
|---------|------|
| `327a47e` | Add kaiki stills, glitch jumpscare, and web release |
| `dc3b0e5` | Fix jumpscare in exported builds, add UIFont AutoLoad |

---

## 次回の作業候補

### ジャンプスケア
- [ ] SE が聞こえるか実機再確認（`load()` でのロード可否）
- [ ] ジャンプスケア素材を増やす場合は `jumpscare_3.png` + `jumpscare_3.mp3` を置くだけ
- [ ] トリガー条件の見直し（現状: グリッド配置失敗 / タイムアップ）
- [ ] 演出の持続時間・強度の調整（ホールド 0.7 秒 → フェード 0.5 秒）

### UI / UX
- [ ] ItemTray 内のピース表示の最終確認
- [ ] HUD の見た目調整

### ゲームバランス
- [ ] 無限モードの難易度上昇（呪われたセルの強化）
- [ ] ギャラリー用 event_002〜021 画像の用意

### Web 版更新手順（次回から）
1. Godot エディタで変更・確認
2. 変更を `main` ブランチにコミット・プッシュ
3. `/build-android-apk` で APK ビルド（実機確認用）
4. Web 版更新: `index.pck` だけ差し替えて `gh-pages` プッシュ
   - PCK は APK ビルド時のものをそのまま流用可（同一フォーマット）
   - `.html`/`.js`/`.wasm` は変更不要

---

## 現在のジャンプスケア設定値

| 項目 | 値 |
|------|---|
| ホールド時間 | 0.7 秒 |
| フェードアウト時間 | 0.5 秒 |
| SE 音量フェード | 3 秒 |
| グリッチ intensity | 0.5 |
| グリッチ speed | 25.0 |
| CanvasLayer layer | 10 |
