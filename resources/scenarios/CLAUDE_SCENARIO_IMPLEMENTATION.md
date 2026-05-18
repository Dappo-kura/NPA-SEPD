# NPA-SEPD シナリオ実装メモ for Claude Code

## 追加済み素材

イベントCGは以下の命名で配置する。

```text
res://resources/events/event_day_01.png
...
res://resources/events/event_day_21.png
```

すべて 1080x1920 の縦長PNG。

## シナリオデータ

`res://resources/scenarios/day_scenarios.json` を追加する。

形式は以下。

```json
{
  "schema_version": 1,
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
      "evidence_items": "破れた紙片、曲がったフック、空の赤箱",
      "overview": "...",
      "preservation_note": "...",
      "case_file_text": "...",
      "intro_text": "...",
      "clear_text": "...",
      "nightmare_text": "...",
      "event_cg_id": 1,
      "event_cg_path": "res://resources/events/event_day_01.png",
      "gallery_title": "Day 1 赤箱返送事件",
      "event_illustration_note": "..."
    }
  ]
}
```

## 推奨実装

1. `ScenarioManager` のようなAutoLoadを追加し、JSONをロードする。
2. `ScenarioManager.get_day(day: int) -> Dictionary` でDay単位のデータを返す。
3. ストーリーモードの各Day開始時、パズル前に以下を表示する。
   - `case_id`
   - `case_title`
   - `case_file_text`
   - `intro_text`
4. 封印後は既存の `NightmareEvent.show_event()` に渡している `StageData.nightmare_text` の代わりに、JSONの `clear_text` または `nightmare_text` を使う。
5. Dayクリア時に `event_cg_id` をギャラリー解放IDとして保存する。
6. ギャラリーは `day_scenarios.json` の `days` から `event_cg_path` と `gallery_title` を動的生成すると、21件の手入力を避けられる。

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
  -> Day開始シナリオ画面
       事件資料
       開始前テキスト
  -> パズル画面
  -> 封印
  -> 封印後テキスト
  -> Dayクリア、CG解放
  -> 次Day開始シナリオ画面
```

## 注意

- Day数と事件数は一致。1ステージにつき1事件。
- 9章は物語上の章テーマであり、1章1事件ではない。
- ゲージ連動演出は今回の実装対象外。
- 画像にはUI文字を焼き込んでいないため、ゲーム側のダイアログUIを重ねて使う。

