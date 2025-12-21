# mac / Vim / Neovim / tmux 設定ファイルまとめ

このリポジトリは、  
**macOS + ターミナル + Vim / Neovim / tmux** の設定ファイルを管理するためのものです。

⚠️ **注意**  
このリポジトリに置いてあるファイルは **そのまま使われている実ファイルではありません**。  
実際の設定ファイルを **コピーしたもの（_cp）** を置いています。

---

## 目的

- dotfiles を GitHub で安全に管理したい
- mac / Linux どちらでも再現しやすくしたい
- Neovim で慣れつつ、最終的に Vim も使える状態を維持したい
- tmux × vim の操作体系を統一したい

---

## ファイル構成

```
.
├── nvim_cp
│   ├── init.lua
│   ├── lazy-lock.json
│   ├── lua
│   │   ├── autocmds.lua
│   │   ├── base.lua
│   │   ├── colorscheme.lua
│   │   ├── keymaps.lua
│   │   ├── options.lua
│   │   └── plugins.lua
│   └── plugin
│       └── packer_compiled.lua
├── starship_cp.tomi
├── tmux_cp.conf
├── vimrc_cp
└── zsh_cp
```

---

## 各設定ファイルの役割

### Neovim

| Git上の名前 | 実際の配置先 | 役割 |
|------------|-------------|------|
| `nvim_cp/` | `~/.config/nvim/` | Neovim 設定全体 |
| `init.lua` | `~/.config/nvim/init.lua` | 各 Lua ファイルを読み込むエントリーポイント |
| `autocmds.lua` | `~/.config/nvim/lua/autocmds.lua` | 起動時自動処理（Neo-tree自動起動など） |
| `base.lua` | `~/.config/nvim/lua/base.lua` | 文字コード・共通関数など基礎設定 |
| `options.lua` | `~/.config/nvim/lua/options.lua` | `set number` などの各種オプション |
| `keymaps.lua` | `~/.config/nvim/lua/keymaps.lua` | キーバインド定義 |
| `colorscheme.lua` | `~/.config/nvim/lua/colorscheme.lua` | テーマ設定 |
| `plugins.lua` | `~/.config/nvim/lua/plugins.lua` | プラグイン定義（Packer 使用） |
| `lazy-lock.json` | 同上 | プラグインのバージョン固定用 |

📌 **プラグイン同期**
```vim
:PackerSync
```

---

### tmux

| Git上の名前        | 実際の配置先         | 役割           |
| -------------- | -------------- | ------------ |
| `tmux_cp.conf` | `~/.tmux.conf` | tmux の設定ファイル |

* prefix: `Ctrl + a`
* Vim風 pane 移動（`Ctrl + h/j/k/l`）
* macOS クリップボード連携（pbcopy）

---

### Vim（素の Vim）

| Git上の名前    | 実際の配置先     | 役割          |
| ---------- | ---------- | ----------- |
| `vimrc_cp` | `~/.vimrc` | 最小構成 Vim 設定 |

* 行番号表示
* マウス有効
* macOS クリップボード共有

---

### starship

| Git上の名前    | 実際の配置先     | 役割          |
| ---------- | ---------- | ----------- |
| `starship_cp.toml` | `~/.config/starship.toml` | starshipの設定ファイル |

* ターミナルでのカレントディレクトリの表記
* Pythonのバージョンの表記
* gitのbranchや現在のステータスの表記

---

### ターミナル（zsh）

| Git上の名前  | 実際の配置先     | 役割     |
| -------- | ---------- | ------ |
| `zsh_cp` | `~/.zshrc` | zsh 設定 |

* Zim 使用
* PATH 管理
* alias 定義
* pyenv / virtualenv 対応
* secrets は `.secrets` に分離（Git非管理）

---

## セキュリティ方針

* 実ファイルは直接 Git に上げない
* `.secrets` / APIキー / トークン類は **絶対に含めない**
* 必ずコピーしてからコミットする

---

## セットアップ手順

```sh
cp vimrc_cp ~/.vimrc
cp tmux_cp.conf ~/.tmux.conf
cp -r nvim_cp ~/.config/nvim
cp zsh_cp ~/.zshrc
cp starship_cp.toml ~/.config/starship.toml
```

---

## 前提環境

* macOS
* Homebrew
* Vim / Neovim
* tmux
* zsh

```

---

## 追加するとさらに良くなる情報

### ① キーバインド方針（超おすすめ）
```md
## キーバインド設計方針

- 移動はすべて `hjkl`
- tmux / vim / nvim で操作を揃える
- prefix / leader を極力減らす
```

### ② 依存関係

```md
## 必要なツール

- vim (brew)
- neovim (brew)
- tmux
- pbcopy（macOS）
- Packer.nvim
```

### ③ トラブルシューティング

```md
## よくあるトラブル

### yank が mac のクリップボードに入らない
- vim --version | grep clipboard
- +clipboard が有効か確認
- tmux 経由なら pbcopy 設定必須
```
