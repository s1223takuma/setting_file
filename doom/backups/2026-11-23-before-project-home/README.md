# Project Home変更前のバックアップ

作業画面の改造前に、設定ファイルとSVGをコピーしたものです。
`custom.el` のユーザー設定も含まれます。

元に戻すときはDoom設定ディレクトリで次を実行し、Emacsを再起動してください。

```sh
cp backups/2026-11-23-before-project-home/*.el .
cp backups/2026-11-23-before-project-home/assets/dashboard-banner.svg assets/
```

新しい `project-workspace.el` は復旧後に読み込まれません。
