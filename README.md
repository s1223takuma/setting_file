# macOS Settings

macOS で使用しているアプリや開発ツールの設定ファイルを保管するリポジトリです。

このリポジトリは `~/.config` にある実設定のコピーです。ここにあるファイルは自動では反映・同期されません。

## 収録している設定

```text
.
├── NuGet/
│   └── NuGet.Config
├── calyx/
│   ├── calyx-glass.conf
│   └── calyx-runtime.conf
├── cmux.json
├── fish/
│   └── config.fish
├── gh/
│   └── config.yml
├── ghostty/
│   └── config
├── karabiner/
│   ├── karabiner.json
│   └── assets/complex_modifications/
├── nvim/
│   ├── init.lua
│   ├── lazy-lock.json
│   └── lua/
├── skhd/
│   └── skhdrc
├── starship.toml
└── yabai/
    └── yabairc
```

| パス | 用途 |
| --- | --- |
| `ghostty/` | Ghosttyの外観、背景画像、画面分割、キーバインド |
| `fish/` | PATH、Miniconda、Starshipの初期化 |
| `starship.toml` | シェルプロンプトの表示 |
| `nvim/` | Neovim、LSP、補完、DAP、プラグインの設定 |
| `yabai/` | ウィンドウ配置、余白、透明度、除外ルール |
| `skhd/` | yabai操作とアプリ起動のショートカット |
| `karabiner/` | Karabiner-Elementsと複雑なキー変更 |
| `cmux.json` | cmuxのキーバインドとUI設定 |
| `calyx/` | Calyxの表示・実行設定 |
| `gh/config.yml` | GitHub CLIの一般設定 |
| `NuGet/NuGet.Config` | NuGetパッケージソース |

## セットアップ

必要な設定だけを `~/.config` にコピーしてください。既存の設定は上書きされるため、先にバックアップすることを推奨します。

```sh
mkdir -p ~/.config

cp -R ghostty fish nvim yabai skhd karabiner calyx NuGet ~/.config/
cp starship.toml ~/.config/starship.toml

mkdir -p ~/.config/cmux ~/.config/gh
cp cmux.json ~/.config/cmux/cmux.json
cp gh/config.yml ~/.config/gh/config.yml
```

設定の反映には、対象アプリの再起動や設定の再読み込みが必要な場合があります。

## 主な依存ツール

- Fish
- Starship
- Ghostty
- Neovim
- Git
- yabai
- skhd
- Karabiner-Elements
- cmux

Neovimの検索、LSP、フォーマット、デバッグなどをすべて利用する場合は、`ripgrep`、`fd`、Node.js、Python、各言語のツールチェーンも必要です。Neovimプラグインの固定バージョンは `nvim/lazy-lock.json` に記録しています。

## 注意事項

- `gh/hosts.yml` は認証情報を含むため、このリポジトリでは管理していません。
- 履歴、ログ、キャッシュ、バックアップ、PIDなどの実行状態ファイルは含めていません。
- `ghostty/config` の背景画像はローカルの絶対パスを参照しています。別のMacで使う場合は `background-image` を変更またはコメントアウトしてください。
- Neovim設定には `~/Desktop/memo` など、個人用ディレクトリを前提とするコマンドがあります。必要に応じて `nvim/lua/mycommand.lua` と `nvim/lua/autocmds.lua` を調整してください。
- yabaiとskhdはmacOS向けです。利用にはアクセシビリティ権限など、各アプリが要求する権限設定が必要です。

## 更新方法

実際の設定を変更したあと、該当ファイルをこのリポジトリへ再コピーして差分を確認します。

```sh
git diff
git status
```

認証情報やアプリの履歴が混ざっていないことを確認してからコミットしてください。
