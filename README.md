# macOS + Terminal Development Environment Configs

macOSにおけるターミナル環境（Ghostty, Zsh, tmux, Vim, Neovim, Starship）の設定ファイルを一元管理するためのリポジトリです。

> [!WARNING]  
> **実ファイル管理について**  
> このリポジトリに配置されているファイルは、ホームディレクトリ等で**実際に使用されている設定ファイルのコピー（末尾に `_cp` やフォルダ名に `_cp` が付いたもの）**です。  
> 編集の際は、実ファイルを直接編集したのち、本リポジトリへコピーしてコミットしてください。

---

## 🛠️ ファイル構成

```text
.
├── README.md               # 本ドキュメント
├── ghostty_cp/             # Ghostty ターミナル設定
│   └── config              # アピアランス・画面分割キーマップ
├── nvim_cp/                # Neovim (v0.10+) 設定
│   ├── init.lua            # エントリーポイント & Lazy.nvim 起動
│   ├── lazy-lock.json      # プラグインロックファイル
│   └── lua/
│       ├── autocmds.lua    # 自動処理（保存時整形、メモ・日記自動Gitプッシュ）
│       ├── cmp-config.lua  # 補完エンジン (nvim-cmp) の挙動・ソース
│       ├── colorscheme.lua # Nightfox カラースキーム & 背景透過設定
│       ├── keymaps.lua     # キーマッピング (Telescope, Molten, タブ操作等)
│       ├── lsp.lua         # LSP (Mason経由) / ネイティブLSP設定
│       ├── mycommand.lua   # 自作ユーザーコマンド (実行・メモ・AtCoder)
│       ├── options.lua     # 基本オプション設定
│       └── plugins.lua     # Lazy.nvim プラグイン定義 (Jupyter環境等)
├── starship_cp.toml        # Starship プロンプト設定
├── tmux_cp.conf            # tmux 設定 (Prefix: Ctrl+a, Vimキー移動)
├── vimrc_cp                # 素の Vim 用最小設定
└── zsh_cp                  # Zsh 設定 (Zimfw, エイリアス, 環境変数)
```

---

## 🚀 クイックセットアップ（配置方法）

設定ファイルを実際の場所に反映させるためのコマンドです。既存の設定ファイルがある場合は、適宜バックアップを取ってから実行してください。

```bash
# Zsh
cp zsh_cp ~/.zshrc

# Starship
mkdir -p ~/.config
cp starship_cp.toml ~/.config/starship.toml

# tmux
cp tmux_cp.conf ~/.tmux.conf

# Ghostty
mkdir -p ~/.config/ghostty
cp ghostty_cp/config ~/.config/ghostty/config

# Vim
cp vimrc_cp ~/.vimrc

# Neovim
mkdir -p ~/.config/nvim
cp -r nvim_cp/* ~/.config/nvim/
```

---

## 📝 各設定のハイライト

### 1. Ghostty Terminal (`ghostty_cp/config`)
macOSで高速に動作するモダンなターミナル「Ghostty」の設定です。
- **デザイン**: `nightfox` テーマを適用し、背景透過（`opacity = 0.9`）＋すりガラス効果（Blur）を設定。タイトルバーを透過させて境界線をなくしたスマートな外観。
- **ペイン分割・操作性**: macOSネイティブ感覚で画面分割・移動を行えるようキーマップをバインド。
  - `Cmd + Enter`: 下に分割 (`new_split:down`)
  - `Cmd + Shift + Enter`: 右に分割 (`new_split:right`)
  - `Cmd + 矢印キー`: 分割ペインの移動 (`goto_split`)
  - `Cmd + Shift + 矢印キー`: 分割ペインのリサイズ
  - `Cmd + W`: 現在のペインを閉じる

### 2. Neovim (`nvim_cp/`)
`lazy.nvim` をパッケージマネージャとして採用した、本格的な開発・メモ環境です。

