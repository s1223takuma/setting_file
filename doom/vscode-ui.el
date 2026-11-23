;;; vscode-ui.el -*- lexical-binding: t; -*-

;; Project Home の左端に、VS Code の Activity Bar に相当する入口を置く。
;; このファイルは実験ブランチだけで読み込む。

(require 'button)

(defface my/vscode-activity-face
  '((t :inherit default :height 1.3))
  "Activity Bar のアイコン。")

(defvar-local my/vscode-activity-root nil)

(define-derived-mode my/vscode-activity-mode special-mode "Activity"
  "プロジェクト操作用の細いサイドバー。"
  (setq-local display-line-numbers nil
              truncate-lines t
              mode-line-format nil
              header-line-format nil
              cursor-type nil))

(defun my/vscode-activity--button (icon help action)
  (insert "\n ")
  (insert-text-button
   icon 'face 'my/vscode-activity-face
   'mouse-face 'highlight
   'help-echo help
   'follow-link t
   'action (lambda (_button)
             (let ((root my/vscode-activity-root))
               (funcall action root))))
  (insert "\n"))

(defun my/vscode-activity--home-buffer (root)
  (catch 'found
    (dolist (buffer (buffer-list))
      (with-current-buffer buffer
        (when (and (derived-mode-p 'my/project-home-mode)
                   (equal my/project-home-root root))
          (throw 'found buffer))))))

(defun my/vscode-activity--explorer (root)
  (let ((default-directory root))
    (+treemacs/toggle)))

(defun my/vscode-activity--search (root)
  (let ((default-directory root))
    (consult-ripgrep root)))

(defun my/vscode-activity--git (root)
  (magit-status root))

(defun my/vscode-activity--ai (_root)
  (call-interactively #'gptel))

(defun my/vscode-activity--terminal (root)
  (if-let ((home (my/vscode-activity--home-buffer root)))
      (with-current-buffer home
        (my/project-home-toggle-terminal))
    (user-error "Project Home を先に開いてください")))

(defun my/vscode-activity--render (root)
  (let ((inhibit-read-only t))
    (erase-buffer)
    (setq-local my/vscode-activity-root root
                default-directory root)
    (my/vscode-activity--button "▣" "Explorer" #'my/vscode-activity--explorer)
    (my/vscode-activity--button "⌕" "Search in project" #'my/vscode-activity--search)
    (my/vscode-activity--button "⑂" "Git status" #'my/vscode-activity--git)
    (my/vscode-activity--button "✦" "AI chat" #'my/vscode-activity--ai)
    (my/vscode-activity--button ">" "Terminal" #'my/vscode-activity--terminal)
    (goto-char (point-min))))

(defun my/vscode-activity-show (&rest _)
  "Project Home を開いた後、左端に Activity Bar を表示する。"
  (when (and (display-graphic-p)
             (derived-mode-p 'my/project-home-mode)
             my/project-home-root)
    (let ((root my/project-home-root)
          (home-window (selected-window))
          (buffer (get-buffer-create "*Activity Bar*")))
      (with-current-buffer buffer
        (my/vscode-activity-mode)
        (my/vscode-activity--render root))
      (let ((window (display-buffer-in-side-window
                     buffer '((side . left)
                              (slot . -1)
                              (window-width . 5)))))
        (set-window-dedicated-p window t)
        (set-window-parameter window 'no-delete-other-windows t))
      (when (window-live-p home-window)
        (select-window home-window)))))

(advice-add #'my/project-home-open :after #'my/vscode-activity-show)

(after! centaur-tabs
  (setq centaur-tabs-height 28
        centaur-tabs-bar-height 34))

(after! demap
  (setq demap-minimap-window-width 14))

(defun my/vscode-ui-open-minimap ()
  "GUI でコードを開いたときに右側へミニマップを表示する。"
  (when (and (display-graphic-p)
             (derived-mode-p 'prog-mode)
             (not (minibufferp)))
    (demap-open)))

(add-hook 'find-file-hook #'my/vscode-ui-open-minimap)

;; VS Code に近い「ファイル・検索・Git・ターミナル」の入口。
(map! :leader
      :desc "Project explorer" "o e" #'+treemacs/toggle
      :desc "Search project" "s p" #'consult-ripgrep
      :desc "Git status" "g g" #'magit-status
      :desc "Project home" "p h" #'my/project-home-open)

(provide 'vscode-ui)
