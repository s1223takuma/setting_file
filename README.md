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

## 🔒 セキュリティ方針

- パスワード、APIキー、トークンなどの機密情報は、絶対にこのリポジトリのファイル内に直接記述しないでください。
- 環境変数はすべて `~/.secrets` に記述し、`zsh_cp` の末尾にある以下の読み込み機構によってロードする運用を徹底してください。
  ```bash
  if [[ -f "$HOME/.secrets" ]]; then
    source "$HOME/.secrets"
  fi
  ```

