# test.org反映前のバックアップ

`~/Desktop/memo/test.org`を読んで設定を変更する直前の状態です。
前回のUI変更は含まれています。

元に戻すときはDoom設定ディレクトリで次を実行し、Emacsを再起動してください。

```sh
cp backups/2026-11-23-before-test-org/*.el .
cp backups/2026-11-23-before-test-org/assets/dashboard-banner.svg assets/
~/.config/emacs/bin/doom sync
```

新しく追加した `workflows.el` は復旧後に読み込まれません。

`test.org` のDONE変更前の控えも同じディレクトリに保存しています。
元に戻す場合は `cp backups/2026-11-23-before-test-org/test.org ~/Desktop/memo/test.org` を実行してください。
