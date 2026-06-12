# NPA-SEPD 開発ログ

---

## 2026-06-12

全体評価 → 改善プラン策定 → Phase 1（バグ修正）＋ Phase 2（継続プレイ対応）を実装。
**Phase 3 / Phase 4 は次回アップデートで対応する（下記「次回: Phase 3 / Phase 4 作業計画」参照）。**

### Phase 1: バグ修正（commit `3e93984`）

| # | 修正 | 対象ファイル |
|---|------|------------|
| 1-1 | 無限モードにストーリーの `clear_lines`・CG・怪異スチルが混入 → `MODE_STORY` 判定追加 | `nightmare_event.gd` / `main_game.gd` |
| 1-2 | ドラッグ中タイムアップでピース消滅・SANダメージ計算漏れ → 強制封印前に `_restore_to_tray()` | `main_game.gd` |
| 1-3 | SAN 0 で演出スキップして即ゲームオーバー → `_pending_game_over` フラグで演出完走後に遷移 | `main_game.gd` |
| 1-4 | Web版で無効な終了ボタン → `OS.has_feature("web")` で非表示 | `title_screen.gd` |

### Phase 2: 継続プレイ対応（commit `d4f9eb4`）

#### 続きから
- `SaveManager.story_run_day` / `story_run_san` を追加。**Day開始時に保存**、ゲームオーバー・全クリアで消去
- `GameManager.continue_story()` 追加（保存値から再開）
- タイトルに「続きから（Day N）」ボタン（ラン有時のみ表示）。同時にストーリーボタンを「最初から」表記に変更し上書きを明示
- **仕様メモ**: 死亡＝ラン消去だが、広告視聴で同じDayから再挑戦可能（下記「広告リトライ」参照）

#### 設定画面（新規 `scenes/settings/`）
- BGM/SE音量スライダー（0〜100%・5%刻み）。変更は即時反映、退出時に `save.json` へ保存
- AutoLoad順が AudioManager → SaveManager のため、**音量の起動時反映は `SaveManager._ready()` 側から実行**
- ジャンプスケアSEも SE音量設定に追従するよう修正（`jump_scare.gd`）

#### ポーズ
- メインゲーム下部に「中断」ボタン追加。`_paused` フラグで `_process`（タイマー）と `_input` を停止
- 暗転オーバーレイ（z_index=25）で「再開」「タイトルへ戻る」
- 中断時は選択/ドラッグ中ピースを `_restore_to_tray()` で戻してから停止

### 広告リトライ（死亡時の継続・収益化）※ユーザー判断により当日追加実装

- **仕様決定**: 死亡時は「広告を見て同じDayからSAN全快で再挑戦」（収益化を兼ねる）
- 死亡フロー: SAN 0 → ラン消去 → ゲームオーバー画面に「広告を見て Day N から再挑戦」ボタン
  （ストーリーモードのみ表示）→ 視聴完了 → `save_story_run(day, 100)` → `continue_story()` → day_intro
- 広告を見ずに「タイトルに戻る」→ ランは消えたまま（Day 1から）。広告ゲートが意味を持つ構造
- **`autoload/ad_manager.gd` 新規**（AutoLoad登録済み）:
  - 現状は**スタブ実装**（5秒カウントダウンのデモ広告画面 → 「閉じて報酬を受け取る」）
  - 差し替えポイントは `is_rewarded_ad_available()` / `show_rewarded(callback)` の2関数のみ
- **AdMob本接続に必要なもの（次回以降）**:
  1. AdMobアカウント作成 → アプリID・リワード広告ユニットID取得
  2. Poing Studios製 Godot AdMob Plugin の AAR を `godot_android_build/libs` へ追加
  3. `AndroidManifest.xml` に `com.google.android.gms.ads.APPLICATION_ID` meta-data 追加
  4. `ad_manager.gd` の2関数を実SDK呼び出しに差し替え
  5. 注意: Web版はAdMob非対応。Web収益化は別途（AdSense for Games等）の検討が必要

### ビルド環境の復旧（重要）

- **Temp掃除で `build_pck.py` / `build_apk.py` と Gradleビルドdirのルートファイルが消失していた**
- `ANDROID_BUILD_GUIDE.md` から復元。再構築用 `setup_android_build.py`（Step1+2の必須修正込み）も作成
- Godot本体の場所: `C:/Users/datepo/OneDrive/ドキュメント/Godot_v4.5.1-stable_win64.exe/`（フォルダ名が.exe）

### APK肥大化バグの発見と対策

- PCK差し替え後のインクリメンタルGradleビルドで APK が 124.8MB → **220.8MB に肥大化**
- 原因: zip内に旧PCK分の「穴」（デッドバイト）が残る。論理エントリは正常なので `jar tf` では見えない
- 対策: `gradlew clean` 後に再ビルドで解消。**`build_apk.py` に `clean` を恒久組み込み済み**

