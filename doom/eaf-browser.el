;;; eaf-browser.el -*- lexical-binding: t; -*-

;; EAF 本体とブラウザは ~/.config/emacs/eaf/ に置く。
;; Python 依存関係は EAF 専用の .venv に隔離する。
(let* ((eaf-dir (expand-file-name "eaf/" doom-emacs-dir))
       (python (expand-file-name ".venv/bin/python" eaf-dir))
       (qt-platform (expand-file-name
                     "/opt/homebrew/opt/qtbase/share/qt/plugins/platforms")))
  (when (and (file-readable-p (expand-file-name "eaf.el" eaf-dir))
             (file-readable-p (expand-file-name "app/browser/eaf-browser.el" eaf-dir))
             (file-executable-p python))
    (when (file-exists-p (expand-file-name "libqcocoa.dylib" qt-platform))
      (setenv "QT_QPA_PLATFORM_PLUGIN_PATH" qt-platform))
    (add-to-list 'load-path eaf-dir)
    (require 'eaf)
    (require 'eaf-browser)
    (setq eaf-python-command python)))

(defun my/open-web-in-emacs ()
  "EAF ブラウザで URL または検索語を開く。"
  (interactive)
  (unless (display-graphic-p)
    (user-error "EAF ブラウザは GUI 版 Emacs で使ってください"))
  (unless (fboundp 'eaf-open-browser)
    (user-error "EAF ブラウザが未インストールです"))
  (call-interactively #'eaf-open-browser))

(map! :leader
      :desc "Open web in Emacs"
      "o w" #'my/open-web-in-emacs)

(provide 'my-eaf-browser)
