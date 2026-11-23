;;; project-workspace.el -*- lexical-binding: t; -*-

;; Doomのプロジェクトworkspaceに、軽いホーム画面を追加する。

(require 'seq)
(require 'subr-x)

(defface my/project-home-title
  '((t :inherit default :weight bold :height 1.7))
  "Project Homeのタイトル。")

(defface my/project-home-section
  '((t :inherit font-lock-keyword-face :weight bold :height 1.12))
  "Project Homeの見出し。")

(defface my/project-home-muted
  '((t :inherit shadow))
  "Project Homeの補助テキスト。")

(defface my/project-home-action
  '((((type graphic))
     :foreground "#eceff4" :background "#3b4252"
     :weight medium :box (:line-width (7 . 4) :color "#3b4252"))
    (t :inherit link))
  "Project Homeの操作ボタン。")

(defvar-local my/project-home-root nil
  "このProject Homeが属するプロジェクトのルート。")

(defvar my/project-home-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "g") #'my/project-home-refresh)
    (define-key map (kbd "f") #'my/project-home-find-file)
    (define-key map (kbd "e") #'my/project-home-toggle-explorer)
    (define-key map (kbd "t") #'my/project-home-toggle-terminal)
    (define-key map (kbd "m") #'my/project-home-magit)
    map)
  "Project Homeの操作キー。")

(define-derived-mode my/project-home-mode special-mode "Project Home"
  "プロジェクトの入口を表示するモード。"
  (setq-local display-line-numbers nil)
  (setq-local truncate-lines t))

(after! evil
  (evil-define-key* 'normal my/project-home-mode-map
    "g" #'my/project-home-refresh
    "f" #'my/project-home-find-file
    "e" #'my/project-home-toggle-explorer
    "t" #'my/project-home-toggle-terminal
    "m" #'my/project-home-magit))

(define-button-type 'my/project-home-button
  'follow-link t
  'face 'my/project-home-action
  'mouse-face 'highlight
  'action (lambda (button)
            (funcall (button-get button 'project-home-action))))

(defun my/project-home--insert-button (label action)
  "LABELとACTIONでクリック可能な操作を挿入する。"
  (insert-text-button label
                      'type 'my/project-home-button
                      'project-home-action action
                      'help-echo "RET / click to open"))

(defun my/project-home--git-output (root &rest args)
  "ROOTでGitをARGS付きで実行し、成功時の出力を返す。"
  (when (executable-find "git")
    (with-temp-buffer
      (when (eq 0 (apply #'process-file "git" nil t nil "-C" root args))
        (string-trim (buffer-string))))))

(defun my/project-home--git-summary (root)
  "ROOTのGitブランチと変更件数を短く返す。"
  (when-let ((branch (my/project-home--git-output
                     root "rev-parse" "--abbrev-ref" "HEAD")))
    (let* ((status (my/project-home--git-output root "status" "--short"))
           (count (length (split-string (or status "") "\n" t))))
      (format "Git  %s    %s"
              branch
              (if (zerop count) "clean" (format "%d changed" count))))))

(defun my/project-home--recent-files (root)
  "ROOT内の最近開いたファイルを返す。"
  (seq-take
   (seq-filter
    (lambda (file)
      (and (stringp file)
           (not (file-remote-p file))
           (file-exists-p file)
           (file-in-directory-p file root)))
    (bound-and-true-p recentf-list))
   6))

(defun my/project-home--render ()
  "現在のProject Homeを描画する。"
  (let ((inhibit-read-only t)
        (root my/project-home-root))
    (erase-buffer)
    (insert "\n")
    (insert (propertize
             (file-name-nondirectory (directory-file-name root))
             'face 'my/project-home-title))
    (insert "\n")
    (insert (propertize (abbreviate-file-name root)
                        'face 'my/project-home-muted))
    (insert "\n")
    (when-let ((git (my/project-home--git-summary root)))
      (insert (propertize git 'face 'my/project-home-muted) "\n"))
    (insert "\n")
    (my/project-home--insert-button "Find file" #'my/project-home-find-file)
    (insert "    ")
    (my/project-home--insert-button "Explorer" #'my/project-home-toggle-explorer)
    (insert "    ")
    (my/project-home--insert-button "Terminal" #'my/project-home-toggle-terminal)
    (insert "    ")
    (my/project-home--insert-button "Git status" #'my/project-home-magit)
    (insert "\n\n\n")
    (insert (propertize "Recent files" 'face 'my/project-home-section) "\n\n")
    (if-let ((files (my/project-home--recent-files root)))
        (dolist (file files)
          (insert (propertize (if (display-graphic-p) "•  " ">  ")
                              'face 'font-lock-keyword-face))
          (my/project-home--insert-button
           (file-relative-name file root)
           (let ((path file)) (lambda () (find-file path))))
          (insert "\n"))
      (insert (propertize "No recent files yet. Use Find file to start."
                          'face 'my/project-home-muted) "\n"))
    (insert "\n")
    (insert (propertize
             "f  find file     e  explorer     t  terminal     m  git     g  refresh"
             'face 'my/project-home-muted))
    (goto-char (point-min))))

(defun my/project-home-refresh ()
  "Project Homeの最近のファイルとGit状態を更新する。"
  (interactive)
  (unless (derived-mode-p 'my/project-home-mode)
    (user-error "Project Homeで実行してください"))
  (my/project-home--render))

(defun my/project-home-find-file ()
  "現在のプロジェクトからファイルを探す。"
  (interactive)
  (let ((default-directory my/project-home-root))
    (call-interactively #'projectile-find-file)))

(defun my/project-home-toggle-explorer ()
  "プロジェクトのファイルツリーを開閉する。"
  (interactive)
  (let ((default-directory my/project-home-root))
    (+treemacs/toggle)))

(defun my/project-home-magit ()
  "プロジェクトのGit状態を開く。"
  (interactive)
  (unless (my/project-home--git-output
           my/project-home-root "rev-parse" "--is-inside-work-tree")
    (user-error "このディレクトリはGitリポジトリではありません"))
  (magit-status my/project-home-root))

(defun my/project-home--terminal-name (root)
  "ROOT用のvtermバッファ名を返す。"
  (format "*project-term:%s:%s*"
          (file-name-nondirectory (directory-file-name root))
          (substring (secure-hash 'sha1 root) 0 6)))

(defun my/project-home-toggle-terminal ()
  "プロジェクトルートのvtermを下側に開閉する。"
  (interactive)
  (let* ((root my/project-home-root)
         (name (my/project-home--terminal-name root))
         (buffer (get-buffer name))
         (window (and buffer (get-buffer-window buffer))))
    (if (window-live-p window)
        (delete-window window)
      (unless buffer
        (setq buffer (get-buffer-create name)))
      (with-current-buffer buffer
        (setq default-directory root)
        (unless (derived-mode-p 'vterm-mode)
          (vterm-mode)))
      (select-window
       (display-buffer-in-side-window
        buffer '((side . bottom)
                 (slot . 0)
                 (window-height . 0.28)))))))

(defun my/project-home-open (&optional root)
  "ROOTのProject Homeを開く。ファイルツリーは必要なときだけ表示する。"
  (interactive)
  (let* ((directory (or root
                        (and (fboundp 'doom-project-root) (doom-project-root))
                        (and (fboundp 'projectile-project-root)
                             (projectile-project-root))))
         (directory (and directory (file-name-as-directory
                                    (file-truename directory)))))
    (unless (and directory (file-directory-p directory))
      (user-error "プロジェクト内で実行してください"))
    (let* ((name (format "*Project Home:%s:%s*"
                         (file-name-nondirectory (directory-file-name directory))
                         (substring (secure-hash 'sha1 directory) 0 6)))
           (buffer (get-buffer-create name)))
      (with-current-buffer buffer
        (my/project-home-mode)
        (setq-local my/project-home-root directory)
        (setq-local default-directory directory)
        (my/project-home--render))
      (switch-to-buffer buffer)
      buffer)))

;; Doomのプロジェクト切替とworkspace生成はそのまま使い、入口だけ差し替える。
(setq +workspaces-switch-project-function #'my/project-home-open)

(after! treemacs
  (setq treemacs-width 28))

(map! :leader
      :desc "Open project home"
      "p h" #'my/project-home-open)

(provide 'project-workspace)
