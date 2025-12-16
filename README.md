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
|gitに上がっているファイル/フォルダ名|実際に配置されているディレクトリ、ファイルの絶対パス|どの設定ファイルか|備考|
|:-:|:-:|:-:|:-:|
|nvim_cp|~/.config/nvim/|nvim|実際に書いたのはinit.luaとluaディレクトリ内部のファイル|
