# macとかvim/neovimとかtmuxとかの設定ファイル一覧

## ファイル構成
##### (このファイルはコピーであり、実際の設定ファイルとは名前や配置場所が少し違います。ご注意ください)
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
├── README.md
├── tmux_cp.conf
├── vimrc_cp
└── zsh_cp
```

## 各ファイル/フォルダ
|影響するコマンド/アプリ|gitに上がっているファイル/フォルダ名|実際に配置されているディレクトリ、ファイルの絶対パス|備考|
|:-:|:-:|:-:|:-:|
|nvim|nvim_cp|~/.config/nvim/|実際に書いたのはinit.luaとluaディレクトリ内部のファイル|
||init.lua|~/.config/nvim/init.lua|luaディレクトリに書かれているプログラムをまとめている。簡単に書きたい場合はこれだけ書けばいい|
||autocmds.lua|~/.config/nvim/lua/autocmds.lua|`nvim`コマンドを入力した際に実行するプログラム群,Neotreeとかを自動で開くとかで使う|
||base.lua|~/.config/nvim/lua/base.lua|encodeingの指定とかユーザー独自のコマンド作りたい時とかに使う|
||colorscheme.lua|~/.config/nvim/lua/colorscheme.lua|nvimの見た目とかの設定|
||keymaps.lua|~/.config/nvim/lua/keymaps.lua|独自のショートカットコマンド(keymap)を作るときに使う|
||options.lua|~/.config/nvim/lua/options.lua|nvimの各種設定を書くファイル|
||plugins.lua|~/.config/nvim/lua/plugins.lua|プラグインを入れる時とか同期する時とかに使う`PackerSync`でプラグインを同期することもできる|

