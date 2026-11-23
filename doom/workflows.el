;;; workflows.el -*- lexical-binding: t; -*-

;; test.orgで優先度の高い開発ワークフロー。

(defcustom my/markdown-pdf-command
  (expand-file-name "~/Desktop/.mac_setting/cross-platform/md-to-pdf/md-to-pdf")
  "MarkdownをPDFへ変換するコマンド。"
  :type 'file
  :group 'markdown)

(defvar my/markdown-pdf--jobs (make-hash-table :test #'equal)
  "変換中のMarkdownファイルとprocessの対応。")

(defun my/markdown-pdf--display (pdf-file)
  "PDF-FILEを右側に表示する。"
  (when (file-exists-p pdf-file)
    (let ((buffer (find-file-noselect pdf-file)))
      (with-current-buffer buffer
        (revert-buffer nil t))
      (display-buffer
       buffer
       '((display-buffer-in-direction)
         (direction . right)
         (window-width . 0.48))))))

(defun my/markdown-pdf--finished (process _event)
  "PDF変換PROCESSの完了後にプレビューを更新する。"
  (let ((input (process-get process 'my/markdown-pdf-input)))
    (when (and (memq (process-status process) '(exit signal))
               (eq process (gethash input my/markdown-pdf--jobs)))
      (remhash input my/markdown-pdf--jobs)
      (cond
       ((process-get process 'my/markdown-pdf-pending)
        (my/markdown-pdf--request input))
       ((and (eq (process-status process) 'exit)
             (= (process-exit-status process) 0)
             (file-exists-p (process-get process 'my/markdown-pdf-output)))
        (my/markdown-pdf--display
         (process-get process 'my/markdown-pdf-output)))
       (t
        (display-warning
         'markdown-pdf
         (format "PDF変換に失敗しました。%s を確認してください。"
                 (buffer-name (process-buffer process)))))))))

(defun my/markdown-pdf--request (markdown-file)
  "MARKDOWN-FILEのPDFを非同期で生成する。連続保存は最後の状態で再実行する。"
  (when (and markdown-file
             (file-exists-p markdown-file)
             (not (file-remote-p markdown-file)))
    (let* ((input (expand-file-name markdown-file))
           (running (gethash input my/markdown-pdf--jobs)))
      (cond
       (running
        (process-put running 'my/markdown-pdf-pending t))
       ((not (file-executable-p my/markdown-pdf-command))
        (display-warning
         'markdown-pdf
         (format "md-to-pdfが見つかりません: %s" my/markdown-pdf-command)))
       (t
        (let* ((pdf-file (concat (file-name-sans-extension input) ".pdf"))
               (log-buffer
                (get-buffer-create
                 (format "*markdown-pdf: %s*" (file-name-nondirectory input)))))
          (with-current-buffer log-buffer
            (erase-buffer))
          (condition-case err
              (let ((process
                     (make-process
                      :name "markdown-pdf"
                      :buffer log-buffer
                      :noquery t
                      :command (list my/markdown-pdf-command input)
                      :sentinel #'my/markdown-pdf--finished)))
                (process-put process 'my/markdown-pdf-input input)
                (process-put process 'my/markdown-pdf-output pdf-file)
                (puthash input process my/markdown-pdf--jobs))
            (error
             (display-warning 'markdown-pdf (error-message-string err))))))))))

(defun my/markdown-pdf-build ()
  "現在のMarkdownファイルをPDFへ変換する。"
  (interactive)
  (unless (derived-mode-p 'markdown-mode)
    (user-error "Markdown bufferで実行してください"))
  (my/markdown-pdf--request buffer-file-name))

(defun my/markdown-pdf-setup ()
  "Markdownを開いたときと保存したときにPDFを更新する。"
  (when (and buffer-file-name (file-exists-p buffer-file-name))
    (my/markdown-pdf--request buffer-file-name)
    (add-hook 'after-save-hook #'my/markdown-pdf-build nil t)))

(add-hook 'markdown-mode-hook #'my/markdown-pdf-setup)

(defconst my/terminal-workspace-name "Terminal")
(defconst my/terminal-workspace-buffer-name "*terminal-workspace*")

(defun my/terminal-workspace-open ()
  "Terminal workspaceへ移動し、vtermを表示する。"
  (interactive)
  (unless (fboundp 'vterm)
    (user-error "vtermが利用できません"))
  (if (bound-and-true-p persp-mode)
      (+workspace-switch my/terminal-workspace-name t)
    (message "workspaceが無効のため、現在の画面でterminalを開きます"))
  (let ((buffer (get-buffer my/terminal-workspace-buffer-name)))
    (if (buffer-live-p buffer)
        (switch-to-buffer buffer)
      (let ((default-directory (expand-file-name "~/")))
        (vterm my/terminal-workspace-buffer-name)))))

(defun my/terminal-workspace-prepare (&optional frame)
  "起動後にterminal workspaceを用意し、元の画面へ戻る。"
  (when (and (frame-live-p (or frame (selected-frame)))
             (display-graphic-p (or frame (selected-frame)))
             (bound-and-true-p persp-mode)
             (not (+workspace-exists-p my/terminal-workspace-name)))
    (with-selected-frame (or frame (selected-frame))
      (let ((original (+workspace-current-name)))
        (condition-case err
            (unwind-protect
                (my/terminal-workspace-open)
              (when original
                (+workspace-switch original)))
          (error
           (display-warning 'terminal-workspace (error-message-string err))))))))

(defun my/terminal-workspace-schedule (&optional frame)
  "UI初期化後にterminal workspaceの準備を予約する。"
  (let ((target (or frame (selected-frame))))
    (run-with-idle-timer 1 nil #'my/terminal-workspace-prepare target)))

(add-hook 'emacs-startup-hook #'my/terminal-workspace-schedule)
(add-hook 'after-make-frame-functions #'my/terminal-workspace-schedule)

(defun my/sql-open-terminal-side ()
  "SQLファイルを開いたら、同じディレクトリのvtermを右側に表示する。"
  (when (and buffer-file-name
             (string-equal (downcase (or (file-name-extension buffer-file-name) ""))
                           "sql")
             (derived-mode-p 'sql-mode)
             (display-graphic-p)
             (not (file-remote-p buffer-file-name)))
    (let* ((file buffer-file-name)
           (name (format "*sql:%s:%s*"
                         (file-name-base file)
                         (substring (secure-hash 'sha1 file) 0 6)))
           (buffer (get-buffer-create name)))
      (condition-case err
          (progn
            (with-current-buffer buffer
              (setq default-directory (file-name-directory file))
              (unless (derived-mode-p 'vterm-mode)
                (vterm-mode)))
            (let ((window
                   (display-buffer-in-side-window
                    buffer '((side . right)
                             (slot . 0)
                             (window-width . 0.38)))))
              (set-window-dedicated-p window t)))
        (error
         (display-warning 'sql-terminal (error-message-string err)))))))

(add-hook 'find-file-hook #'my/sql-open-terminal-side)

(provide 'workflows)
