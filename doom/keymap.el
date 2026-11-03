;;; doom/keymap.el -*- lexical-binding: t; -*-

;;vtermを開くように
(defun toggle/vterm ()
  "vtermのtoggle"
  (interactive)
  (let ((buffer (get-buffer "*vterm*")))
    (if (and buffer (get-buffer-window buffer))
        (delete-window (get-buffer-window buffer))
      (vterm))))

(map! :leader
      :desc "Toggle vterm"
      "o t" #'toggle/vterm)

;; finderを開く
(defun my/open-current-directory-in-finder ()
  "Open the current directory in Finder."
  (interactive)
  (start-process "open-finder" nil "open" default-directory))

(map! :leader
      :desc "Open Finder"
      "o f" #'my/open-current-directory-in-finder)

;; 今開いてるorgfileにpython実行セルを入れる
(defun insert/py ()
  (interactive)
  (unless (derived-mode-p 'org-mode)
   (user-error "Orgモードで実行してください"))
  (insert "\n#+begin_src python" "\n\n" "#+end_src")
  (forward-line -1))

(after! org
  (map! :map org-mode-map
        :leader
        :desc "Insert Python block"
        "i p" #'insert/py))

;; forgeのkeymap
(after! forge
  (map! :leader
        :desc "Forge"
        "g f" #'forge-dispatch
        :desc "Forge-merge"
        "g m" #'forge-merge))
