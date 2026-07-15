# NPA-SEPD 怪異スチル実装メモ

## 追加素材

未収納ピースありで封印した時だけ表示する怪異スチルを21枚追加する。

```text
res://resources/events/kaiki_day_01.png
...
res://resources/events/kaiki_day_21.png
```

すべて 1080x1920 の縦長PNG。

## データ

`res://resources/scenarios/kaiki_stills.json` を追加する。

形式:

```json
{
  "schema_version": 1,
  "project": "NPA-SEPD",
  "purpose": "kaiki_still_for_incomplete_seal",
  "trigger_condition": "Show only when seal is executed with unplaced pieces / SAN damage > 0.",
  "stills": [
    {
      "day": 1,
      "case_id": "SEPD-0001",
      "case_title": "赤箱返送事件",
      "trigger": "unplaced_pieces_on_seal",
      "kaiki_still_id": 1,
      "kaiki_still_path": "res://resources/events/kaiki_day_01.png",
      "gallery_title": "怪異 Day 1 赤箱返送事件"
    }
  ]
}
```

## 表示条件

怪異スチルは、封印時に未収納ピースがある場合のみ表示する。

既存の封印処理では未収納ピースから `damage` を計算しているため、基本条件は以下でよい。

```gdscript
if damage > 0:
    # 怪異スチルを表示
else:
    # 怪異スチルなしで通常封印
```

## 推奨表示順

```text
封印ボタン
  -> SANダメージ計算
  -> damage > 0 の場合のみ怪異スチル表示
  -> 封印後シナリオ clear_lines
  -> 次Dayへ
```

## UI方針

- 怪異スチルは画面全体に表示する。
- 1タップ/クリックで閉じる。
- 表示時間を固定するなら1〜2秒程度にする。
- シナリオ用の話者名UIや事件資料UIは重ねない。
- 必要なら軽い暗転、赤フラッシュ、封印SEの直後に差し込む。

## ギャラリー

任意で、怪異スチルを見た時だけギャラリー解放する。

```gdscript
SaveManager.unlock_kaiki_still(day)
```

のような別配列にすると、通常イベントCGと怪異スチルを分けて管理しやすい。

