;;; notebook.el -*- lexical-binding: t; -*-

;; Jupytext keeps the editable Python cells and the original notebook paired.
(defvar-local my/notebook-ipynb-file nil)
(defvar-local my/notebook-repl-buffer nil)

(defvar my/notebook-mode-map (make-sparse-keymap))
(define-minor-mode my/notebook-mode
  "Keys for a Jupytext notebook buffer."
  :lighter " Notebook"
  :keymap my/notebook-mode-map)

(defun my/notebook--data (file)
  "Read the JSON contents of FILE."
  (with-temp-buffer
    (insert-file-contents file)
    (json-parse-buffer :object-type 'hash-table)))

(defun my/notebook--jupytext (&rest args)
  "Run Jupytext with ARGS and report errors without hiding its output."
  (let ((program (or (executable-find "jupytext")
                     (user-error "jupytext が見つかりません: pip install jupytext")))
        (output (generate-new-buffer " *jupytext*")))
    (unwind-protect
        (unless (eq 0 (apply #'process-file program nil output nil args))
          (error "Jupytext: %s" (string-trim (with-current-buffer output
                                                (buffer-string)))))
      (kill-buffer output))))

(defun my/notebook--paired-p (file)
  "Return non-nil if FILE declares a percent-script pair."
  (let* ((data (my/notebook--data file))
         (metadata (gethash "metadata" data))
         (jupytext (and metadata (gethash "jupytext" metadata)))
         (formats (and jupytext (gethash "formats" jupytext))))
    (and (stringp formats)
         (string-match-p "\\bipynb\\b" formats)
         (string-match-p "py:percent" formats))))

(defun my/notebook--kernel (file)
  "Return FILE's Jupyter kernel name, falling back to python3."
  (let* ((metadata (gethash "metadata" (my/notebook--data file)))
         (spec (and metadata (gethash "kernelspec" metadata)))
         (name (and spec (gethash "name" spec))))
    (if (and (stringp name) (not (string-empty-p name))) name "python3")))

(defun my/notebook--sync ()
  "Synchronize the current notebook pair after saving its Python cells."
  (when (and my/notebook-ipynb-file buffer-file-name)
    (my/notebook--jupytext "--sync" my/notebook-ipynb-file)))

(defun my/notebook--sync-after-save ()
  "Synchronize after saving, reporting failures without losing the script."
  (condition-case err
      (my/notebook--sync)
    (error (display-warning 'notebook
                            (format "ノートブックの同期に失敗: %s"
                                    (error-message-string err))))))

(defun my/notebook-sync ()
  "Save and synchronize the current notebook pair."
  (interactive)
  (unless my/notebook-ipynb-file
    (user-error "ノートブックのPythonバッファで実行してください"))
  (save-buffer)
  (my/notebook--sync)
  (message "ノートブックを同期しました"))

(defun my/notebook--show-all-pandas (client)
  "Show every pandas row and column in CLIENT's kernel."
  (jupyter-run-with-client client
    (jupyter-sent
     (jupyter-execute-request
      :code (concat "try:\n"
                    "    import pandas as _notebook_pd\n"
                    "except ImportError:\n"
                    "    pass\n"
                    "else:\n"
                    "    _notebook_pd.set_option('display.max_rows', None)\n"
                    "    _notebook_pd.set_option('display.max_columns', None)\n"
                    "    del _notebook_pd")
      :silent t :store-history nil :handlers nil))))

(defun my/notebook-console ()
  "Show or start the Jupyter console below the notebook."
  (interactive)
  (unless my/notebook-ipynb-file
    (user-error "ノートブックのPythonバッファで実行してください"))
  (require 'jupyter)
  (let* ((existing (and (bound-and-true-p jupyter-current-client)
                        (jupyter-connected-p jupyter-current-client)
                        jupyter-current-client))
         (client (or existing (jupyter-run-repl (my/notebook--kernel my/notebook-ipynb-file)
                                                 (file-name-base my/notebook-ipynb-file)
                                                 t)))
         (repl (oref client buffer)))
    (unless existing
      (my/notebook--show-all-pandas client))
    (setq-local my/notebook-repl-buffer repl)
    (display-buffer-in-side-window
     repl '((side . bottom) (slot . 0) (window-height . 0.32)))
    (when (called-interactively-p 'interactive)
      (message "セル実行: C-c %% e / コンソール: SPC o c"))
    repl))

(defun my/notebook-open (file)
  "Open FILE as a paired notebook with a Jupyter console."
  (interactive (list (read-file-name "Notebook (.ipynb): " nil nil t)))
  (setq file (expand-file-name file))
  (unless (and (file-regular-p file) (string-suffix-p ".ipynb" file))
    (user-error ".ipynb ファイルを選択してください"))
  (let* ((script (concat (file-name-sans-extension file) ".py"))
         (paired (my/notebook--paired-p file))
         (script-buffer (get-file-buffer script)))
    (when (and script-buffer (buffer-modified-p script-buffer))
      (user-error "対応するPythonバッファに未保存の変更があります"))
    (cond
     (paired (my/notebook--jupytext "--sync" file))
     ((file-exists-p script)
      (user-error "%s が既にあります。別の場所に移動してから開いてください" script))
     (t
      (unless (file-exists-p (concat file ".before-emacs"))
        (copy-file file (concat file ".before-emacs")))
      (my/notebook--jupytext "--set-formats" "ipynb,py:percent" file)))
    (when script-buffer
      (with-current-buffer script-buffer
        (revert-buffer :ignore-auto :noconfirm)))
    (find-file script)
    (require 'code-cells)
    (code-cells-mode 1)
    (my/notebook-mode 1)
    (setq-local my/notebook-ipynb-file file)
    (add-hook 'after-save-hook #'my/notebook--sync-after-save nil t)
    (condition-case err
        (my/notebook-console)
      (error (display-warning 'notebook
                              (format "コンソール起動に失敗: %s。SPC o c で再試行できます"
                                      (error-message-string err)))))))

(after! code-cells
  ;; code-cells' direct .ipynb save path discards cell outputs.  Edit the
  ;; paired script instead; opening raw JSON remains available if needed.
  (add-to-list 'auto-mode-alist '("\\.ipynb\\'" . json-mode)))

(after! jupyter
  (setq jupyter-repl-echo-eval-p t))

(map! :leader
      :desc "Open Jupyter notebook" "o n" #'my/notebook-open
      :desc "Notebook console" "o c" #'my/notebook-console)

(map! :map code-cells-mode-map
      :localleader
      :desc "Run cell" "e" #'code-cells-eval
      :desc "Run cell and step" "s" #'code-cells-eval-and-step
      :desc "Next cell" "n" #'code-cells-forward-cell
      :desc "Previous cell" "p" #'code-cells-backward-cell
      :desc "Sync notebook" "w" #'my/notebook-sync)

;; Evil's normal state runs the cell; insert state keeps RET as a newline.
(map! :map my/notebook-mode-map
      :n "RET" #'code-cells-eval-and-step)
