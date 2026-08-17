# Metamorph: Creative Menu — 日本語

[English](README.en.md) · [Русский](README.ru.md) · [Português (Brasil)](README.pt-BR.md) · [Español](README.es-ES.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Italiano](README.it.md) · [Polski](README.pl.md) · [简体中文](README.zh-CN.md) · [日本語](README.ja.md) · [한국어](README.ko.md)

## 概要

**Metamorph: Creative Menu (MCM)** は **Noita** 用のクリエイティブ/開発者メニューです。シングルプレイでは単独で動作し、任意で **Entangled Worlds / Noita Proxy** との実験的互換機能も提供します。

杖の編集、アイテム生成/取得、パークと効果の付与・削除、クリーチャーへの変身、カーソル下の既存クリーチャーの乗っ取り、天候・ワールドルール変更、プレイヤー風の仲間生成などができます。

## 必要条件とインストール

- Noita。
- `Noita/mods/` 内の `metamorph_creative_menu` フォルダ。
- Noita の Mod 設定で **Unsafe mods / unrestricted API** を有効にしてください。同梱のネイティブ **NoitaPatcher** が必要とします。
- Entangled Worlds は**任意**です。

1. [Releases](https://github.com/zerodancing/Metamorph-Creative-Menu/releases) からビルドを取得するか、リポジトリをダウンロード/cloneします。
2. `metamorph_creative_menu` を `Noita/mods/` にコピーします。
3. `Noita/mods/metamorph_creative_menu/mod.xml` が存在することを確認します。
4. Unsafe mods と Metamorph: Creative Menu を有効化します。

内部フォルダ名は変更しないでください。

## 操作

- **TAB** — メニューを開く/閉じる。
- **変身中の TAB** — 人間形態へ戻る。
- 既定 **G** — カーソル下の対応クリーチャーを乗っ取る/変身する。設定で変更可能。
- LMB/RMB の用途は各タブの UI に表示されます。

## 機能

### 呪文/杖編集
杖を持ち、スロットを選び、検索・カテゴリ対応の一覧から呪文を選択します。置換、削除、ワールドへのドロップが可能です。置換では新しい呪文を確認してから古い呪文を削除します。

### アイテム
ボトル/容器、液体、石、卵、杖、本、ボーナス、オーブ、クエストアイテムなど。
- **LMB:** 近くに生成。
- **RMB:** 適切なインベントリスロットへ直接追加を試行。
- 空きがない/取得失敗時はアイテムをワールドに残します。
- 液体入りフラスコ等も対応します。

### パーク
- **ADD:** LMB で通常 pickup を生成、RMB で直接取得。
- **REMOVE:** LMB で1スタック削除、RMB ですべて削除を試行。
MCM はパーク所有の多くの変更を追跡し、他システムの状態を意図的に上書きせず、エンティティ/コンポーネント/値を戻そうとします。安全な逆操作がない場合は危険な削除を拒否することがあります。

### 検索
大きなカタログでは翻訳名、ID、説明などで検索できます。

### クリーチャー、オブジェクト、形態
- **LMB:** 生成。
- **RMB:** 変身。
- **TAB:** 人間へ戻る。

互換性は正確な XML パス単位で管理されます。既知の危険な placement wrapper の一部は、変身時のみ安全な canonical target にルーティングされます。プレイヤー形態は有用なネイティブ攻撃、移動、見た目、物理をできるだけ維持し、操作と競合する AI を無効化します。複雑なエンティティは近似 adapter を使う場合があります。

### 人間への復帰と形態の死亡
通常の TAB 復帰はまず Noita のネイティブ polymorph lifecycle を使います。さらに MCM は NoitaPatcher で人間のシリアライズ済みバックアップを保持します。

致命傷では **death handoff** を試み、クリーチャー身体は死亡させつつ、プレイヤー権限を復元した人間へ戻し、形態の死だけで run 全体が終わらないようにします。

### Possession
対応クリーチャーにカーソルを合わせ **G**。MCM は対象に対応する形態を使用し、元の対象を retire/削除して単純な複製を避けます。

### PLAYER 仲間
`PLAYER` 項目からプレイヤー風の味方を生成できます。必要な NoitaPatcher 機能があれば、コピーした杖をより実際のプレイヤーに近い形で使用できます。

### 効果
ステータス/時間制効果を付与し、対応していれば時間を選択し、内部/perk 状態を可能な限り保護しながら削除できます。

### 天候
時間プリセット: 朝、昼、夕方、夜。天候: 晴れ、曇り、霧、嵐。Advanced では時間、雲、霧、風、風速、雨、雷関連の対応値を変更できます。**RELEASE** で MCM の override 維持を停止します。

### ワールドルール
ルールは**可逆 override**です。`NATIVE`/RESET は MCM が記録した baseline を戻し、重要なルールは永続 recovery 情報を持ちます。

現在のルール:

- クリーチャー関係
- 金塊が消えない
- 呪文使用回数無制限
- マップを開く
- トリックキル血金
- 回復ドロップ率
- 友好的なネズミ
- 流血量
- トリックキル金額
- ダメージフラッシュ
- 汚れの脱落
- ワールド重力
- 物理減衰
- 血液量
- キック力
- ジョイント強度
- 昼夜サイクル速度

物理ルールはロード済み/近くのエンティティや物理ボディに作用し、無限ワールド全体の未ロード対象を一瞬で書き換えるものではありません。

## シングルプレイと Entangled Worlds

**シングルプレイに EW は不要です。** MCM は NoitaPatcher とローカル Base64 codec を同梱しています。

`quant.ew` が有効なら、ワールドアイテム、パーク、天候、ルール、形態/possess、仲間、互換 patch の実験的連携が有効になります。EW が互換 NoitaPatcher API をすでに公開している場合、MCM はそれを再利用できます。

マルチプレイ対応は**実験的/部分的**です。host と client は同じ MCM 操作権を持つ方針ですが、すべての Noita/EW edge case を保証するものではありません。全 peer で同じ MCM バージョンを使ってください。

## トラブルと報告

- メニューが出ない: パスと Mod 有効化を確認。
- 拡張機能がない: Unsafe mods と `NoitaPatcher/noitapatcher.dll` を確認。
- 形態の問題: 正確な名前/XML と TAB/死亡復帰のどちらが失敗したかを記載。
- EW: MCM と EW のバージョンを記載。

[GitHub Issues](https://github.com/zerodancing/Metamorph-Creative-Menu/issues) へ再現手順とログを投稿してください。

## 依存関係とクレジット

MCM は **NoitaPatcher** (dextercd) と **lbase64** (Ilya Kolbin) を同梱し、任意で **Noita Entangled Worlds** (IntQuant と contributors) と連携します。詳細は [THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md)。

## リンク

- MCM: https://github.com/zerodancing/Metamorph-Creative-Menu
- Releases: https://github.com/zerodancing/Metamorph-Creative-Menu/releases
- Issues: https://github.com/zerodancing/Metamorph-Creative-Menu/issues
- Noita: https://noitagame.com/
- NoitaPatcher: https://github.com/dextercd/NoitaPatcher
- NoitaPatcher docs: https://dexter.döpping.eu/NoitaPatcher/
- Entangled Worlds: https://github.com/IntQuant/noita_entangled_worlds
- lbase64: https://github.com/iskolbin/lbase64

## 開発

プレイ可能な Mod は `metamorph_creative_menu/`、テスト/contract は `metamorph_creative_menu/tests/` にあります。MCM オリジナルコードのリポジトリ全体ライセンスはまだ選択されていません。
