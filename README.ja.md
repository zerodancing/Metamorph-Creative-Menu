<h1 align="center">Metamorph: Creative Menu</h1>

<p align="center">
  Noita 向けのクリエイティブツール集：呪文、杖、アイテム、マテリアル、パーク、クリーチャー、効果、テレポート、天候、ワールドルール。
</p>

<a id="languages"></a>

[English](README.md) · [Русский](README.ru.md) · [Português (Brasil)](README.pt-BR.md) · [Español](README.es.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Italiano](README.it.md) · [Polski](README.pl.md) · [简体中文](README.zh-CN.md) · [**日本語**](README.ja.md) · [한국어](README.ko.md)

## ダウンロード

現在のバージョン：**2.0.0**

| パッケージ | ダウンロード |
|---|---|
| **最新のインストール用ビルド** | **[⬇️ Metamorph-Creative-Menu.zip をダウンロード](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip)** |
| ビルドページ | [最新のインストール用ビルド](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/tag/latest-build) |

> ZIP には NoitaPatcher を含む完全な `metamorph_creative_menu` フォルダが入っています。そのフォルダを直接 `Noita/mods/` に展開してください。

正しい最終パス：

```text
Noita/mods/metamorph_creative_menu/mod.xml
```

`metamorph_creative_menu/metamorph_creative_menu/mod.xml` になっている場合は、1 階層深く展開されています。

---

## 日本語

### インストール

1. [最新のインストール用 ZIP をダウンロード](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/download/latest-build/Metamorph-Creative-Menu.zip)します。
2. MOD のインストールまたは更新前に Noita を完全に終了します。
3. Steam で **ライブラリ → Noita を右クリック → 管理 → ローカルファイルを閲覧** を開きます。
4. ゲームの `mods` フォルダを開き、**`metamorph_creative_menu`** フォルダ全体をコピーします。
5. `Noita/mods/metamorph_creative_menu/mod.xml` が存在することを確認してください。MOD フォルダ名は変更しないでください。
6. Noita を起動し、**Metamorph: Creative Menu** を有効にします。必要な場合は **Unsafe mods / unrestricted API** を許可し、MOD を有効にした後で Noita を再起動します。
7. ゲームを開始して **TAB** を押します。メニューが開けばインストール完了です。

**更新：**Noita を終了し、古い `metamorph_creative_menu` フォルダを削除してから、新しいフォルダを `mods` にコピーしてください。フォルダ全体を置き換えることで、旧バージョンの不要なファイルが残るのを防げます。

### 操作

- **F4 または TAB**：Creative Menu を開閉します。
- **変身中に TAB**：人間形態に戻ります。
- **G**（デフォルト）：カーソル下の対応クリーチャーに憑依します。
- **マウス中央ボタン**：選択したマテリアルで描画します。
- キー割り当ては操作セクションまたは MOD 設定で変更できます。左クリックと右クリックで実行できる操作は UI に表示されます。

### MCM でできること

- 呪文を取得・配置し、杖、常時詠唱スロット、インベントリ、ワールドの間で移動できます。
- 杖の性能、外見、ロックを編集し、杖プリセットの保存やコピーの作成ができます。
- プレイヤーの近く、または指定したワールド位置にアイテムを生成し、対応アイテムを直接インベントリへ入れられます。
- 選択した液体入りのフラスコを作成できます。
- マテリアルを選択してワールドに描画できます。
- パークを生成、取得、削除できます。
- プレイヤーの近く、または指定したワールド位置にクリーチャーを生成できます。
- クリーチャーへ変身し、ワールド内の既存クリーチャーに憑依し、人間形態へ戻れます。
- 独立した PLAYER エンティティを生成できます。
- ゲーム内の効果を付与・削除できます。
- 天候、時間帯、重力、その他のワールドルールを変更できます。
- ゲーム内の地点へテレポートできます。
- Entangled Worlds 使用時は、他プレイヤーの位置へ移動したり、他プレイヤーを自分の位置へ呼び寄せたりできます。
- キー割り当てを変更し、呪文、アイテム、マテリアル、パーク、クリーチャーの各カタログを検索できます。
- メニューウィンドウを移動・リサイズでき、その位置とサイズは次回起動時にも保持されます。