#### 🔹 自動化機能 (`lua/autocmds.lua`)
- **ファイル保存時**: 行末の不要な空白（Trailing Whitespace）を自動削除。
- **カーソル復元**: ファイルを開いた際、最後に編集していたカーソル位置を自動で復元。
- **自動Gitプッシュ（超強力！）**: 
  - `~/Desktop/memo/*` 内のファイルを編集してNeovimを閉じると、自動的に Git 状態を確認。変更があればGitHubへPushするか確認され、コミットメッセージ（デフォルトは `Auto-update memo`）を入力して即座に Push します。
  - `~/Desktop/daily_log/*` (日記) に対しても同様に、退室時に「YYYY-MM-DDの日記」というメッセージで自動コミット＆プッシュを実行。

#### 🔹 独自コマンド (`lua/mycommand.lua` & `lua/keymaps.lua`)
- **クイックメモ**:
  - `:Memo`: `~/Desktop/memo/memo.md` を開く
  - `:Smemo`: `~/Desktop/memo/secretmemo.md` を開く
  - `:Dmemo`: 今日のメモ（日付名 `.md`）を開く
  - `:Dlog`: 今日の日記（日付名 `.md`）を開く
- **クイック開発 & 実行**:
  - `:P` / `:S`: テスト用の Python / Swift ファイルをサクッと開く
  - `:Py` / `:Sw`: 現在開いているコードを縦分割のターミナル（`:terminal`）を起動して即座に実行。
- **AtCoder 用マクロ**:
  - `:As` / `:Ap`: 現在のファイルを保存し、`test.txt` を標準入力として流し込んで実行（Swift/Python対応）。
- **Telescope ファジーファインダー**:
  - `ff`: ファイル検索
  - `F`: ファイル内全文検索 (Live Grep)
  - `fb`: バッファ検索
- **Jupyter Notebookライク環境**:
  - `molten-nvim` と `notebook-navigator` を連携。Pythonコード内の `# %%` セル区切りを認識し、`<leader>r` でセル実行、`]h` / `[h` でセル間を移動可能。画像やプロットは `image.nvim` によりターミナル上に直接描画。

#### 🔹 主要導入プラグイン (`lua/plugins.lua`)
Neovim環境のコアとなる主要プラグインと役割の一覧です。

