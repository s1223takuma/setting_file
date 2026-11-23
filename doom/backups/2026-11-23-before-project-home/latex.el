;;; latex.el -*- lexical-binding: t; -*-

;; MacTeXの安定したリンクを使い、再ロードでもPATHを重複させない。
(let ((tex-bin "/Library/TeX/texbin"))
  (when (file-directory-p tex-bin)
    (add-to-list 'exec-path tex-bin)
    (unless (member tex-bin (split-string (or (getenv "PATH") "") path-separator t))
      (setenv "PATH" (concat tex-bin path-separator (getenv "PATH"))))))

(defvar my/latex--jobs (make-hash-table :test #'equal)
  "Running latexmk processes, keyed by the canonical TeX file path.")

(defun my/latex-display-pdf (pdf-file)
  "Display PDF-FILE in a right-side window."
  (when (file-exists-p pdf-file)
    (display-buffer
     (find-file-noselect pdf-file)
     '((display-buffer-in-direction)
       (direction . right)
       (window-width . 0.5)))))

(defun my/latex--request (tex-file &optional show-pdf)
  "Compile TEX-FILE, coalescing saves while a build is running.
SHOW-PDF requests a preview after the last queued build succeeds."
  (cond
   ((file-remote-p tex-file)
    (display-warning 'latex "リモートファイルの自動コンパイルはスキップします。"))
   ((not (executable-find "latexmk"))
    (display-warning 'latex "latexmkが見つかりません。TeX環境を確認してください。"))
   (t
    (setq tex-file (file-truename tex-file))
    (if-let ((running (gethash tex-file my/latex--jobs)))
        (progn
          ;; 終了直後でもsentinelが実行されるまでは新しいprocessを作らない。
          (process-put running 'my/latex-pending t)
          (when show-pdf (process-put running 'my/latex-show-pdf t)))
      (let* ((default-directory (file-name-directory tex-file))
             (pdf-file (concat (file-name-sans-extension tex-file) ".pdf"))
             (log-buffer (get-buffer-create (format "*latexmk: %s*" tex-file))))
        (condition-case err
            (let ((process
                   (make-process
                    :name "latexmk" :buffer log-buffer :noquery t
                    :command (list "latexmk" "-lualatex" "-interaction=nonstopmode"
                                   "-halt-on-error" (file-name-nondirectory tex-file))
                    :sentinel
                    (lambda (proc _event)
                      (when (and (memq (process-status proc) '(exit signal))
                                 (eq proc (gethash tex-file my/latex--jobs)))
                        (remhash tex-file my/latex--jobs)
                        (let ((show (process-get proc 'my/latex-show-pdf)))
                          (cond
                           ((process-get proc 'my/latex-pending)
                            (my/latex--request tex-file show))
                           ((and (eq (process-status proc) 'exit)
                                 (= (process-exit-status proc) 0)
                                 (file-exists-p pdf-file))
                            (when-let ((buffer (get-file-buffer pdf-file)))
                              (with-current-buffer buffer
                                (revert-buffer nil t)
                                (when (derived-mode-p 'pdf-view-mode)
                                  (pdf-view-redisplay))))
                            (when show (my/latex-display-pdf pdf-file)))
                           (t
                            (display-warning
                             'latex (format "コンパイル失敗: %s を確認してください。"
                                            (buffer-name log-buffer)))))))))))
              (process-put process 'my/latex-show-pdf show-pdf)
              (puthash tex-file process my/latex--jobs))
          (error (display-warning 'latex (error-message-string err)))))))))

(defun my/latex-compile ()
  "Compile the current saved TeX file with latexmk and LuaLaTeX."
  (interactive)
  (when buffer-file-name
    (my/latex--request buffer-file-name)))

(defun my/latex-open-pdf-side ()
  "Open the matching PDF on the right, compiling first if needed."
  (when buffer-file-name
    (let ((pdf-file (concat (file-name-sans-extension buffer-file-name) ".pdf")))
      (if (file-exists-p pdf-file)
          (my/latex-display-pdf pdf-file)
        (my/latex--request buffer-file-name t)))))

(defun my/latex-auto-compile ()
  "Automatically compile LaTeX files after saving."
  (when (derived-mode-p 'LaTeX-mode 'latex-mode)
    (my/latex-compile)))

(defun my/latex-setup ()
  "Set up the PDF preview and buffer-local save hook."
  (my/latex-open-pdf-side)
  (add-hook 'after-save-hook #'my/latex-auto-compile nil t))

(add-hook 'LaTeX-mode-hook #'my/latex-setup)
