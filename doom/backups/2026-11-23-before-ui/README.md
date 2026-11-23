# UI変更前のバックアップ

2026-11-23の変更前に、設定ファイルをそのままコピーしたものです。

元に戻すときはDoom設定ディレクトリで次を実行し、Emacsを再起動してください。

```sh
cp backups/2026-11-23-before-ui/*.el .
~/.config/emacs/bin/doom sync
```

新しく追加した `assets/dashboard-banner.svg` は復旧後に使われません。
