;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-
;; 日本語環境の設定

(set-language-environment "Japanese")
(prefer-coding-system 'utf-8)
(set-default 'buffer-file-coding-system 'utf-8)
;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-one)
(setq-default tab-width 4)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")
(after! org
  (setq org-agenda-files
        (list (expand-file-name "tasks.org" org-directory)))

  (setq org-capture-templates
        '(("t" "Todo" entry
           (file+headline "tasks.org" "Inbox")
           "* TODO %?\n"))))

;; Herdr updates tasks.org outside Emacs. A stale Org element cache can then
;; point into the middle of a planning line and abort agenda generation.
(defun my/org-agenda-reset-file-caches (&rest _)
  (dolist (file (org-agenda-files t))
    (when (file-readable-p file)
      (with-current-buffer (find-file-noselect file)
        (org-element-cache-reset)))))
(advice-add #'org-agenda :before #'my/org-agenda-reset-file-caches)

;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `with-eval-after-load' block, otherwise Doom's defaults may override your
;; settings. E.g.
;;
;;   (with-eval-after-load 'PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look them up).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.
;; クリップボードの設定
(setq select-enable-clipboard t)

(unless (display-graphic-p)
  (setq interprogram-cut-function
        (lambda (text &optional _push)
          (let ((process-connection-type nil))
            (let ((proc (start-process "pbcopy" nil "pbcopy")))
              (process-send-string proc text)
              (process-send-eof proc)))))
  (setq interprogram-paste-function
        (lambda ()
          (shell-command-to-string "pbpaste"))))
;; corfuの自動補完をON
(after! corfu
  (setq corfu-auto t
        corfu-auto-prefix 1
        corfu-auto-delay 0.1))

;; Neovimで使っている自作キーマップとExコマンド（プラグイン非依存）。
(load! "vim-keymaps")
(load! "keymap")

;; 見た目のロード
(load! "apperance")

;; Xcode系のコマンド
(load! "xcode")


;; Pyrightは整形に対応しないため、Ruffを優先する。
(defun my/python-format-buffer ()
  "Format with Ruff, or a formatting-capable LSP server if available.
A missing formatter or invalid source must not prevent saving."
  (condition-case err
      (if-let ((ruff (executable-find "ruff")))
          (let ((output (generate-new-buffer " *python-format*"))
                (coding-system-for-read 'utf-8-unix)
                (coding-system-for-write 'utf-8-unix))
            (unwind-protect
                (save-restriction
                  (widen)
                  (if (eq 0 (call-process-region
                             (point-min) (point-max) ruff nil (list output nil) nil
                             "format" "--stdin-filename"
                             (or buffer-file-name "buffer.py") "-"))
                      (save-excursion (replace-buffer-contents output))
                    (display-warning 'python-format
                                     "Ruffの整形に失敗しました。元の内容で保存します。")))
              (kill-buffer output)))
        (when (and (bound-and-true-p lsp-mode)
                   (fboundp 'lsp-feature?)
                   (or (lsp-feature? "textDocument/formatting")
                       (lsp-feature? "textDocument/rangeFormatting")))
          (lsp-format-buffer)))
    (error (display-warning 'python-format (error-message-string err)))))

(defun my/python-format-on-save ()
  (remove-hook 'before-save-hook #'lsp-format-buffer t)
  (add-hook 'before-save-hook #'my/python-format-buffer nil t))

(add-hook 'python-mode-hook #'my/python-format-on-save)
(add-hook 'python-ts-mode-hook #'my/python-format-on-save)

;; corfuの設定
(after! corfu
  (unless (display-graphic-p)
    (corfu-terminal-mode +1)))

;; githubの認証系(forgeで使用)
(setq auth-sources '("~/.authinfo.gpg"))

;; ダッシュボードの設定
(load! "dashboard")

;; Markdown/PDF、SQL、terminal workspace
(load! "workflows")

;; プロジェクトごとの作業画面
(load! "project-workspace")

;; 上部のファイルタブ
(after! centaur-tabs
  (setq centaur-tabs-height 28
        centaur-tabs-bar-height 34))

;; texの自動化
(load! "latex")

;; gptel

(load! "ai")

;; Emacs 内で Web ページを表示する EAF ブラウザ
(load! "eaf-browser")

;; Jupyter notebooks: cell editor, console, and plots.
(load! "notebook")

;; Remove completed tasks whose scheduled date is at least a week old.
(load! "org-tasks-cleanup")