<details>
<summary><strong>変身、互換性、復元</strong></summary>

MCM は正確な XML パスごとの互換性データを使用し、直接のネイティブ変身が危険または不適切と分かっているエンティティにだけ、限定的な安全経路の例外を設けています。プレイヤーが操作する形態では、役立つネイティブの移動、攻撃、見た目、物理挙動をできるだけ保持しつつ、プレイヤー入力と競合する人工知能を無効化します。複雑なボス、強くスクリプト制御されたエンティティ、物理オブジェクトでは専用アダプターが必要になる場合があり、元の人工知能の挙動をすべて完全に再現できるとは限りません。

NoitaPatcher は、エンティティのシリアライズ／デシリアライズ、プレイヤーエンティティの制御引き継ぎ、その他の高度な実行時機能など、強力な復元処理に使用されます。そのため、完全な単体版では MOD の無制限アクセスを要求します。

</details>

<details>
<summary><strong>Entangled Worlds とのマルチプレイヤー統合</strong></summary>

**Entangled Worlds は任意です。** MCM は EW なしでも完全なシングルプレイヤー MOD として動作するよう設計されています。

`quant.ew` が有効な場合、共有アイテム、パーク、天候、ワールドルール、形態と憑依、コンパニオン要求、さらに制御権と同期に関する処理について、実験的なマルチプレイヤー統合が有効になります。すべての参加者で同じ MCM バージョンを使用してください。Noita と EW のすべての特殊な状況で完全な同期を保証することはできないため、マルチプレイヤー対応は意図的に実験的機能として扱われています。

</details>

### 必要環境と外部コンポーネント

- **Noita** — Nolla Games による必須ゲーム本体。
- **NoitaPatcher**（dextercd）— MCM に同梱され、高度な実行時機能と復元に使用されます。
- **lbase64**（Ilya Kolbin）— 同梱されているローカル Base64 実装。
- **Entangled Worlds / Noita Proxy**（IntQuant および貢献者）— 任意のマルチプレイヤー統合。シングルプレイヤーには不要です。

元プロジェクトへの正確なリンク、同梱ファイルのパス、ライセンスと状態の情報は [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) を参照してください。

### トラブルシューティング

- **TAB を押しても何も起きない：**`mod.xml` の正確なパス、MCM の有効化、Unsafe mods/unrestricted API の許可を確認し、Noita を再起動してください。
- **高度な復元機能や一部のワールドルールが使えない：**`metamorph_creative_menu/NoitaPatcher/noitapatcher.dll` が存在し、unrestricted API が許可されていることを確認してください。
- **形態から正しく戻れない：**正確なクリーチャー名または XML と、通常の TAB 復帰で失敗したのか、致命ダメージ後の復元で失敗したのかを報告してください。
- **EW が同期しない：**全員が同じ MCM ビルドと互換性のある EW ビルドを使用していることを確認してください。

### リンク

- [最新ビルド](https://github.com/zerodancing/Metamorph-Creative-Menu/releases/tag/latest-build)
- [不具合を報告](https://github.com/zerodancing/Metamorph-Creative-Menu/issues)
- [外部コンポーネント情報](THIRD_PARTY_NOTICES.md)
- [Noita](https://noitagame.com/)
- [NoitaPatcher](https://github.com/dextercd/NoitaPatcher)
- [NoitaPatcher ドキュメント](https://dexter.döpping.eu/NoitaPatcher/)
- [Entangled Worlds](https://github.com/IntQuant/noita_entangled_worlds)
- [lbase64](https://github.com/iskolbin/lbase64)

[↑ 言語選択へ戻る](#languages)

---

## 開発者向け

実際に動作する MOD は `metamorph_creative_menu/` にあります。

- アーキテクチャ／開発者向けメモ：`metamorph_creative_menu/README.txt`
- 回帰テスト一式：`metamorph_creative_menu/tests/`
- テスト手順：`metamorph_creative_menu/tests/TESTING.txt`
- 外部コンポーネント情報：[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)

リポジトリの自動 `latest-build` ワークフローは、動作可能な `metamorph_creative_menu` フォルダをインストール用 ZIP にまとめ、上記の固定ダウンロード先を更新します。