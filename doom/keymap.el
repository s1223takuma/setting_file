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

;; forgeのkeymap
(after! forge
  (map! :leader
        :desc "Forge"
        "g f" #'forge-dispatch
        :desc "Forge-merge"
        "g m" #'forge-merge))
