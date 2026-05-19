# NPA-SEPD シナリオ実装メモ for Claude Code

## 追加済み素材

イベントCGは以下の命名で配置する。

```text
res://resources/events/event_day_01.png
...
res://resources/events/event_day_21.png
```

すべて 1080x1920 の縦長PNG。

## データ分離方針

シナリオと事件資料は別管理にする。

- `res://resources/scenarios/day_scenarios.json`
  - 会話/ナレーション用
  - `intro_lines`: 封印前シナリオ
  - `clear_lines`: 封印後シナリオ
- `res://resources/scenarios/case_files.json`
  - 事件資料画面用
  - パズル前に表示する業務資料

表示順は必ず以下にする。

```text
封印前シナリオ day_scenarios.intro_lines
  -> 事件資料 case_files
  -> パズル
  -> 封印後シナリオ day_scenarios.clear_lines
```

## シナリオデータ

`res://resources/scenarios/day_scenarios.json` を使用する。

形式は以下。

```json
{
  "schema_version": 2,
  "project": "NPA-SEPD",
  "scenario_style": "one_day_one_case",
  "asset_resolution": "1080x1920",
  "chapters": [
    {
      "chapter_number": 1,
      "chapter_title": "配属初日",
      "days": [1, 2]
    }
  ],
  "days": [
    {
      "day": 1,
      "chapter_number": 1,
      "chapter_title": "配属初日",
      "case_id": "SEPD-0001",
      "case_title": "赤箱返送事件",
      "intro_text": "...",
      "clear_text": "...",
      "mentor_speaker_name": "先輩管理官",
      "intro_lines": [
        {
          "type": "narration",
          "speaker": "",
          "text": "先輩管理官は、赤い箱を机の中央に置いた。"
        },
        {
          "type": "dialogue",
          "speaker": "先輩管理官",
          "text": "今日から君の仕事は、証拠品を保全すること。"
        }
      ],
      "clear_lines": [
        {
          "type": "narration",
          "speaker": "",
          "text": "封印札が貼り付くと、箱の内側から小さな音がした。"
        }
      ],
      "nightmare_text": "...",
      "event_cg_id": 1,
      "event_cg_path": "res://resources/events/event_day_01.png",
      "gallery_title": "Day 1 赤箱返送事件",
      "event_illustration_note": "..."
    }
  ]
}
```

## 事件資料データ

`res://resources/scenarios/case_files.json` を使用する。

形式は以下。

```json
{
  "schema_version": 1,
  "project": "NPA-SEPD",
  "purpose": "case_file_screen_before_puzzle",
  "display_order": "after_intro_scenario_before_puzzle",
  "case_files": [
    {
      "day": 1,
      "chapter_number": 1,
      "chapter_title": "配属初日",
      "case_id": "SEPD-0001",
      "case_title": "赤箱返送事件",
      "title_text": "【事件資料】 赤箱返送事件",
      "management_number": "SEPD-0001",
      "evidence_items": "破れた紙片、曲がったフック、空の赤箱",
      "overview": "...",
      "preservation_note": "...",
      "display_sections": [
        { "label": "管理番号", "text": "SEPD-0001" },
        { "label": "搬入物", "text": "破れた紙片、曲がったフック、空の赤箱" },
        { "label": "概要", "text": "..." },
        { "label": "保全注意", "text": "..." }
      ]
    }
  ]
}
```

## 推奨実装

1. `ScenarioManager` のようなAutoLoadを追加し、`day_scenarios.json` と `case_files.json` の両方をロードする。
2. `ScenarioManager.get_day_scenario(day: int) -> Dictionary` でシナリオデータを返す。
3. `ScenarioManager.get_case_file(day: int) -> Dictionary` で事件資料データを返す。
4. ストーリーモードの各Day開始時、まず `intro_lines` をページ送り表示する。
5. `intro_lines` / `clear_lines` はページ送り用の配列。`type == "dialogue"` の場合は `speaker` を話者名欄へ表示し、`type == "narration"` の場合は話者名欄を非表示にする。
6. `intro_lines` が終わったら、同じDayの `case_files.json` の事件資料を表示する。
7. 事件資料を閉じたらパズルを開始する。
8. 封印後は既存の `NightmareEvent.show_event()` に渡している `StageData.nightmare_text` の代わりに、JSONの `clear_lines` をページ送り表示する。旧実装互換用に `clear_text` / `nightmare_text` も残している。
9. Dayクリア時に `event_cg_id` をギャラリー解放IDとして保存する。
10. ギャラリーは `day_scenarios.json` の `days` から `event_cg_path` と `gallery_title` を動的生成すると、21件の手入力を避けられる。

## 既存コードへの接続ポイント

- `autoload/game_manager.gd`
  - 現在Dayは `GameManager.current_day`
  - Dayクリアは `advance_day()`
- `scenes/main_game/main_game.gd`
  - `_init_from_game_manager()` または `_on_day_changed()` の直後に、Day開始シナリオ画面を挟む
  - `_on_seal_pressed()` の封印後テキスト取得箇所をJSON参照に変更
- `autoload/save_manager.gd`
  - `on_story_day_cleared(day)` は既にDay番号をギャラリーIDとして解放しているため、そのまま利用可能
- `scenes/gallery/gallery.gd`
  - 現状は `GALLERY_ENTRIES` が1件固定
  - JSONから21件を生成するか、最低限 `event_day_01.png` から `event_day_21.png` まで登録する

## 表示順

```text
タイトル
  -> ストーリーモード開始
  -> 封印前シナリオ画面
       day_scenarios.intro_lines
  -> 事件資料画面
       case_files.display_sections
  -> パズル画面
  -> 封印
  -> 封印後シナリオ画面
       day_scenarios.clear_lines
  -> Dayクリア、CG解放
  -> 次Day封印前シナリオ画面
```

## 事件資料画面UI

添付参考のような黒背景の業務資料画面にする。

- 背景: 黒
- タイトル: 赤、`【事件資料】 {case_title}`
- 本文: 白
- 表示項目:
  - `管理番号: {management_number}`
  - `搬入物: {evidence_items}`
  - `概要: {overview}`
  - `保全注意: {preservation_note}`
- 画面右下に進行用の小さな三角アイコン
- タップ/クリックでパズルへ進む
- シナリオ用の話者名UIは使わない

## 注意

- Day数と事件数は一致。1ステージにつき1事件。
- 9章は物語上の章テーマであり、1章1事件ではない。
- ゲージ連動演出は今回の実装対象外。
- 画像にはUI文字を焼き込んでいないため、ゲーム側のダイアログUIを重ねて使う。
- 「先輩保全官」表記は廃止し、「先輩管理官」に統一済み。
