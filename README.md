# Terminal Development Environment Configs (macOS / Windows)

ターミナル環境（Ghostty, Zsh, tmux, Vim, Neovim, Starship）の設定ファイルを一元管理するリポジトリです。
macOS を主対象にしていますが、Neovim / Starship / Git は Windows でも使えるように手順を整理しています。

> [!WARNING]
> **実ファイル管理について**
> このリポジトリのファイルは、ホームディレクトリ等で**実際に使っている設定ファイルのコピー**（`_cp` 付き）です。
> 編集するときは実ファイルを直接更新し、その後でこのリポジトリへコピーしてコミットしてください。

> [!NOTE]
> **Windows利用時の注意**
> `zsh_cp` / `tmux_cp.conf` / `ghostty_cp/` は Unix 系専用です。Windows で同じ構成を再現したい場合は
> **WSL2 (Ubuntu)** を使うのが最も手堅いです。Neovim 単体・Starship 単体なら Windows ネイティブでも動作します。
> 詳細は [🪟 Windows対応について](#-windows対応について) を参照してください。

---

## 🛠️ ファイル構成

```text
.
├── README.md               # 本ドキュメント
├── ghostty_cp/              # Ghosttyターミナル設定（macOS/Linux専用）
│   └── config
├── nvim_cp/                 # Neovim (v0.11+) 設定
│   ├── init.lua             # エントリーポイント & lazy.nvim起動
│   ├── lazy-lock.json       # プラグインロックファイル
│   └── lua/
│       ├── autocmds.lua     # 保存時整形、メモ・日記の自動Gitプッシュ
│       ├── cmp-config.lua   # 補完エンジン(nvim-cmp)の挙動・ソース
│       ├── colorscheme.lua  # Nightfoxカラースキーム & 背景透過
│       ├── keymaps.lua      # キーマップ (Telescope, Molten, タブ操作等)
│       ├── lsp.lua          # LSP (Mason経由) 設定
│       ├── mycommand.lua    # 自作ユーザーコマンド (実行・メモ・AtCoder)
│       ├── options.lua      # 基本オプション設定
│       └── plugins.lua      # lazy.nvim プラグイン定義 (Jupyter環境等)
├── starship_cp.toml         # Starshipプロンプト設定（クロスプラットフォーム）
├── tmux_cp.conf              # tmux設定（macOS/Linux/WSL）
├── vimrc_cp                  # 素のVim用最小設定
└── zsh_cp                    # Zsh設定（macOS/Linux/WSL）
```

---

## 📦 事前に必要な依存ツール

`lazy.nvim` はプラグイン本体を自動インストールしますが、LSP・フォーマッタ・画像表示などが依存する**外部コマンド**は事前に用意する必要があります。

### 必須（全プラットフォーム共通）

| ツール             | 用途                                                       | macOS (Homebrew)                                    | Windows (winget)                                                                            |
| ------------------ | ---------------------------------------------------------- | --------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| Git                | プラグイン管理 / 自動push                                  | `brew install git`                                  | `winget install Git.Git`                                                                    |
| Neovim (v0.11+)    | エディタ本体（`vim.lsp.enable` API使用のため0.11以上必須） | `brew install neovim`                               | `winget install Neovim.Neovim`                                                              |
| ripgrep            | Telescope Live Grep (`F`)                                  | `brew install ripgrep`                              | `winget install BurntSushi.ripgrep.MSVC`                                                    |
| fd                 | Telescope高速ファイル検索                                  | `brew install fd`                                   | `winget install sharkdp.fd`                                                                 |
| Node.js (LTS)      | ts_ls / emmet_ls / prettier 等                             | `brew install node`                                 | `winget install OpenJS.NodeJS.LTS`                                                          |
| Python3 + pip      | pyright / ruff / Molten(REPL)                              | `brew install python`                               | `winget install Python.Python.3.12`                                                         |
| Java (JDK 17+)     | jdtls (Java LSP)                                           | `brew install openjdk`                              | `winget install EclipseAdoptium.Temurin.21.JDK`                                             |
| Cコンパイラ + make | treesitter / telescope-fzf-native のビルド                 | Xcode Command Line Tools (`xcode-select --install`) | `winget install Microsoft.VisualStudio.2022.BuildTools` または `winget install MSYS2.MSYS2` |
| Nerd Font          | アイコン表示 (nvim-web-devicons, lualine等)                | `brew install --cask font-jetbrains-mono-nerd-font` | `winget install DEVCOM.JetBrainsMonoNerdFont`                                               |
| Starship           | プロンプト                                                 | `brew install starship`                             | `winget install Starship.Starship`                                                          |

Python側は追加で以下をpip導入（Molten用REPL連携）:

```bash
pip install pynvim jupyter_client ipykernel --user
```

### 任意（機能を使う場合のみ）

| ツール                | 用途                                                      | macOS                             | Windows                                             |
| --------------------- | --------------------------------------------------------- | --------------------------------- | --------------------------------------------------- |
| ImageMagick           | image.nvim / diagram.nvim の画像描画                      | `brew install imagemagick`        | `winget install ImageMagick.ImageMagick`            |
| glow                  | glow.nvim (Markdownプレビュー)                            | `brew install glow`               | `winget install charmbracelet.glow`                 |
| gh (GitHub CLI)       | octo.nvim のPR/Issue操作を安定化                          | `brew install gh`                 | `winget install GitHub.cli`                         |
| SourceKit-LSP / Swift | Swift LSP・`:As`/`:Sw`実行コマンド                        | Xcode同梱（追加インストール不要） | **非対応**（Swift for Windowsは実験的、非推奨）     |
| Ghostty               | ターミナル本体                                            | `brew install --cask ghostty`     | **非対応**（WSL2 + Windows Terminal / WezTerm推奨） |
| WezTerm               | Kittyグラフィックスプロトコル対応ターミナル(image.nvim用) | `brew install --cask wezterm`     | `winget install wez.wezterm`                        |

Rust製CLI（ripgrep/fd/starship等）は `cargo install` でも共通コマンドとして導入可能です:

```bash
cargo install ripgrep fd-find starship
```

---

## 🚀 クイックセットアップ

### macOS

```bash
# Zsh / Starship / tmux / Ghostty
cp zsh_cp ~/.zshrc
mkdir -p ~/.config && cp starship_cp.toml ~/.config/starship.toml
cp tmux_cp.conf ~/.tmux.conf
mkdir -p ~/.config/ghostty && cp ghostty_cp/config ~/.config/ghostty/config

# Vim / Neovim
cp vimrc_cp ~/.vimrc
mkdir -p ~/.config/nvim && cp -r nvim_cp/* ~/.config/nvim/
```

### Windows (PowerShell)

Neovim / Starship のみ、Windowsネイティブで配置できます。

```powershell
# Neovim (設定先: %LOCALAPPDATA%\nvim)
New-Item -ItemType Directory -Force -Path "$env:LOCALAPPDATA\nvim"
Copy-Item -Recurse -Force nvim_cp\* "$env:LOCALAPPDATA\nvim\"

# Starship (設定先: %USERPROFILE%\.config\starship.toml)
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.config"
Copy-Item -Force starship_cp.toml "$env:USERPROFILE\.config\starship.toml"
```

zsh_cp / tmux_cp.conf / ghostty_cp はWSL2内のUbuntu上でmacOSと同じ手順で配置してください。

---

## 🪟 Windows対応について

このNeovim設定をWindowsで使う場合、以下の点に注意してください。

1. **Swift関連機能は動きません**
   `lsp.lua` の `sourcekit`、`mycommand.lua` の `:S` / `:Sw` / `:As`、`plugins.lua` の `swiftformat` はmacOS(Xcode)前提です。Windowsで使う場合はこれらを無効化・削除してください。
2. **ハードコードされた絶対パスの修正が必要**
   `autocmds.lua` / `mycommand.lua` 内の `/Users/sekitakuma/Desktop/memo` のようなmacOS固有の絶対パスは、Windowsでは無効です。
   `vim.fn.expand("~/Desktop/memo")` のようにホームディレクトリ相対で書き換えると、macOS/Windows両対応になります（Windowsでは `~` が `%USERPROFILE%` に解決されます）。
3. **image.nvim / diagram.nvim はターミナル依存**
   Kittyグラフィックスプロトコル対応ターミナル（WezTerm等）が必要です。標準のWindows TerminalやPowerShellコンソールでは画像が表示されません。
4. **jdtlsのパス設定**
   `plugins.lua` 内の `config_mac` は macOS専用のjdtls設定ディレクトリです。Windowsでは `config_win` に変更してください。
5. **総合的におすすめの構成**
   zsh・tmux・Ghosttyまで含めて元の環境をそのまま使いたい場合は、**WSL2 (Ubuntu)** をインストールし、その中でmacOS向け手順をそのまま実行するのが最も手間が少ない方法です。

---

## 📝 各設定のハイライト

### 1. Ghostty Terminal (`ghostty_cp/config`)

- 背景透過（`opacity = 0.9`）とブラーで、軽いすりガラス風の見た目にしています。
- `Cmd+Enter`: 下に分割 / `Cmd+Shift+Enter`: 右に分割 / `Cmd+矢印`: ペイン移動 / `Cmd+Shift+矢印`: リサイズ / `Cmd+W`: ペインを閉じる

### 2. Neovim (`nvim_cp/`)

`lazy.nvim` をパッケージマネージャにした開発・メモ環境です。

#### 自動化機能 (`autocmds.lua`)

- 保存時に行末の不要な空白を自動削除
- ファイルを開くと最後のカーソル位置を復元
- `~/Desktop/memo/*` と `~/Desktop/daily_log/*` を編集してバッファを離れると、差分確認のうえで GitHub へ push するかを尋ねる

#### 独自コマンド (`mycommand.lua` & `keymaps.lua`)

- `:Memo` / `:Smemo` / `:Dmemo` / `:Dlog` で各種メモ・日記ファイルを開く
- `:P` / `:S` でテスト用 Python / Swift ファイルを開く（`:S` は macOS 専用）
- `:Py` / `:Sw` で現在のコードを分割ターミナルから実行する（`:Sw` は macOS 専用）
- `:As` / `:Ap` で `test.txt` を標準入力にして AtCoder 用に実行する（`:As` は macOS 専用）
- `ff` / `F` / `fb` / `fh` で Telescope によるファイル / 全文 / バッファ / ヘルプ検索を行う
- `molten-nvim` + `notebook-navigator` により `# %%` セルを認識し、`<leader>r` で実行、`]h` / `[h` でセル移動、`image.nvim` でプロットを描画する

#### 主要プラグイン (`plugins.lua`)

| カテゴリ           | プラグイン                                                                                          |
| ------------------ | --------------------------------------------------------------------------------------------------- |
| ファイラー・検索   | oil.nvim, neo-tree.nvim, telescope.nvim                                                             |
| 開発支援           | nvim-lspconfig, mason.nvim, nvim-cmp, conform.nvim, nvim-treesitter, trouble.nvim, **lspsaga.nvim** |
| 実行・デバッグ     | **jaq-nvim**（コード即実行）, **nvim-dap + nvim-dap-ui**（デバッガ）                                |
| 編集スピード       | flash.nvim, nvim-surround, Comment.nvim, treesj, nvim-spider                                        |
| Jupyter/ビジュアル | molten-nvim, NotebookNavigator.nvim, image.nvim, diagram.nvim                                       |
| 外観・操作         | nightfox.nvim, barbar.nvim, lualine.nvim, smart-splits.nvim, which-key.nvim, dropbar.nvim           |
| Git連携            | gitsigns.nvim, diffview.nvim, octo.nvim, **neogit**                                                 |

#### 🌱 Neogit の使い方（add / commit / push を Neovim 内で完結）

`Space+gg`（`:Neogit`）を実行すると、専用のステータス画面が開きます。表示はおおむね次のような構成です。

```text
Untracked files (1)
  new_file.py

Unstaged changes (2)
  modified: plugins.lua
  modified: keymaps.lua

Staged changes (0)

Recent commits
  a1b2c3d 前回のコミット
```

**基本操作**

| キー      | 動作                                                                    |
| --------- | ----------------------------------------------------------------------- |
| `s`       | カーソル位置のファイル（またはhunk）をステージ（add相当）               |
| `u`       | ステージ解除（unstage）                                                 |
| `x`       | 変更を破棄（discard。取り消せないので注意）                             |
| `Tab`     | ファイルを展開してdiffをインライン表示（hunk単位で`s`できるようになる） |
| `c` → `c` | コミットメッセージ入力画面を開いてコミット                              |
| `P` → `p` | push                                                                    |
| `F` → `p` | pull                                                                    |
| `g?`      | 今使えるキー一覧をオーバーレイ表示（迷ったらこれ）                      |
| `q`       | 画面を閉じる                                                            |

つまずきやすい原因は主に3つです。

1. **カーソル位置がファイル名の行からずれている** - 見出し行（`Unstaged changes (2)` など）や空行の上で `s` を押しても反応しません。ファイル名の行に合わせる必要があります。
2. **`Tab` で hunk を展開した状態のまま `s` を押している** - 展開中の `s` は、その hunk にだけ効きます。ファイル全体をステージしたい場合は、畳んだ状態で `s` を押してください。
3. **見た目だけの問題で、実は成功している** - 確認したい場合は、`toggleterm.nvim`（`Ctrl+\`）などで実際に以下を実行するのが確実です。
   ```bash
   git status
   ```
   `Changes to be committed:` の下に対象ファイルが出ていればステージ成功です。

---

## 📄 設定ファイルの内容メモ

このリポジトリにある `_cp` 付きファイルの要点を、用途が分かる程度にまとめています。

### `starship_cp.toml`

- `python` のバージョン表示と virtualenv 表示を有効化
- `git_branch` / `git_status` / `git_metrics` を表示
- `directory` はフルパス表示、`time` は `MM/DD HH:MM:SS` 形式で表示

### `tmux_cp.conf`

- prefix を `Ctrl+A` に変更
- `|` と `-` で左右分割・上下分割
- `mouse on` と `mode-keys vi` を有効化
- `C-h/j/k/l` で prefix なしのペイン移動
- `y` で `pbcopy` に送ってコピー

### `zsh_cp`

- Zim を使ってモジュール管理
- `bindkey -v` で vi キーバインドを有効化
- `pyenv` / `rbenv` / `zoxide` / `starship` を初期化
- `ll` / `la` / `lla` / `vim` / `vi` などのエイリアスを定義
- `s` 関数で Google 検索をブラウザで開く

### `vimrc_cp`

- `nightfox.nvim` を Vim 側で読み込んで配色を設定
- 行番号表示、`wildmenu`、`showcmd` を有効化
- HTML / Markdown で `<CR>` を `<br>` 挿入に割り当て
- `:Memo` / `:Dmemo` / `:Pmemo` / `:Py` / `:As` / `:Ap` / `:C` を定義
- `set clipboard=unnamed` と `unnamedplus` でクリップボード連携

### `ghostty_cp/config`

- `theme = nightfox` を使用
- 透過と余白で、軽いすりガラス風の見た目に調整
- macOS 向けにタイトルバー、マウス挙動、カーソルを設定
- `Cmd+Enter` 系で分割、`Cmd+矢印` で移動、`Cmd+Shift+矢印` でリサイズ
- `Cmd+W` で現在のペインを閉じる

**一連の流れの例**

1. `Space+gg` でNeogitを開く
2. `modified: plugins.lua` の行にカーソルを合わせて `s` → Staged changesへ移動すれば成功
3. `c` → `c` でコミットメッセージバッファが開く。メッセージを書いて `<C-c><C-c>`（または保存して閉じる）でコミット確定
4. `P` → `p` でpush

**補足**

- `octo.nvim`（PR/Issue管理）とは役割が別なので共存に問題ありません。Neogitでコミット・push → `Space+oc`でPR作成、という流れで使えます。
- `diffview`統合を有効にしているので、Neogit画面から差分を開くと使い慣れたdiffview.nvimのUIで表示されます。

### 3. Zsh & Starship — macOS/Linux/WSL

- `Zimfw` による高速補完・シンタックスハイライト・履歴検索
- Starshipでディレクトリ・Gitブランチ・差分件数・経過時間を表示
- `mywork` / `atcoder` / `s <検索語>` / `tmux-source-all` などのエイリアス
- 機密情報は `~/.secrets` に分離

### 4. tmux — macOS/Linux/WSL

- Prefix: `Ctrl+a`、`|`/`-` でペイン分割、Prefixなし `Ctrl+h/j/k/l` でシームレス移動
- コピーモードは `vi` キーバインド、`pbcopy` と自動連携

### 5. Vim (`vimrc_cp`)

- サーバー環境用の最小構成。`vim-plug` + `nightfox`、AtCoder用コマンド、`:C` でクリップボードコピー

---

## ⌨️ キーバインド・コマンド チートシート

### Neovim — 基礎

| キー                                 | 動作                                                    |
| ------------------------------------ | ------------------------------------------------------- |
| **モード変換（自モード以外で作動）** |                                                         |
| `<Esc>`                              | Normalモードに変更（デフォルト）                        |
| `i`                                  | Insertモード（文字入力モード）                          |
| `v`                                  | Visualモード（選択モード）                              |
| `;` / `:`                            | コマンドモード                                          |
| **ちょっと特殊なモード**             |                                                         |
| `V`                                  | 行選択モード（行ごとに選択）                            |
| `<C-v>`                              | 矩形（範囲）選択モード                                  |
| **移動 (Normalモード)**              |                                                         |
| `h` / `j` / `k` / `l`                | 左 / 下 / 上 / 右                                       |
| `w` / `b`                            | 次/前の単語頭へ（**nvim-spiderにより拡張**、下記参照）  |
| `e`                                  | 単語末尾へ（**nvim-spiderにより拡張**、下記参照）       |
| `0` / `$`                            | 行頭へ / 行末へ                                         |
| `gg` / `G`                           | ファイル先頭へ / ファイル末尾へ                         |
| `{数字}G`                            | 指定行へジャンプ（例: `10G`で10行目）                   |
| `Ctrl+d` / `Ctrl+u`                  | 半ページ下/上スクロール                                 |
| **削除・変更**                       |                                                         |
| `x`                                  | カーソル位置の1文字削除                                 |
| `dd`                                 | 行を1行削除（カット）                                   |
| `{数字}dd`                           | 指定行数だけ削除（例: `3dd`で3行削除）                  |
| `dw`                                 | カーソル位置から単語末尾まで削除                        |
| `d$` （または`D`）                   | カーソル位置から行末まで削除                            |
| `cc`                                 | 行を削除してInsertモードへ（変更）                      |
| `cw`                                 | 単語を削除してInsertモードへ                            |
| `r{文字}`                            | カーソル位置の1文字を置換                               |
| `u` / `Ctrl+r`                       | 元に戻す（undo） / やり直す（redo）                     |
| **ヤンク（コピー）・ペースト**       |                                                         |
| `yy`                                 | 行を1行ヤンク（コピー）                                 |
| `{数字}yy`                           | 指定行数だけヤンク（例: `3yy`で3行コピー）              |
| `yw`                                 | カーソル位置から単語末尾までヤンク                      |
| `y$`                                 | カーソル位置から行末までヤンク                          |
| `p`                                  | ヤンク/削除した内容をカーソルの**後ろ（下）**に貼り付け |
| `P`                                  | ヤンク/削除した内容をカーソルの**前（上）**に貼り付け   |
| **Visualモードでの操作**             |                                                         |
| `v` → 移動 → `d`                     | 選択範囲を削除                                          |
| `v` → 移動 → `y`                     | 選択範囲をヤンク                                        |
| `v` → 移動 → `c`                     | 選択範囲を削除してInsertモードへ                        |
| **検索**                             |                                                         |
| `/{文字列}` → `Enter`                | 前方検索、`n`/`N`で次/前の候補へ                        |
| `*`                                  | カーソル位置の単語を前方検索                            |

> **補足: `w`/`e`/`b`について**
> `nvim-spider`により、`camelCase`や`snake_case`の区切りも単語境界として認識するようになっています。素のVimより少ない回数の移動で目的の単語に到達できます（`dw`/`cw`等の組み合わせにも適用されます。ただ、相変わらず日本語には弱いです。）。

### Neovim — 一般・編集

| キー              | 動作                                     |
| ----------------- | ---------------------------------------- |
| `Space`           | Leaderキー                               |
| `;`               | `:` (コマンドラインモード)               |
| `jk` (挿入モード) | `<ESC>`                                  |
| `x`               | ヤンクせず1文字削除                      |
| `dw`              | 単語を後方削除                           |
| `Y`               | 行末までヤンク                           |
| `Space+l`         | 行末へ移動                               |
| `Space+q`         | 強制終了                                 |
| `Esc`             | 検索ハイライト消去                       |
| `s` / `S`         | flash.nvim ジャンプ / Treesitterジャンプ |
| `J`               | ブロックの1行化/複数行化トグル (treesj)  |

### Neovim — ファイラー・検索

| キー                     | 動作                                                |
| ------------------------ | --------------------------------------------------- |
| `ff` / `F` / `fb` / `fh` | ファイル検索 / 全文検索 / バッファ検索 / ヘルプ検索 |
| `-`                      | oil.nvim起動                                        |
| `Space+e`                | Neo-treeトグル                                      |

### Neovim — Jupyter風環境

| キー                    | 動作                        |
| ----------------------- | --------------------------- |
| `Space+mi`              | `:MoltenInit python3`       |
| `Space+r` / `Space+x`   | セル実行 / セル実行して次へ |
| `]h` / `[h`             | 次/前のセルへ移動           |
| `Space+rl` / `Space+rv` | 行実行 / 選択範囲実行       |
| `Space+rr`              | セル再実行                  |

### Neovim — Git連携

| キー                                 | 動作                                   |
| ------------------------------------ | -------------------------------------- |
| `]c` / `[c`                          | 次/前のHunkへ移動                      |
| `Space+hs` / `Space+hr` / `Space+hp` | Hunkのステージ / リセット / プレビュー |
| `Space+xx`                           | Trouble診断一覧                        |
| `Space+gg`                           | Neogitを開く（Git Status画面）         |
| `Space+gc`                           | Neogit: コミット画面を開く             |
| `Space+gp`                           | Neogit: push                           |
| `Space+oc`                           | Octo PR作成                            |
| `Space+op` / `Space+oi`              | Octo PR一覧 / Issue一覧                |

### Neovim — コード実行 (jaq-nvim)

| キー      | 動作                                         |
| --------- | -------------------------------------------- |
| `Space+j` | カーソルのあるファイルをfloat windowで即実行 |

### Neovim — デバッガ (nvim-dap / nvim-dap-ui)

| キー                                 | 動作                                          |
| ------------------------------------ | --------------------------------------------- |
| `Space+dc`                           | Continue（実行/再開）                         |
| `Space+do` / `Space+di` / `Space+dO` | Step Over / Step Into / Step Out              |
| `Space+db`                           | ブレークポイントの切り替え                    |
| `Space+dB`                           | 条件付きブレークポイントを設定                |
| `Space+dl`                           | ログポイントを設定                            |
| `Space+du`                           | DAP UIの開閉                                  |
| `Space+de`                           | 選択範囲/カーソル下の値を評価 (Normal/Visual) |

> Python以外の言語でデバッグしたい場合は、対応する`nvim-dap-*`アダプタ（例: `leoluz/nvim-dap-go`）を`plugins.lua`に追記してください。

### Neovim — LSP UI強化 (Lspsaga)

| キー                  | 動作                           |
| --------------------- | ------------------------------ |
| `K`                   | リッチなHover表示              |
| `Space+1`             | LSP Finder（参照・実装元一覧） |
| `Space+2`             | Rename                         |
| `Space+3`             | Code Action                    |
| `Space+4`             | 現在行の診断を表示             |
| `Space+5`             | 定義をPeek表示                 |
| `Space+[` / `Space+]` | 前/次の診断へジャンプ          |

### Neovim — 独自コマンド

| コマンド           | 動作                       | プラットフォーム                |
| ------------------ | -------------------------- | ------------------------------- |
| `:Memo` / `:Smemo` | メモファイルを開く         | 全対応\*                        |
| `:Dmemo` / `:Dlog` | 今日のメモ/日記を開く      | 全対応\*                        |
| `:P` / `:S`        | テスト用Python/Swiftを開く | Python:全対応 / Swift:macOSのみ |
| `:Py` / `:Sw`      | 分割ターミナルで実行       | Python:全対応 / Swift:macOSのみ |
| `:W` / `:Wq`       | 保存 / 保存終了            | 全対応                          |
| `:As` / `:Ap`      | AtCoder標準入力実行        | Python:全対応 / Swift:macOSのみ |

\* パスがmacOSハードコードのため、Windowsで使う場合は前述の修正が必要です。

### tmux

| キー                        | 動作                         |
| --------------------------- | ---------------------------- |
| `Ctrl+a`                    | Prefix                       |
| `Ctrl+h/j/k/l` (Prefixなし) | ペイン移動                   |
| `Prefix+`/`Prefix+-`        | 左右/上下分割                |
| `Prefix+r`                  | 設定リロード                 |
| `Prefix+[` → `v`/`y`        | コピーモード開始/選択/コピー |

### Ghostty (macOS/Linux)

| キー                            | 動作                  |
| ------------------------------- | --------------------- |
| `Cmd+Enter` / `Cmd+Shift+Enter` | 下/右に分割           |
| `Cmd+矢印` / `Cmd+Shift+矢印`   | ペイン移動 / リサイズ |
| `Cmd+W`                         | ペインを閉じる        |

### 素のVim

| コマンド              | 動作                                 |
| --------------------- | ------------------------------------ |
| `Esc`                 | 検索ハイライト消去                   |
| `:Memo` / `:Dmemo`    | メモを開く                           |
| `:Py` / `:As` / `:Ap` | 実行系コマンド                       |
| `:C`                  | ファイル全体をクリップボードにコピー |

### Zsh

| コマンド          | 動作                               |
| ----------------- | ---------------------------------- |
| `mywork`          | プロジェクトディレクトリへジャンプ |
| `atcoder`         | A/B/C問題フォルダ一括生成          |
| `s <検索語>`      | ブラウザでGoogle検索               |
| `vim` / `vi`      | `nvim` にマッピング                |
| `tmux-source-all` | 全tmuxペインで`.zshrc`再読込       |

---

## 🔒 セキュリティ方針

- パスワード・APIキー・トークン等はこのリポジトリに直接記述しないこと。
- 環境変数は `~/.secrets` に分離し、`zsh_cp` 末尾の以下の読み込み機構でロードする：
  ```bash
  if [[ -f "$HOME/.secrets" ]]; then
    source "$HOME/.secrets"
  fi
  ```
- Windowsで同等の運用をする場合は `%USERPROFILE%\.secrets.ps1` を作成し、PowerShellプロファイル (`$PROFILE`) から `. $HOME\.secrets.ps1` で読み込む形にすると同じ思想を踏襲できます。
