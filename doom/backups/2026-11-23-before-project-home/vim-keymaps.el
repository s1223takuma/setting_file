;;; vim-keymaps.el -*- lexical-binding: t; -*-

;; Neovimの lua/keymaps.lua と lua/mycommand.lua から、プラグインに
;; 依存しない操作だけを移植する。

;; `;' はEx入力に使うため、Doomのevil-snipeには奪わせない。
(setq evil-snipe-override-evil-repeat-keys nil)

(after! evil-snipe
  (evil-define-key* 'motion evil-snipe-override-local-mode-map
    ";" nil))

;;; Commands

(defun my/open-memo ()
  (interactive)
  (find-file "~/Desktop/memo/memo.md"))

(defun my/open-secret-memo ()
  (interactive)
  (find-file "~/Desktop/memo/secretmemo.md"))

(defun my/open-daily-memo ()
  (interactive)
  (find-file
   (expand-file-name (format-time-string "%Y-%m-%d.md")
                     "~/Desktop/memo/")))

(defun my/open-daily-log ()
  (interactive)
  (find-file
   (expand-file-name (format-time-string "%Y-%m-%d.md")
                     "~/Desktop/daily_log/")))

(defun my/open-python-scratch ()
  (interactive)
  (find-file "~/Desktop/memo/test.py"))

(defun my/open-swift-scratch ()
  (interactive)
  (find-file "~/Desktop/memo/test.swift"))

(defun my/run-current-file (program &optional input-file)
  "Save and run the current file with PROGRAM.
When INPUT-FILE is non-nil, redirect it to standard input."
  (unless buffer-file-name
    (user-error "Current buffer is not visiting a file"))
  (save-buffer)
  (let ((command
         (format "%s %s%s"
                 program
                 (shell-quote-argument buffer-file-name)
                 (if input-file
                     (format " < %s" (shell-quote-argument input-file))
                   ""))))
    (compile command)))

(defun my/run-python ()
  (interactive)
  (my/run-current-file "python3"))

(defun my/run-swift ()
  (interactive)
  (my/run-current-file "swift"))

(defun my/run-python-with-test-input ()
  (interactive)
  (my/run-current-file "python3" (expand-file-name "test.txt" default-directory)))

(defun my/run-swift-with-test-input ()
  (interactive)
  (my/run-current-file "swift" (expand-file-name "test.txt" default-directory)))

;;; Evil helpers

(after! evil
  (evil-define-command my/evil-delete-char-without-yank (count)
    "Delete COUNT characters without changing registers."
    (interactive "<c>")
    (let ((end (min (line-end-position) (+ (point) (or count 1)))))
      (when (< (point) end)
        (evil-delete (point) end 'exclusive ?_))))

  (evil-define-command my/evil-delete-word-backward-without-yank (count)
    "Delete backward by COUNT words without changing registers."
    (interactive "<c>")
    (let ((end (point)))
      (evil-backward-word-begin (or count 1))
      (evil-delete (point) end 'exclusive ?_)))

  (evil-define-command my/evil-yank-to-eol ()
    "Yank from point to the end of the line."
    (interactive)
    (evil-yank (point) (line-end-position) 'exclusive nil nil))

  (evil-define-command my/evil-shift-left-keep-selection (beg end)
    "Shift the visual selection left and keep it selected."
    :keep-visual t
    (interactive "<r>")
    (evil-shift-left beg end))

  (evil-define-command my/evil-shift-right-keep-selection (beg end)
    "Shift the visual selection right and keep it selected."
    :keep-visual t
    (interactive "<r>")
    (evil-shift-right beg end))

  (evil-define-command my/evil-visual-to-eol ()
    "Extend the visual selection to one character before EOL."
    :keep-visual t
    (interactive)
    (evil-end-of-line nil)
    (unless (bolp)
      (backward-char)))

  (evil-define-command my/evil-visual-paste-register-zero (count)
    "Replace the visual selection using Vim register 0."
    (interactive "p")
    (evil-paste-after count ?0))

  (defun my/evil-tab-edit ()
    (interactive)
    (evil-ex "tabedit "))

  (defun my/evil-force-quit ()
    (interactive)
    (evil-quit t))

  ;; Normal mode. One-key bindings go directly into Evil's base map so Doom's
  ;; auxiliary maps cannot silently replace them.
  (define-key evil-normal-state-map (kbd "<up>")
              (cmd! (evil-previous-line 5)))
  (define-key evil-normal-state-map (kbd "<down>")
              (cmd! (evil-next-line 5)))
  (define-key evil-normal-state-map (kbd "g n") #'tab-bar-new-tab)
  (define-key evil-normal-state-map (kbd "<tab>") #'evil-next-buffer)
  (define-key evil-normal-state-map (kbd "<backtab>") #'evil-prev-buffer)
  (define-key evil-normal-state-map (kbd "x") #'my/evil-delete-char-without-yank)
  (define-key evil-normal-state-map (kbd ";") #'evil-ex)
  (define-key evil-normal-state-map (kbd "Y") #'my/evil-yank-to-eol)
  (define-key evil-normal-state-map (kbd "<escape>") #'evil-ex-nohighlight)

  (map! :leader
        "b t" #'tab-bar-close-tab
        "b d" #'evil-delete-buffer
        "l" #'evil-end-of-line
        "Q" #'my/evil-force-quit)

  ;; `te'だけを差し替え、通常の`t{char}'はそのまま残す。
  (general-define-key
   :states 'normal
   "t" (general-key-dispatch #'evil-find-char-to
         "e" #'my/evil-tab-edit))

  ;; `dw'だけを差し替え、`dd'や`d{motion}'はEvil標準のまま残す。
  (general-define-key
   :states 'normal
   "d" (general-key-dispatch #'evil-delete
         "w" #'my/evil-delete-word-backward-without-yank
         "d" #'evil-delete-whole-line))

  ;; Neovimの `jk'。GeneralはDoom/Evilに同梱されているため追加不要。
  (general-define-key
   :states 'insert
   "j" (general-key-dispatch #'self-insert-command
         "k" #'evil-normal-state))

  (define-key evil-insert-state-map (kbd ",")
              (cmd! (if (derived-mode-p 'vterm-mode)
                        (vterm-send-string ",")
                      (insert ", "))))

  ;; Visual mode
  (define-key evil-visual-state-map (kbd "<")
              #'my/evil-shift-left-keep-selection)
  (define-key evil-visual-state-map (kbd ">")
              #'my/evil-shift-right-keep-selection)
  (define-key evil-visual-state-map (kbd "v") #'my/evil-visual-to-eol)
  (define-key evil-visual-state-map (kbd "C-p")
              #'my/evil-visual-paste-register-zero)

  ;; User-defined Ex commands from mycommand.lua.
  (evil-ex-define-cmd "Memo" #'my/open-memo)
  (evil-ex-define-cmd "Smemo" #'my/open-secret-memo)
  (evil-ex-define-cmd "Dmemo" #'my/open-daily-memo)
  (evil-ex-define-cmd "Dlog" #'my/open-daily-log)
  (evil-ex-define-cmd "P" #'my/open-python-scratch)
  (evil-ex-define-cmd "S" #'my/open-swift-scratch)
  (evil-ex-define-cmd "Py" #'my/run-python)
  (evil-ex-define-cmd "Sw" #'my/run-swift)
  (evil-ex-define-cmd "W" #'save-buffer)
  (evil-ex-define-cmd "Wq" #'evil-save-and-close)
  (evil-ex-define-cmd "As" #'my/run-swift-with-test-input)
  (evil-ex-define-cmd "Ap" #'my/run-python-with-test-input))

;;; vim-keymaps.el ends here
