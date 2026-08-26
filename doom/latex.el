;;; latex.el -*- lexical-binding: t; -*-

;; ─────────────────────────────────────
;; TeX Live PATH
;; ─────────────────────────────────────

(let ((tex-bin "/usr/local/texlive/2026/bin/universal-darwin"))
  (add-to-list 'exec-path tex-bin)
  (setenv "PATH"
          (concat tex-bin ":" (getenv "PATH"))))


;; ─────────────────────────────────────
;; PDF display
;; ─────────────────────────────────────

(defun my/latex-display-pdf (pdf-file)
  "Display PDF-FILE in a right-side window."
  (when (file-exists-p pdf-file)
    (let ((pdf-buffer (find-file-noselect pdf-file)))
      (display-buffer
       pdf-buffer
       '((display-buffer-in-direction)
         (direction . right)
         (window-width . 0.5))))))


;; ─────────────────────────────────────
;; Compile
;; ─────────────────────────────────────

(defun my/latex-compile ()
  "Compile the current TeX file with latexmk and LuaLaTeX."
  (interactive)

  (when buffer-file-name
    (let* ((default-directory
            (file-name-directory buffer-file-name))
           (tex-file
            (file-name-nondirectory buffer-file-name))
           (pdf-file
            (concat
             (file-name-sans-extension buffer-file-name)
             ".pdf"))
           (process
            (start-process
             "latexmk"
             "*latexmk*"
             "latexmk"
             "-lualatex"
             tex-file)))

      (set-process-sentinel
       process
       (lambda (proc _event)
         (when (and (eq (process-status proc) 'exit)
                    (= (process-exit-status proc) 0))

           ;; PDFが既に開かれていたら更新
           (when-let ((buffer (get-file-buffer pdf-file)))
             (with-current-buffer buffer
               (revert-buffer nil t)

               (when (derived-mode-p 'pdf-view-mode)
                 (pdf-view-redisplay))))))))))


;; ─────────────────────────────────────
;; Open PDF automatically
;; ─────────────────────────────────────

(defun my/latex-open-pdf-side ()
  "Open the matching PDF on the right.
If it does not exist, compile the TeX file first."
  (when buffer-file-name
    (let* ((tex-file buffer-file-name)
           (pdf-file
            (concat
             (file-name-sans-extension tex-file)
             ".pdf")))

      (if (file-exists-p pdf-file)

          ;; 既にPDFがある
          (my/latex-display-pdf pdf-file)

        ;; まだPDFがない
        (let* ((default-directory
                (file-name-directory tex-file))
               (process
                (start-process
                 "latexmk"
                 "*latexmk*"
                 "latexmk"
                 "-lualatex"
                 (file-name-nondirectory tex-file))))

          (set-process-sentinel
           process
           (lambda (proc _event)
             (when (and (eq (process-status proc) 'exit)
                        (= (process-exit-status proc) 0)
                        (file-exists-p pdf-file))

               (my/latex-display-pdf pdf-file)))))))))


;; ─────────────────────────────────────
;; Auto compile on save
;; ─────────────────────────────────────

(defun my/latex-auto-compile ()
  "Automatically compile LaTeX files after saving."
  (when (derived-mode-p 'LaTeX-mode 'latex-mode)
    (my/latex-compile)))


;; ─────────────────────────────────────
;; Hooks
;; ─────────────────────────────────────

(add-hook 'LaTeX-mode-hook
          (lambda ()
            ;; .texを開いたらPDFを右側へ
            (my/latex-open-pdf-side)

            ;; 保存したら自動コンパイル
            (add-hook 'after-save-hook
                      #'my/latex-auto-compile
                      nil
                      t)))