### 検証方法（今回確立）

- 全シーンロード検証: `tools/check_scenes.gd`（SceneTreeスクリプト・リポジトリ内に保存）
  ```
  Godot_console.exe --headless --path <project> -s tools/check_scenes.gd
  ```
  各シーンを instantiate + add_child して `@onready` 欠落やパースエラーを検出。
  新シーン追加時は scenes 配列に追記すること

### リリース

- APK: `Documents/NPA-SEPD-debug.apk`（124.8 MB）
- Web: gh-pages 更新済み → https://dappo-kura.github.io/NPA-SEPD/

### GitHub コミット

| ハッシュ | 内容 |
|---------|------|
| `3e93984` | Fix Phase 1 bugs: mode leaks, drag-timeout loss, SAN 0 flow, web quit |
| `d4f9eb4` | Add Phase 2 features: continue, settings screen, pause menu |

---

## 次回: Phase 3 / Phase 4 作業計画

### Phase 3: ゲームデザイン強化（推定2〜3日）

#### 3-1. danger を意味のある値にする ★着手点
- 現状: 未配置ダメージ = セル数のみ（`GameManager.calculate_total_san_damage()`）。`danger` 1〜5 は飾り
- 変更案: ダメージ = `セル数 × danger`。「危険物を優先して収納する」判断が生まれる
- 影響範囲: `game_manager.gd` のダメージ計算、`main_game.gd:_on_seal_pressed` の records 構築
  （`{"item": item, "cell_count": ...}` に danger を追加）、バランス調整（SAN 100 に対する係数検討）
- トレイの danger 表示が小さすぎる問題も同時に直す（`item_visual.gd:88-92` フォント12px → 視認可能サイズに）

#### 3-2. 呪いセルの公平性
- 現状: `grid_box.add_cursed_cell()` が無警告で空セルをブロック。解けない盤面が生まれ得る
- 変更案:
  - 出現1秒前に対象セルを点滅警告（タイマー方式は `main_game.gd:_process` の `_cursed_cell_timer` 参照）
  - 残りピースが配置不能になる場合は出現を抑制（全ピースの全回転で配置可能性チェック）
  - リセット時に呪いセルもクリアするか要検討（現状は `clear_all_items()` で残る）

#### 3-3. エンディング/ゲームオーバー差し替え
- 現状エンディングは「見所があるな！よし！ご褒美をあげよう」のプレースホルダ（トーン不一致）
- `day_scenarios.json` 方式の VN 演出に差し替え（`ending_lines` を JSON に追加し day_intro と同形式で表示）
- ゲームオーバー画面も演出強化（現状ボタン1個のみ）

#### 3-4. SEプレイヤーのプール化
- 現状 `audio_manager.gd` は SE プレイヤー1本 → 連続配置で音が切れる
- 3〜4本の `AudioStreamPlayer` をローテーション

#### 3-5. 死亡時の継続仕様 → ✅解決済み（2026-06-12当日実装）
- 広告視聴で同じDayからSAN全快再挑戦（収益化兼用・スタブ広告）。本節の作業は
  AdMob本接続のみ残（上記「広告リトライ」のチェックリスト参照）

#### クリーンアップ（Phase 3 と同時に）
- 未使用: `can_merge` / `merge_recipe.gd`、`StageData.san_threshold`、`_rotate_active()`、
  `ItemTray.rotate_item()`、`grid_box._gui_input()`（空）、`GameManager.start_game()`
- `day_intro.gd` / `nightmare_event.gd` の VN ロジック重複（約150行）→ 共通基底クラス化

### Phase 4: AnomalyDirector（fear_level連動演出）

- `fear_level = f(SAN, 盤面のdanger合計)` を導入（Phase 3-1 の danger 有効化が前提）
- fear低: 照明ちらつき・箱の赤い脈動・環境音ノイズ
- fear中: 机上の手形・ピースが一瞬別形状・トレイ表示の乱れ
- fear高: 視野狭窄・箱内セルの呼吸・机上の手でセル一時封鎖
- ジャンプスケアを大ミス/限界時のみに集約（現状: 配置失敗とタイムアップで毎回発火）

### 次回の作業手順メモ

1. 着手前に `git log --oneline -5` で前回までの状態確認
2. ビルドスクリプトの存在確認: `C:/Users/datepo/AppData/Local/Temp/build_pck.py` / `build_apk.py`
   （Temp掃除で消えていたら本ログの「ビルド環境の復旧」参照）
3. 実装 → `check_scenes.gd` で全シーン検証 → APK＋Web ビルド → main コミット

---

## 2026-05-20

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
