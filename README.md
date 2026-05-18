# 整理パズル型サバイバル — NPA-SEPD

> **"五日間の封印作業を生き延びろ"**
> 呪われた証拠品をグリッドに詰め込み、精神を保ったまま封印を完遂するパズルサバイバルゲーム。

![Godot 4.5](https://img.shields.io/badge/Godot-4.5-478CBF?logo=godotengine)
![GDScript](https://img.shields.io/badge/Language-GDScript-blue)
![Platform](https://img.shields.io/badge/Platform-Android%20%2F%20PC-green)
![Status](https://img.shields.io/badge/Status-MVP%20実装中-yellow)

---

## ゲーム概要

プレイヤーは「呪物整理専門部署（NPA-SEPD）」の新人隊員。毎日持ち込まれる呪具を所定のグリッドに収め、**封印（Seal）**を完了することが目標。

- アイテムはテトリスのような多角形ピース
- 時間切れや配置失敗でジャンプスケアが発生し **SAN値（精神力）** が削られる
- SAN値が0になるとゲームオーバー
- 全ステージクリアでエンディング

---

## ゲームプレイ

### 基本操作

| 操作 | 効果 |
|------|------|
| アイテムをドラッグ | グリッドに配置 |
| アイテムをタップ | クリック配置モード（タップで場所を指定） |
| **R キー** | アイテムを90°回転（回転可能なアイテムのみ） |
| 右クリック / ESC | アイテムをトレイに戻す |
| **封印ボタン** | 作業を完了して次のステージへ |
| **リセットボタン** | グリッドのアイテムをすべてトレイに戻す |

### SAN（精神値）システム

- 初期値: **100**
- 封印時に未配置のアイテムがあると `セル数 × 1` のSANダメージ
- グリッドをピッタリ埋めてから封印すると **SAN +10 回復ボーナス**
- SAN 0 → ゲームオーバー

### 制限時間

| ステージ | 制限時間 |
|---------|---------|
| Day 1〜2（チュートリアル） | なし |
| Day 3〜4 | 60 秒 |
| Day 5〜10 | 90 秒 |
| Day 11〜15 | 80 秒 |
| Day 16〜21 | 120 秒 |
| 無限モード | 90 秒 から Wave ごとに 3 秒短縮（最短 30 秒） |

時間が半分を切ると、15 秒ごとに**呪われたセル（使用不可マス）**がグリッドに出現する。

---

## ゲームモード

### ストーリーモード
- 21 ステージ・9 シナリオを順番にクリア
- セーブ機能あり（進行状況は自動保存）

### 無限パズルモード
- ランダムにステージを選択して Wave を重ねる
- 自己記録（最高 Wave 数）を保存

### ギャラリー
- ストーリーモードを進めることでイベントCGが解放される

---

## シナリオ一覧

| 話数 | タイトル | ステージ | グリッド |
|------|---------|---------|---------|
| 第1話 | 配属初日 | Day 1〜2 | 3×3 |
| 第2話 | 人形の家 | Day 3〜4 | 4×4 |
| 第3話 | 文字の呪縛 | Day 5〜7 | 5×5 |
| 第4話 | 廻る因縁 | Day 8〜10 | 5×5〜6×6 |
| 第5話 | 鈎の記憶 | Day 11〜13 | 6×6 |
| 第6話 | 鏡の向こう | Day 14〜15 | 7×7 |
| 第7話 | 念珠と罪業 | Day 16〜17 | 8×8 |
| 第8話 | 写真に宿る影 | Day 18〜19 | 9×9 |
| 第9話 | 最後の封印 | Day 20〜21 | 9×9（全アイテム混合） |

---

## 登場アイテム（呪具）

| アイテム名 | 備考 |
|-----------|------|
| 錆びたナイフ (rusty_knife) | 直線形 |
| 割れた人形 (cracked_doll) | L字形 |
| 破れた手紙 (torn_paper) | 1×1 |
| 謎のコイン (strange_coin) | 1×1 |
| 曲がった鈎 (bent_hook) | 鈎形 |
| 呪いの指輪 (cursed_ring) | 小型 |
| 藁人形 (straw_doll) | T字形 |
| 呪いの鏡 (cursed_mirror) | 大型 |
| 数珠 (prayer_beads) | 長形 |
| 呪いの写真 (cursed_photo) | 中型 |
| 呪いの髪 (cursed_hair) | S字形 |

---

## 技術仕様

| 項目 | 内容 |
|------|------|
| エンジン | Godot 4.5 |
| 言語 | GDScript |
| 対象プラットフォーム | Android（縦画面）/ PC |
| 画面解像度 | 1080 × 2400 px（Pixel 7 縦画面基準） |
| 画面向き | 縦固定（Portrait） |

### ディレクトリ構成

```
NPA-SEPD/
├── autoload/
│   ├── game_manager.gd      # ゲーム進行・SAN管理・シグナル
│   ├── audio_manager.gd     # BGM・SE再生
│   └── save_manager.gd      # セーブ・ギャラリー解放管理
├── resources/
│   ├── items/               # アイテム定義 (.tres) と画像 (.png)
│   ├── stages/              # ステージ定義 day_01〜day_21.tres
│   ├── events/              # イベントCG (event_001.png ほか)
│   ├── sound/               # BGM・SE (.mp3)
│   └── title.png            # タイトル背景画像
├── scenes/
│   ├── main_game/           # メインゲーム（グリッド・HUD・トレイ）
│   │   ├── grid_box/        # グリッド描画・配置ロジック
│   │   ├── hud/             # SANバー・タイマー表示
│   │   ├── item_tray/       # アイテムトレイ（横スクロール）
│   │   └── item_visual/     # アイテム描画コンポーネント
│   ├── title_screen/        # タイトル画面
│   ├── ending/              # エンディング（タイプライター演出）
│   ├── game_over/           # ゲームオーバー画面
│   ├── gallery/             # ギャラリー画面
│   ├── nightmare_event/     # 封印後のナイトメアテキスト表示
│   └── jump_scare/          # ジャンプスケア・ノイズエフェクト
└── project.godot
```

### AutoLoad Singleton

| クラス名 | 役割 |
|---------|------|
| `GameManager` | ゲームモード・現在Day・SAN値・ステージ遷移 |
| `AudioManager` | BGMループ再生・SE（puzzle / enter / seal） |
| `SaveManager` | ストーリー進行・無限ベスト・ギャラリー解放の永続化 |

### 主要シグナル（GameManager）

```gdscript
signal san_changed(new_value: int)   # SAN値変化
signal day_changed(new_day: int)     # Day/Wave切り替わり
signal game_over()                   # SAN 0
signal game_cleared()                # 全ステージクリア
```

---

## セットアップ・実行方法

1. [Godot 4.5](https://godotengine.org/download/) をインストール
2. このリポジトリをクローン
   ```bash
   git clone https://github.com/Dappo-kura/NPA-SEPD.git
   ```
3. Godot エディタで `project.godot` を開く
4. F5 または「実行」でプレイ

---

## 実装状況

### 完了
- [x] データクラス（ItemData / StageData / MergeRecipe）
- [x] 21 ステージ・9 シナリオ
- [x] ドラッグ＆ドロップ / クリック配置の状態機械
- [x] アイテム回転（R キー）
- [x] SAN システム・制限時間・呪われたセル
- [x] ジャンプスケア・ノイズシェーダー
- [x] BGM・SE（AudioManager）
- [x] ストーリーモード / 無限モード分岐
- [x] セーブ機能（SaveManager）
- [x] ギャラリー画面
- [x] エンディング（タイプライター演出）
- [x] タイトル画面（フルスクリーン背景・4ボタン）

### 未実装（今後の予定）
- [ ] Phase B: 無限モード難易度上昇（呪われたセルの強化）
- [ ] ジャンプスケア専用アセット（jumpscare.png / jumpscare.mp3 / noise.mp3）
- [ ] ギャラリー event_002〜021 画像
- [ ] 日本語フォント組み込み（文字化け対策）
- [ ] Android ビルド・実機テスト

---

## ライセンス

現時点では All Rights Reserved。利用・転載についてはリポジトリオーナーに確認してください。
