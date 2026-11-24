;;; org-tasks-cleanup.el -*- lexical-binding: t; -*-

(require 'org)

(defvar my/org-tasks-cleanup-timer nil)

(defun my/org-tasks--file-state (file)
  "Return identity, size, and modification time for FILE."
  (let ((attrs (file-attributes file)))
    (list (file-attribute-inode-number attrs)
          (file-attribute-size attrs)
          (file-attribute-modification-time attrs))))

(defun my/org-tasks--clean-file (file cutoff)
  "Remove old unlinked DONE leaf headings from FILE through CUTOFF.
Return the number removed.  Do not change FILE if it has unsaved edits."
  (let ((visiting (get-file-buffer file)))
    (if (or (and visiting (buffer-modified-p visiting))
            (file-locked-p file))
        0
      (let ((state (my/org-tasks--file-state file))
            (removed 0))
        (with-temp-buffer
          (insert-file-contents file)
          (org-mode)
          (let (ranges)
            (org-map-entries
             (lambda ()
               (let ((scheduled (org-entry-get nil "SCHEDULED")))
                 (when (and (equal (org-get-todo-state) "DONE")
                            scheduled
                            (string-match "<\\([0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\}\\)" scheduled)
                            (not (string-lessp cutoff (match-string 1 scheduled)))
                            ;; Herdr propagates removal of linked tasks to Google Calendar.
                            (not (org-entry-get nil "HERDR_GCAL"))
                            ;; Keep a parent if it contains other tasks.
                            (not (save-excursion (org-goto-first-child))))
                   (push (cons (point)
                               (save-excursion (org-end-of-subtree t t) (point)))
                         ranges)))))
            (setq removed (length ranges))
            (when (> removed 0)
              (dolist (range (sort ranges (lambda (a b) (> (car a) (car b)))))
                (delete-region (car range) (cdr range)))
              (let ((temp (make-temp-file
                           (expand-file-name ".tasks.org-clean-" (file-name-directory file)))))
                (unwind-protect
                    (progn
                      (let ((coding-system-for-write 'utf-8-unix))
                        (write-region (point-min) (point-max) temp nil 'silent))
                      (set-file-modes temp (file-modes file))
                      (unless (equal state (my/org-tasks--file-state file))
                        (error "tasks.org changed during cleanup; no changes applied"))
                      (rename-file temp file t)
                      (when visiting
                        (with-current-buffer visiting
                          (revert-buffer :ignore-auto :noconfirm)
                          (when (derived-mode-p 'org-mode)
                            (org-element-cache-reset)))))
                  (when (file-exists-p temp)
                    (delete-file temp)))))))
        removed))))

(defun my/org-tasks-cleanup ()
  "Remove unlinked DONE tasks scheduled at least seven days ago from tasks.org."
  (interactive)
  (let* ((file (expand-file-name "tasks.org" org-directory))
         (cutoff (format-time-string "%Y-%m-%d"
                                     (time-subtract (current-time) (days-to-time 7)))))
    (when (file-exists-p file)
      (condition-case err
          (let ((count (my/org-tasks--clean-file file cutoff)))
            (when (or (> count 0) (called-interactively-p 'interactive))
              (message "tasks.org: %d 件の古いDONEを削除" count)))
        (error (display-warning 'org-tasks-cleanup (error-message-string err)))))))

;; Check shortly after startup and hourly while Emacs is running.
(when (timerp my/org-tasks-cleanup-timer)
  (cancel-timer my/org-tasks-cleanup-timer))
(setq my/org-tasks-cleanup-timer
      (run-with-timer 60 3600 #'my/org-tasks-cleanup))