##### 📂 ファイラー・検索
- **[oil.nvim](https://github.com/stevearc/oil.nvim)**: `-` で親ディレクトリをバッファとして開き、Vimコマンドでファイル名変更や削除、作成を直感的に行えるファイルエクスプローラ。
- **[neo-tree.nvim](https://github.com/nvim-neo-tree/neo-tree.nvim)**: 左側に展開するサイドバー型のツリービュー。
- **[telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)**: 高速かつ拡張性の高いあいまい検索（ファイル検索 `ff`、全文検索 `F` など）。

##### 💻 開発・コーディング支援
- **[nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) & [mason.nvim](https://github.com/williamboman/mason.nvim)**: 各言語のLSPやフォーマッタの自動インストールとネイティブ接続。
- **[nvim-cmp](https://github.com/hrsh7th/nvim-cmp)**: スニペットエンジン（LuaSnip）やLSP、バッファ、コマンドラインをソースとする高機能補完。
- **[conform.nvim](https://github.com/stevearc/conform.nvim)**: 保存時の自動コードフォーマット（stylua, ruff_format, prettier, swiftformatなど）。
- **[nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)**: Treesitterによる高速・高精度なシンタックスハイライト。
- **[trouble.nvim](https://github.com/folke/trouble.nvim)**: エラーや警告（LSP診断）を画面下部にリスト形式で一覧表示（`<leader>xx`）。

##### ✍️ 編集スピード向上
- **[flash.nvim](https://github.com/folke/flash.nvim)**: `s` で画面上の任意の文字へ一瞬でジャンプ、またはTreesitterオブジェクト単位の高速ジャンプ。
- **[nvim-surround](https://github.com/kylechui/nvim-surround)**: 括弧やクォート、HTMLタグなどの囲み文字を素早く変更・削除・追加。
- **[Comment.nvim](https://github.com/numToStr/Comment.nvim)**: 行・ブロックの直感的なコメントトグル。
- **[treesj](https://github.com/Wansmer/treesj)**: `J` キーひとつで、コードブロックの1行化と複数行化をインテリジェントにトグル。
- **[nvim-spider](https://github.com/chrisgrieser/nvim-spider)**: `w`/`e`/`b` 移動で、キャメルケースやスネークケースの単語内境界を認識する高度な移動。

##### 📓 Jupyter Notebook 互換 & ビジュアル
- **[molten-nvim](https://github.com/benlubas/molten-nvim)**: Jupyterカーネルと接続し、コードを実行（REPL環境）。
- **[NotebookNavigator.nvim](https://github.com/GCBallesteros/NotebookNavigator.nvim)**: Python等のコード内にある `# %%` を認識し、セル単位での移動（`]h`/`[h`）や実行（`<leader>r`）を可能に。
- **[image.nvim](https://github.com/3rd/image.nvim) & [diagram.nvim](https://github.com/3rd/diagram.nvim)**: ターミナル上で画像を表示。Markdown内のMermaidなどのダイアグラムや、Jupyterで実行したプロット画像を直接レンダリング。

##### 🎨 外観・操作系
- **[nightfox.nvim](https://github.com/EdenEast/nightfox.nvim)**: メインのダークテーマ（背景透過とすりガラス効果に対応）。
- **[barbar.nvim](https://github.com/romgrk/barbar.nvim)**: ウィンドウ上部に美しく配置されるバッファタブ。
- **[lualine.nvim](https://github.com/nvim-lualine/lualine.nvim)**: 軽量でカスタマイズ可能なステータスライン。
- **[smart-splits.nvim](https://github.com/mrjones2014/smart-splits.nvim)**: tmuxのペイン移動とNeovimのペイン移動を `Ctrl + h/j/k/l` でシームレスに行き来させる。
- **[which-key.nvim](https://github.com/folke/which-key.nvim)**: キーマップの入力を待ち受ける際に、次に押せるキーのヒントをポップアップ表示。
- **[dropbar.nvim](https://github.com/Bekaboo/dropbar.nvim)**: エディタ上部にクラス名や関数名などの現在のコンテキストをパンくずリストで表示（`<leader>;`で選択）。

##### 🐙 Git連携
- **[gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim)**: 差分箇所を行左側に可視化し、Hunkごとのプレビュー（`<leader>hp`）やステージング（`<leader>hs`）が可能。
- **[diffview.nvim](https://github.com/sindrets/diffview.nvim)**: 変更ファイルの差分や履歴をサイドバイサイドで美しく比較するGit差分ビューア。
- **[octo.nvim](https://github.com/pwntester/octo.nvim)**: Neovim内から直接 GitHub の PR（`<leader>op`）や Issue（`<leader>oi`）のレビュー・作成・コメント等を行えるGitHub統合プラグイン。

### 3. Zsh & Starship (`zsh_cp` & `starship_cp.toml`)
Zshプラグインマネージャである **Zimfw** を使用し、高速な補完とシンタックスハイライト、履歴のサブストリング検索を有効化しています。
- **プロンプト**: `Starship` を導入。カレントディレクトリ、Gitブランチ（`🌱`絵文字）、Gitステータス（コンフリクトや差分件数を視覚化）、経過時間を美しく表示。
- **エイリアス**:
  - `ll`, `la`, `lla` などの基本コマンド拡張
  - `mywork`: `~/desktop/project/自主学習` へのクイックジャンプ
  - `vim`, `vi`: 自動的に `nvim` にマッピング
  - `s`: Google検索をターミナルから起動（例：`s neovim configuration` でブラウザ起動）
  - `tmux-source-all`: 起動中のすべての tmux ウィンドウ・ペインで一斉に `source ~/.zshrc` を実行
  - `atcoder`: A/B/C問題を解くためのフォルダとテスト用ファイルを一括生成
- **ツール連携**: `pyenv` / `rbenv` / `zoxide` (スマートな `cd` 移動) の自動ロード。外部に漏らしたくない環境変数は `~/.secrets` に分離して読み込む設計。

### 4. tmux (`tmux_cp.conf`)
- **Prefix**: デフォルトの `Ctrl + b` を押しやすい `Ctrl + a` に変更。
- **ペイン分割**: `|` で左右分割、`-` で上下分割。
- **Vim風ペイン移動**: **Prefixキーなし**で `Ctrl + h/j/k/l` を押すだけでペイン間をシームレスに移動可能。
- **コピーモード**: `vi` キーバインドを設定。`v` で選択開始、`y` でコピーし、macOSのクリップボード (`pbcopy`) と自動連携。
- **ラグ解消**: Neovimのレスポンスを高めるため、ESCキーの待機時間（`escape-time`）を `10ms` に極小化。

### 5. Vim (`vimrc_cp`)
サーバー環境や素のVimを使う場合のための最小構成です。
- **プラグイン**: `vim-plug` で `nightfox` カラースキームを導入。背景はターミナルに合わせて透過。
- **キーバインド**: Neovimと共通の AtCoder 用実行コマンド（`:As`, `:Ap`）、メモ呼び出しコマンド（`:Memo`, `:Dmemo`）、クリップボードコピー（`:C` でファイル全体を `pbcopy`）を実装。
- macOSクリップボード連携（`clipboard=unnamed,unnamedplus`）を標準搭載。

---

## ⌨️ キーバインド・コマンド チートシート

各ツールの主要なキーマップおよび独自定義コマンドの一覧です。

### 1. Neovim (`nvim_cp/`)

#### 🔹 一般・編集操作
- `Space` : Leader キー
- `;` : `:` と同じ（コマンドラインモードへ移行）
- `jk` (挿入モード時) : `<ESC>` (インサートモードを抜ける)
- `x` : ヤンク（コピー）せずに一文字削除
- `dw` : 単語を後方に削除（`vb"_d`）
- `Y` : カーソル位置から行末までヤンク (`y$`)
- `Space + l` : 行末へ移動 (`$`)
- `Space + q` : 強制終了 (`:q!`)
- `Esc` : 検索のハイライトを消去
- `v` (ビジュアルモード時) : 行末まで選択 (`$h`)
- `<` / `>` (ビジュアルモード時) : インデント調整後も選択状態を維持 (`<gv` / `>gv`)
- `Ctrl + p` (ビジュアルモード時) : ヤンク用バッファ（レジスタ `0`）から貼り付け (`"0p`)
- `J` (Treesitter連携) : コードブロックの1行化・複数行化をトグル
- `s` (flash.nvim) : 画面内の任意の箇所へ高速ジャンプ
- `S` (flash.nvim) : Treesitterを使用したノード選択・ジャンプ

#### 📂 ファイラー・検索 (Telescope / Oil / Neotree)
- `ff` : ファイル名であいまい検索 (Telescope)
- `F` : ファイル内全文検索 (Telescope Live Grep)
- `fb` : 開いているバッファを検索 (Telescope)
- `fh` : ヘルプタグを検索 (Telescope)
- `-` : `oil.nvim` を起動（親ディレクトリをエディタのように編集・閲覧）
- `Space + e` : `Neotree` (サイドバーファイルツリー) の表示トグル

#### 📓 Jupyter Notebook風環境 (Molten / NotebookNavigator)
- `Space + mi` : JupyterのPythonカーネルを初期化 (`:MoltenInit python3`)
- `Space + r` : 現在のセル（`# %%` で囲まれた範囲）を実行
- `Space + x` : 現在のセルを実行して次のセルへ移動
- `]h` / `[h` : 次のセル / 前のセルへ移動
- `Space + rl` : カーソル行のコードを実行
- `Space + rv` (ビジュアル選択時) : 選択範囲のコードを実行
- `Space + rr` : セルを再実行

#### 🐙 Git連携 (Gitsigns / Diffview / Octo)
- `]c` / `[c` : 次の Git 差分 (Hunk) / 前の Git 差分へ移動
- `Space + hs` : 現在の差分 (Hunk) をステージ
- `Space + hr` : 現在の差分 (Hunk) をリセット
- `Space + hp` : 現在の差分 (Hunk) をプレビュー
- `Space + xx` : エラー・警告 (Diagnostics) 一覧を画面下に表示 (Trouble)
- `:DiffviewOpen` / `:DiffviewClose` : Git差分ビューアの起動 / 終了
- `Space + op` : GitHub の PR 一覧を表示 (Octo)
- `Space + oi` : GitHub の Issue 一覧を表示 (Octo)

#### 🛠️ 独自コマンド
- `:Memo` : `~/Desktop/memo/memo.md` を開く
- `:Smemo` : `~/Desktop/memo/secretmemo.md` を開く
- `:Dmemo` : 今日のメモ（`YYYY-MM-DD.md`）を開く
- `:Dlog` : 今日の日記（`~/Desktop/daily_log/YYYY-MM-DD.md`）を開く
- `:P` : テスト用Pythonファイル (`~/Desktop/memo/test.py`) を開く
- `:S` : テスト用Swiftファイル (`~/Desktop/memo/test.swift`) を開く
- `:Py` : 現在のPythonファイルを保存し、画面分割したターミナルで実行
- `:Sw` : 現在のSwiftファイルを保存し、画面分割したターミナルで実行
- `:W` / `:Wq` : 保存 / 保存して終了（タイポ対策）
- `:As` : Swiftファイルを保存し、`test.txt` を標準入力として実行 (AtCoder用)
- `:Ap` : Pythonファイルを保存し、`test.txt` を標準入力として実行 (AtCoder用)

### 2. tmux (`tmux_cp.conf`)
- `Ctrl + a` : プレフィックスキー (デフォルトの `Ctrl + b` から変更)
- `Ctrl + h / j / k / l` (Prefixなし) : ペイン間をシームレスに移動（Vimキーバインド）
- `Prefix + |` : 左右にペイン分割
- `Prefix + -` : 上下にペイン分割
- `Prefix + r` : `~/.tmux.conf` の設定を再読み込み
- `Prefix + [` : コピーモードに入る
  - `v` (コピーモード中) : 選択開始
  - `y` (コピーモード中) : 選択範囲をコピーして終了 (macOSのクリップボード `pbcopy` と自動連携)

### 3. Ghostty Terminal (`ghostty_cp/config`)
- `Cmd + Enter` : 下にペイン分割
- `Cmd + Shift + Enter` : 右にペイン分割
- `Cmd + 矢印キー` : 分割したペイン間を移動
- `Cmd + Shift + 矢印キー` : ペインサイズを調整
- `Cmd + W` : 現在のペインを閉じる

### 4. 素の Vim (`vimrc_cp`)
- `Esc` : 検索ハイライトを消去 (`:noh`)
- `:Memo` / `:Dmemo` : メモを開く
- `:Pmemo` : テスト用Pythonファイルを開く
- `:Py` : ファイル全体を python3 で実行
- `:As` / `:Ap` : AtCoder用の標準入力実行
- `:C` : ファイル全体をクリップボードにコピー (`pbcopy` と連携)

### 5. Zsh (`zsh_cp`)
- `mywork` : `~/desktop/project/自主学習` へのクイックジャンプ
- `atcoder` : A, B, C問題用のフォルダとテンプレートファイルを一括作成
- `tmux-source-all` : 実行中のすべての tmux ウィンドウ・ペインで一斉に `source ~/.zshrc` を実行
- `s <検索ワード>` : Google 検索をブラウザで開く (例: `s neovim`)
- `vim` / `vi` : 自動的に `nvim` で起動
- `j / k` (Viモードでの履歴検索) : 入力中コマンドの前方一致で履歴検索

---

## 🔒 セキュリティ方針

- パスワード、APIキー、トークンなどの機密情報は、絶対にこのリポジトリのファイル内に直接記述しないでください。
- 環境変数はすべて `~/.secrets` に記述し、`zsh_cp` の末尾にある以下の読み込み機構によってロードする運用を徹底してください。
  ```bash
  if [[ -f "$HOME/.secrets" ]]; then
    source "$HOME/.secrets"
  fi
  ```

