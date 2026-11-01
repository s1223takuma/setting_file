;;; dashboard.el -*- lexical-binding: t; -*-

;; Doom標準のダッシュボード部品を活かした、個人用スタート画面。
;; 外部パッケージは追加せず、Doom/Emacs/有効化済みモジュールのAPIだけを使う。

(require 'cl-lib)
(require 'seq)
(require 'subr-x)

(defgroup my/dashboard nil
  "個人用Doom Dashboard。"
  :group 'doom)

(defface my/dashboard-date
  '((t (:inherit font-lock-comment-face :weight medium :height 1.05)))
  "日付に使うface。"
  :group 'my/dashboard)

(defface my/dashboard-time
  '((t (:inherit default :weight bold :height 1.6)))
  "時刻に使うface。"
  :group 'my/dashboard)

(defface my/dashboard-heading
  '((t (:inherit font-lock-keyword-face :weight bold)))
  "セクション見出しに使うface。"
  :group 'my/dashboard)

(defface my/dashboard-item
  '((t (:inherit default)))
  "項目に使うface。"
  :group 'my/dashboard)

(defface my/dashboard-category
  '((t (:inherit font-lock-type-face :weight medium)))
  "Orgカテゴリー表示に使うface。"
  :group 'my/dashboard)

(defface my/dashboard-muted
  '((t (:inherit font-lock-comment-face)))
  "補助的な表示に使うface。"
  :group 'my/dashboard)

(defcustom my/dashboard-item-count 3
  "各セクションに表示する最大項目数。"
  :type 'integer
  :group 'my/dashboard)

(defcustom my/dashboard-pinned-projects nil
  "DashboardのProjects欄へ優先表示するプロジェクトの一覧。"
  :type '(repeat directory)
  :group 'my/dashboard)

(defcustom my/dashboard-fill-projects-after-pins t
  "固定プロジェクトの後ろを最近のプロジェクトで補完する。"
  :type 'boolean
  :group 'my/dashboard)

(defcustom my/dashboard-cache-seconds 30
  "Org、Recent files、Projectsを再取得するまでの秒数。"
  :type 'integer
  :group 'my/dashboard)

(defcustom my/dashboard-elfeed-cache-seconds 120
  "Elfeedを再取得するまでの秒数。"
  :type 'integer
  :group 'my/dashboard)

(defcustom my/dashboard-default-categories '("Inbox" "大学" "学園祭")
  "Captureの候補へ常に表示するOrgカテゴリー。"
  :type '(repeat string)
  :group 'my/dashboard)

(defcustom my/dashboard-default-category "Inbox"
  "DashboardからTodoを追加するときの既定カテゴリー。"
  :type 'string
  :group 'my/dashboard)

(defcustom my/dashboard-category-filter nil
  "DashboardのToday欄へ表示するカテゴリー。nilならすべて表示する。"
  :type '(choice (const :tag "All categories" nil) string)
  :group 'my/dashboard)

(defconst my/dashboard--max-width 72
  "ダッシュボード本文の最大幅。")

(defconst my/dashboard--two-column-min-width 68
  "2カラム表示に必要なウィンドウ幅。")

(defvar-local my/dashboard--last-window-width nil
  "最後にダッシュボードを描画したウィンドウ幅。")

(defvar my/dashboard--resize-timer nil
  "連続したリサイズをまとめて処理するためのtimer。")

(defvar my/dashboard--clock-timer nil
  "Dashboardの時計を更新するtimer。")

(defvar my/dashboard--cache (make-hash-table :test #'eq)
  "Dashboardの重いデータ取得結果を保持するcache。")

(defvar my/dashboard--collecting-org-data nil
  "Orgデータ収集中の再入を防ぐための内部フラグ。")

(defun my/dashboard--cached (key seconds producer)
  "KEYの値をSECONDS秒だけ保持し、必要ならPRODUCERで再取得する。"
  (let ((cached (gethash key my/dashboard--cache)))
    (if (and cached
             (< (- (float-time) (car cached)) seconds))
        (cdr cached)
      (let ((value (funcall producer)))
        (puthash key (cons (float-time) value) my/dashboard--cache)
        value))))

(defun my/dashboard-clear-cache (&optional key)
  "KEYのcacheを消す。KEYがnilならすべて消す。"
  (if key
      (remhash key my/dashboard--cache)
    (clrhash my/dashboard--cache)))

(defun my/dashboard--window-width ()
  "ダッシュボードを表示しているウィンドウの本文幅を返す。"
  (if-let ((window (get-buffer-window (current-buffer) t)))
      (window-body-width window)
    (window-body-width)))

(defun my/dashboard--content-width (window-width)
  "WINDOW-WIDTHに収まる本文幅を返す。"
  (min my/dashboard--max-width
       (max 24 (- window-width 6))))

(defun my/dashboard--run (action)
  "ACTIONを対話コマンドまたは通常の関数として実行する。"
  (when action
    (if (commandp action)
        (call-interactively action)
      (funcall action))))

;; RET、TAB、マウスのいずれでもDoom標準のbutton操作として扱われる。
(define-button-type 'my/dashboard-button
  'follow-link t
  'face 'my/dashboard-item
  'mouse-face 'highlight
  'action (lambda (button)
            (my/dashboard--run
             (button-get button 'dashboard-action))))

(defun my/dashboard--make-item (label action)
  "表示名LABELと実行内容ACTIONから項目を作る。"
  (cons label action))

(defun my/dashboard--empty-item (label action)
  "空のセクション用にLABELとACTIONを持つ項目を作る。"
  (cons (propertize label 'face 'my/dashboard-muted) action))

(defun my/dashboard--org-todo-keyword-info ()
  "Org設定から(all-keywords . done-keywords)を作る。"
  (let (all done)
    (dolist (sequence org-todo-keywords)
      (let ((after-separator nil))
        (dolist (item (cdr sequence))
          (cond
           ((equal item "|")
            (setq after-separator t))
           ((stringp item)
            ;; `TODO(t)'のような高速選択keyを除いた状態名だけを使う。
            (let ((keyword (replace-regexp-in-string "(.*\\'" "" item)))
              (push keyword all)
              (when after-separator
                (push keyword done))))))))
    (cons (delete-dups all) (delete-dups done))))

(defun my/dashboard--scan-agenda-entries ()
  "Agenda fileからDashboardに必要な見出し情報だけを軽量に読む。
Orgの構文cacheを作らず、Herdrによる外部更新やOrg hookとも競合しない。"
  (require 'org)
  (let* ((keyword-info (my/dashboard--org-todo-keyword-info))
         (todo-keywords (car keyword-info))
         (done-keywords (cdr keyword-info))
        entries)
    (dolist (file (org-agenda-files t))
      (when (and (stringp file) (file-readable-p file))
        (with-temp-buffer
          (insert-file-contents file)
          (goto-char (point-min))
          (while (re-search-forward "^\\*+[ \t]+\\(.+\\)$" nil t)
            (let* ((position (line-beginning-position))
                   (raw-heading (string-trim (match-string-no-properties 1)))
                   (first-word (car (split-string raw-heading)))
                   (todo-state (and (member first-word todo-keywords) first-word))
                   (title (if todo-state
                              (string-trim
                               (string-remove-prefix todo-state raw-heading))
                            raw-heading))
                   (entry-end
                    (save-excursion
                      (if (re-search-forward "^\\*+[ \t]+" nil t)
                          (match-beginning 0)
                        (point-max))))
                   category deadline scheduled)
              ;; 優先度cookieと末尾tagを、Dashboard表示名から取り除く。
              (setq title
                    (replace-regexp-in-string
                     "\\`\\[#[[:alnum:]]\\][ \t]*" "" title))
              (setq title
                    (string-trim
                     (replace-regexp-in-string
                      "[ \t]+:[[:alnum:]_@#%:]+:[ \t]*\\'" "" title)))
              (save-excursion
                (when (re-search-forward
                       "^[ \t]*:CATEGORY:[ \t]*\\(.+?\\)[ \t]*$"
                       entry-end t)
                  (setq category (string-trim (match-string-no-properties 1))))
                (goto-char position)
                (forward-line 1)
                ;; Orgのplanning行では、両方の日時が同じ行に並ぶ。
                ;; 本文中のDEADLINE等はplanning情報として扱わない。
                (when (and (< (point) entry-end)
                           (looking-at-p org-planning-line-re))
                  (let ((planning-end (line-end-position)))
                    (while (re-search-forward
                            "\\_<\\(DEADLINE\\|SCHEDULED\\):[ \t]*[<[]\\([0-9-]+\\)"
                            planning-end t)
                      (if (equal (match-string-no-properties 1) "DEADLINE")
                          (setq deadline (match-string-no-properties 2))
                        (setq scheduled (match-string-no-properties 2)))))))
              (push (list :file file
                          :position position
                          :title title
                          :todo-state todo-state
                          :done (and todo-state (member todo-state done-keywords))
                          :category category
                          :deadline deadline
                          :scheduled scheduled)
                    entries))))))
    (nreverse entries)))

(defun my/dashboard--collect-org-categories ()
  "Agenda fileに存在するOrgカテゴリーを収集する。"
  (let ((my/dashboard--collecting-org-data t)
        categories)
    (dolist (entry (my/dashboard--scan-agenda-entries))
      ;; 見出しだけの親カテゴリーではなく、実際のTodoが使う値を候補にする。
      (when (plist-get entry :todo-state)
        (when-let ((category (plist-get entry :category)))
          (unless (string-empty-p category)
            (push category categories)))))
    (sort (delete-dups
           (append (copy-sequence my/dashboard-default-categories)
                   categories))
          #'string-lessp)))

(defun my/dashboard--org-categories ()
  "cache済みのOrgカテゴリー一覧を返す。"
  (my/dashboard--cached
   'org-categories my/dashboard-cache-seconds
   #'my/dashboard--collect-org-categories))

(defun my/dashboard--read-category (&optional prompt default)
  "PROMPTでOrgカテゴリーを読み、空入力ならnilを返す。"
  (let* ((fallback (or default my/dashboard-default-category))
         (category
          (completing-read
           (or prompt "Category (new allowed): ")
           (my/dashboard--org-categories)
           nil nil nil nil fallback)))
    (unless (string-empty-p (string-trim category))
      (string-trim category))))

(defun my/dashboard--set-org-category-at-point ()
  "現在のOrg見出しへカテゴリーを設定または新規作成する。"
  (unless (derived-mode-p 'org-mode)
    (user-error "Org見出しではありません"))
  (org-back-to-heading t)
  (let* ((position (point-marker))
         (current (org-entry-get nil "CATEGORY"))
         (clear-label "[Clear category]")
         (categories
          (delete-dups
           (delq nil
                 (cons current (copy-sequence
                                (my/dashboard--org-categories))))))
         (choice
          (completing-read
           (format "Category%s (new allowed): "
                   (if current (format " [%s]" current) ""))
           (cons clear-label categories)
           nil nil nil nil current)))
    (goto-char position)
    (if (or (string-empty-p (string-trim choice))
            (equal choice clear-label))
        (progn
          (org-delete-property "CATEGORY")
          (message "Category cleared"))
      ;; Herdr TODOも解釈するOrg標準Propertyへ保存する。
      (org-set-property "CATEGORY" (string-trim choice))
      (message "Category: %s" (string-trim choice)))
    ;; Property drawerの挿入・削除後も元の見出し位置へ戻す。
    (goto-char position)
    (my/dashboard-clear-cache 'org-categories)
    (my/dashboard-clear-cache 'org-todos)))

(defun my/dashboard-set-org-category ()
  "Org本文・Capture・Agendaから現在のTodoカテゴリーを編集する。"
  (interactive)
  (if (derived-mode-p 'org-agenda-mode)
      (let ((marker (or (org-get-at-bol 'org-hd-marker)
                        (org-get-at-bol 'org-marker))))
        (unless (and (markerp marker) (marker-buffer marker))
          (user-error "このAgenda行にはOrg見出しがありません"))
        (with-current-buffer (marker-buffer marker)
          (goto-char marker)
          (my/dashboard--set-org-category-at-point)
          (save-buffer))
        (org-agenda-redo))
    (my/dashboard--set-org-category-at-point)
    ;; 通常のOrg本文では保存まで行い、Herdrの外部監視へすぐ反映する。
    ;; CaptureはC-c C-cで確定した時点にOrg標準処理が保存する。
    (when (and buffer-file-name
               (not (bound-and-true-p org-capture-mode)))
      (save-buffer)))
  (my/dashboard--reload-visible))

(defun my/dashboard-capture-task ()
  "カテゴリーを選んでTodo用の通常Capture画面を開く。"
  (interactive)
  (let ((category
         (my/dashboard--read-category
          "Task category (new allowed): "
          (or my/dashboard-category-filter
              my/dashboard-default-category))))
    (org-capture nil "t")
    ;; Herdr TODOと共通のOrg標準CATEGORY Propertyとして保存する。
    (when (and category (bound-and-true-p org-capture-mode))
      (let ((title-position (point-marker)))
        (org-set-property "CATEGORY" category)
        (goto-char title-position)
        (when (markerp my/dashboard--capture-point-marker)
          (set-marker my/dashboard--capture-point-marker (point)))))))

(defvar-local my/dashboard--capture-point-marker nil
  "Capture内で最後にコマンドが正常終了した位置。")

(defvar-local my/dashboard--capture-point-before-command nil
  "Capture内で現在のコマンドを開始する直前の位置。")

(defvar-local my/dashboard--capture-point-generation 0
  "古いpoint復元timerを無効化するための世代番号。")

(defun my/dashboard--restore-capture-point (buffer generation)
  "BUFFERのpointを、GENERATIONが最新の場合だけmarker位置へ戻す。"
  (when (buffer-live-p buffer)
    (with-current-buffer buffer
      (when (and (bound-and-true-p org-capture-mode)
                 (= generation my/dashboard--capture-point-generation)
                 (markerp my/dashboard--capture-point-marker)
                 (marker-position my/dashboard--capture-point-marker))
        (let ((position (marker-position my/dashboard--capture-point-marker)))
          (unless (= (point) position)
            (goto-char position))
          (when-let ((window (get-buffer-window buffer t)))
            (unless (= (window-point window) position)
              (set-window-point window position))))))))

(defun my/dashboard--capture-pre-command ()
  "Captureで外部処理に動かされたpointをコマンド実行前に戻す。"
  (when (and (markerp my/dashboard--capture-point-marker)
             (marker-position my/dashboard--capture-point-marker))
    (let ((position (marker-position my/dashboard--capture-point-marker)))
      (unless (= (point) position)
        (goto-char position))))
  (setq my/dashboard--capture-point-before-command (point)))

(defun my/dashboard--capture-post-command ()
  "CaptureでVim操作後の正しいpointを保存し、外部移動を監視する。"
  ;; ESCは同じ行の1文字左へ移るのがVim本来の挙動。別行へ飛んだ場合だけ補正する。
  (when (and (eq this-command #'evil-normal-state)
             (integer-or-marker-p my/dashboard--capture-point-before-command)
             (/= (line-number-at-pos)
                 (line-number-at-pos my/dashboard--capture-point-before-command)))
    (goto-char my/dashboard--capture-point-before-command)
    (unless (bolp)
      (backward-char)))
  (unless (markerp my/dashboard--capture-point-marker)
    (setq my/dashboard--capture-point-marker (point-marker)))
  (set-marker my/dashboard--capture-point-marker (point) (current-buffer))
  (cl-incf my/dashboard--capture-point-generation)
  ;; 常時監視は行わず、コマンドループを抜けた直後に一度だけ確認する。
  (run-at-time 0 nil
               #'my/dashboard--restore-capture-point
               (current-buffer)
               my/dashboard--capture-point-generation))

(defun my/dashboard--setup-org-capture-point ()
  "Org CaptureへVim操作を維持したpoint監視を設定する。"
  ;; このOrg版ではCaptureのindirect bufferでindent用cache初期化が
  ;; 終わらなくなるため、短い入力bufferに限って構文cacheとindentを使わない。
  (setq-local org-element-use-cache nil)
  (when (bound-and-true-p org-indent-mode)
    (org-indent-mode -1))
  (setq my/dashboard--capture-point-marker (point-marker)
        my/dashboard--capture-point-before-command (point)
        my/dashboard--capture-point-generation 0)
  (add-hook 'pre-command-hook #'my/dashboard--capture-pre-command nil t)
  (add-hook 'post-command-hook #'my/dashboard--capture-post-command t t))

;; Orgと詳細Captureでは、短いキーで予定日／期限を設定できるようにする。
(with-eval-after-load 'org
  (define-key org-mode-map (kbd "C-s") #'org-schedule)
  (define-key org-mode-map (kbd "C-d") #'org-deadline)
  (define-key org-mode-map (kbd "C-c c") #'my/dashboard-set-org-category))

(with-eval-after-load 'org-agenda
  ;; AgendaでもHerdrと共通のCATEGORYを左側へ表示する。
  (setf (alist-get 'agenda org-agenda-prefix-format)
        " %i %-12:c%?-12t% s")
  (setf (alist-get 'todo org-agenda-prefix-format)
        " %i %-12:c ")
  (define-key org-agenda-mode-map (kbd "C-c c")
              #'my/dashboard-set-org-category))

(with-eval-after-load 'org-capture
  (define-key org-capture-mode-map (kbd "C-s") #'org-schedule)
  (define-key org-capture-mode-map (kbd "C-d") #'org-deadline)
  (define-key org-capture-mode-map (kbd "C-c c")
              #'my/dashboard-set-org-category)
  ;; 以前の試行を再読み込みしたEmacsからも確実に取り除く。
  (remove-hook 'org-capture-mode-hook #'my/dashboard--prepare-org-capture)
  (remove-hook 'org-capture-mode-hook #'my/dashboard--setup-org-capture)
  ;; DoomがInsert stateへ切り替えた後のpointを初期位置として記録する。
  (remove-hook 'org-capture-mode-hook #'my/dashboard--setup-org-capture-point)
  (add-hook 'org-capture-mode-hook #'my/dashboard--setup-org-capture-point t))

(defun my/dashboard-open-agenda ()
  "Org agendaを開く。"
  (interactive)
  (org-agenda nil "a"))

(defun my/dashboard-refresh ()
  "Dashboardの内容を再取得して描画し直す。"
  (interactive)
  (my/dashboard-clear-cache)
  (+dashboard-reload 'force))

(defun my/dashboard-open ()
  "現在のframeでDashboardを開く。"
  (interactive)
  (+dashboard/open (selected-frame)))

(defun my/dashboard-open-terminal ()
  "Doomのterminalを開く。"
  (interactive)
  (cond ((fboundp '+vterm/toggle) (+vterm/toggle))
        ((fboundp 'vterm) (vterm))
        (t (ansi-term (getenv "SHELL")))))

(defun my/dashboard-open-magit ()
  "現在選択したプロジェクトのMagitを開く。"
  (interactive)
  (call-interactively #'magit-status))

(defun my/dashboard-open-config ()
  "Doomのconfig.elを開く。"
  (interactive)
  (find-file (expand-file-name "config.el" doom-user-dir)))

(defun my/dashboard--open-todo (file position)
  "OrgのFILEを開き、POSITIONのTODO見出し末尾で編集を開始する。"
  (find-file file)
  (widen)
  (goto-char (min position (point-max)))
  (org-back-to-heading t)
  (org-show-context 'agenda)
  (org-reveal)
  (end-of-line)
  (when (fboundp 'evil-insert-state)
    (evil-insert-state)))

(defun my/dashboard--org-date (timestamp)
  "OrgのTIMESTAMPからYYYY-MM-DDを取り出す。"
  (when (and timestamp
             (string-match "[0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\}"
                           timestamp))
    (match-string 0 timestamp)))

(defun my/dashboard--collect-org-todos ()
  "今日までの未完了Org TODOを収集し、優先順に並べる。"
  (require 'org)
  (let ((my/dashboard--collecting-org-data t)
        (today (format-time-string "%Y-%m-%d"))
        records)
    (dolist (entry (my/dashboard--scan-agenda-entries))
       (let* ((todo-state (plist-get entry :todo-state))
              (deadline (plist-get entry :deadline))
              (scheduled (plist-get entry :scheduled))
              (dates (delq nil (list deadline scheduled)))
              (date (car (sort dates #'string<))))
         ;; Org matcherへ日時比較を任せず、未完了かつ今日以前を明示判定する。
         (when (and todo-state
                    (not (plist-get entry :done))
                    date
                    (not (string< today date)))
           (push (list :file (plist-get entry :file)
                       :position (plist-get entry :position)
                       :title (plist-get entry :title)
                       :category (plist-get entry :category)
                       :date date
                       :overdue (string< date today))
                 records))))
    ;; 期限超過を先頭にし、同じ状態なら日付が早いものを優先する。
    (sort records
          (lambda (left right)
            (let ((left-overdue (plist-get left :overdue))
                  (right-overdue (plist-get right :overdue))
                  (left-date (or (plist-get left :date) today))
                  (right-date (or (plist-get right :date) today)))
              (if (eq left-overdue right-overdue)
                  (string< left-date right-date)
                left-overdue))))))

(defun my/dashboard--org-todos ()
  "今日のOrg TODOをDashboard項目として返す。"
  (condition-case error-data
      (let* ((records
              (my/dashboard--cached
               'org-todos my/dashboard-cache-seconds
               #'my/dashboard--collect-org-todos))
             (records
              (if my/dashboard-category-filter
                  (seq-filter
                   (lambda (record)
                     (equal (plist-get record :category)
                            my/dashboard-category-filter))
                   records)
                records))
             (todo-limit (max 0 (1- my/dashboard-item-count)))
             (items
              (mapcar
               (lambda (record)
                 (let ((file (plist-get record :file))
                       (position (plist-get record :position))
                       (title (plist-get record :title))
                       (category (plist-get record :category))
                       (overdue (plist-get record :overdue)))
                   (my/dashboard--make-item
                    (concat
                     (when category
                       (propertize (format "[%s] " category)
                                   'face 'my/dashboard-category))
                     (if overdue
                         (concat (propertize "OVERDUE " 'face 'error) title)
                       title))
                    (lambda () (my/dashboard--open-todo file position)))))
               (seq-take records todo-limit))))
        (cons (my/dashboard--make-item
               "Add task" #'my/dashboard-capture-task)
              (or items
                  (list (my/dashboard--empty-item
                         "No tasks for today" #'my/dashboard-open-agenda)))))
    (error
     (list
      (my/dashboard--make-item "Add task" #'my/dashboard-capture-task)
      (my/dashboard--empty-item
       (format "Org error: %s"
               (truncate-string-to-width
                (error-message-string error-data) 28 nil nil "..."))
       #'my/dashboard-refresh)))))

(defun my/dashboard-set-category-filter ()
  "DashboardのToday欄をOrgカテゴリーで絞り込む。"
  (interactive)
  (let* ((all-label "All categories")
         (choice
          (completing-read
           "Dashboard category: "
           (cons all-label (my/dashboard--org-categories))
           nil t nil nil
           (or my/dashboard-category-filter all-label))))
    (setq my/dashboard-category-filter
          (unless (equal choice all-label) choice))
    (+dashboard-reload 'force)
    (message "Dashboard category: %s"
             (or my/dashboard-category-filter "All"))))

(defun my/dashboard--file-label (path)
  "PATHをファイル名と親directoryからなる短い表示名にする。"
  (let* ((file (file-name-nondirectory path))
         (parent (file-name-nondirectory
                  (directory-file-name (file-name-directory path)))))
    (if (string-empty-p parent)
        file
      (format "%s  <%s>" file parent))))

(defun my/dashboard--collect-recent-files ()
  "存在するrecentf項目をDashboard項目として収集する。"
  (let (items)
    (dolist (file (seq-take
                   (seq-filter #'file-exists-p
                               (bound-and-true-p recentf-list))
                   my/dashboard-item-count))
      (let ((path file))
        (push (my/dashboard--make-item
               (my/dashboard--file-label path)
               (lambda () (find-file path)))
              items)))
    (or (nreverse items)
        (list (my/dashboard--empty-item
               "No recent files" #'recentf-open-files)))))

(defun my/dashboard--recent-files ()
  "cache済みのRecent filesを返す。"
  (condition-case error-data
      (my/dashboard--cached
       'recent-files my/dashboard-cache-seconds
       #'my/dashboard--collect-recent-files)
    (error
     (list (my/dashboard--empty-item
            (format "Recent error: %s"
                    (truncate-string-to-width
                     (error-message-string error-data) 25 nil nil "..."))
            #'my/dashboard-refresh)))))

(defun my/dashboard--known-projects ()
  "Projectileの既知プロジェクトを正規化して返す。"
  (when (require 'projectile nil t)
    (delete-dups
     (mapcar #'file-name-as-directory
             (seq-filter #'file-directory-p
                         (append my/dashboard-pinned-projects
                                 projectile-known-projects))))))

(defun my/dashboard-toggle-project ()
  "Dashboardに固定表示するプロジェクトを対話的に切り替える。"
  (interactive)
  (let* ((projects (my/dashboard--known-projects))
         (clear-label "[Clear all pinned projects]")
         (choices
          (cons
           (cons clear-label :clear)
           (mapcar
            (lambda (path)
              (cons (format "%s %s"
                            (if (member path my/dashboard-pinned-projects)
                                "[x]" "[ ]")
                            (abbreviate-file-name path))
                    path))
            projects)))
         (choice (completing-read "Toggle dashboard project: "
                                  choices nil t))
         (project (cdr (assoc choice choices))))
    (cond
     ((eq project :clear)
      (customize-save-variable 'my/dashboard-pinned-projects nil)
      (message "Dashboard project pins cleared"))
     ((member project my/dashboard-pinned-projects)
      (customize-save-variable
       'my/dashboard-pinned-projects
       (delete project (copy-sequence my/dashboard-pinned-projects)))
      (message "Unpinned %s" (abbreviate-file-name project)))
     (project
      (customize-save-variable
       'my/dashboard-pinned-projects
       (append my/dashboard-pinned-projects (list project)))
     (message "Pinned %s" (abbreviate-file-name project))))
    (my/dashboard-clear-cache 'projects)
    (+dashboard-reload 'force)))

(defun my/dashboard--project-label (path pinned)
  "PATHのプロジェクト名を作る。PINNEDなら固定表示を示す。"
  (let* ((directory (directory-file-name path))
         (name (file-name-nondirectory directory))
         (parent (file-name-nondirectory
                  (directory-file-name (file-name-directory directory)))))
    (format "%s%s%s"
            (if pinned "PIN " "")
            name
            (if (string-empty-p parent) "" (format "  <%s>" parent)))))

(defun my/dashboard--collect-projects ()
  "固定済みと最近のProjectile projectをDashboard項目にする。"
  (let* ((pinned (seq-filter #'file-directory-p
                             my/dashboard-pinned-projects))
         (known (my/dashboard--known-projects))
         (directories
          (cond ((null pinned) known)
                (my/dashboard-fill-projects-after-pins known)
                (t pinned)))
         items)
    (dolist (directory (seq-take directories my/dashboard-item-count))
      (let ((path directory))
        (push
         (my/dashboard--make-item
          (my/dashboard--project-label
           path (member path my/dashboard-pinned-projects))
          (lambda ()
            (if (fboundp 'projectile-switch-project-by-name)
                (projectile-switch-project-by-name path)
              (dired path))))
         items)))
    (or (nreverse items)
        (list (my/dashboard--empty-item
               "Find a project" #'projectile-switch-project)))))

(defun my/dashboard--projects ()
  "cache済みのProjectile projectを返す。"
  (condition-case error-data
      (my/dashboard--cached
       'projects my/dashboard-cache-seconds
       #'my/dashboard--collect-projects)
    (error
     (list (my/dashboard--empty-item
            (format "Project error: %s"
                    (truncate-string-to-width
                     (error-message-string error-data) 24 nil nil "..."))
            #'my/dashboard-toggle-project)))))

(defun my/dashboard--collect-elfeed-unread ()
  "Elfeedの未読記事を新しい順に収集する。"
  (require 'elfeed-db)
  (require 'elfeed-search)
  (elfeed-db-load)
  (let* ((sorter (lambda (left right)
                   (> (elfeed-entry-date left)
                      (elfeed-entry-date right))))
         (entries (seq-take
                   (elfeed-search-entries "+unread" sorter)
                   my/dashboard-item-count))
         items)
    (dolist (entry entries)
      (let* ((article entry)
             (title (or (elfeed-entry-title article) "Untitled article"))
             (feed (elfeed-entry-feed article))
             (source (and feed (elfeed-feed-title feed))))
        (push
         (my/dashboard--make-item
          (if (and source (not (string-empty-p source)))
              (format "%s  <%s>" title source)
            title)
          (lambda ()
            (require 'elfeed-show)
            (elfeed-show-entry article)))
         items)))
    (or (nreverse items)
        (list (my/dashboard--empty-item
               "No unread articles" #'elfeed)))))

(defun my/dashboard--elfeed-unread ()
  "cache済みのElfeed未読記事を返す。"
  (condition-case error-data
      (my/dashboard--cached
       'elfeed my/dashboard-elfeed-cache-seconds
       #'my/dashboard--collect-elfeed-unread)
    (error
     (list (my/dashboard--empty-item
            (format "Elfeed error: %s"
                    (truncate-string-to-width
                     (error-message-string error-data) 25 nil nil "..."))
            #'elfeed)))))

(defun my/dashboard--insert-item (item column width)
  "ITEMをCOLUMNからWIDTH以内に収めて挿入する。"
  (move-to-column column t)
  ;; ASCII記号だけを使い、Nerd Fontsがなくても表示を崩さない。
  (insert (propertize "> " 'face 'my/dashboard-muted))
  (let ((label (truncate-string-to-width
                (car item) (max 1 (- width 2)) nil nil "...")))
    (insert-text-button label
                        'type 'my/dashboard-button
                        'dashboard-action (cdr item)
                        'help-echo "RET / click to open")))

(defun my/dashboard--insert-heading (title column width)
  "TITLEをCOLUMNからWIDTH幅の見出しとして挿入する。"
  (move-to-column column t)
  (insert (propertize (upcase title) 'face 'my/dashboard-heading))
  (insert " ")
  ;; 罫線もASCIIにしてterminalでの文字幅差を避ける。
  (insert (propertize
           (make-string
            (max 2 (- width (string-width title) 1)) ?-)
           'face 'my/dashboard-muted)))

(defun my/dashboard--section-string (section width &optional limit)
  "SECTIONをWIDTH幅の文字列にする。LIMITは表示件数。"
  (with-temp-buffer
    (my/dashboard--insert-heading (car section) 0 width)
    (insert "\n")
    (dolist (item (seq-take (cdr section)
                            (or limit my/dashboard-item-count)))
      (my/dashboard--insert-item item 0 width)
      (insert "\n"))
    (buffer-string)))

(defun my/dashboard--section-pair-string (left right total-width)
  "LEFTとRIGHTをTOTAL-WIDTH内の2カラム文字列にする。"
  (let* ((gap 4)
         (column-width (/ (- total-width gap) 2))
         (right-column (+ column-width gap))
         (rows (max (length (cdr left)) (length (cdr right)))))
    (with-temp-buffer
      (my/dashboard--insert-heading (car left) 0 column-width)
      (my/dashboard--insert-heading (car right) right-column column-width)
      (insert "\n")
      (dotimes (index (min rows my/dashboard-item-count))
        (when-let ((item (nth index (cdr left))))
          (my/dashboard--insert-item item 0 column-width))
        (when-let ((item (nth index (cdr right))))
          (my/dashboard--insert-item item right-column column-width))
        (insert "\n"))
      (buffer-string))))

(defconst my/dashboard--quick-actions
  `(("Agenda" . ,#'my/dashboard-open-agenda)
    ("Category" . ,#'my/dashboard-set-category-filter)
    ("Projects" . ,#'my/dashboard-toggle-project)
    ("Terminal" . ,#'my/dashboard-open-terminal)
    ("Magit" . ,#'my/dashboard-open-magit)
    ("Config" . ,#'my/dashboard-open-config)
    ("Refresh" . ,#'my/dashboard-refresh))
  "Dashboard下部に並べるクイック操作。")

(defun my/dashboard--shortcut-string (actions)
  "ACTIONSをクリック可能なクイック操作の文字列にする。"
  (with-temp-buffer
    (dolist (item actions)
      (unless (bobp)
        (insert "   "))
      (insert-text-button (car item)
                          'type 'my/dashboard-button
                          'dashboard-action (cdr item)
                          'help-echo "RET / click to run"))
    (buffer-string)))

(defun my/dashboard-widget-date ()
  "中央に日付と時刻を表示する。"
  (+dashboard-insert "")
  ;; 別々に挿入すると、文字列の長さが違っても各行が正確に中央へ来る。
  (+dashboard-insert
   (propertize (format-time-string "%A, %B %e, %Y")
               'face 'my/dashboard-date))
  (+dashboard-insert
   (propertize (format-time-string "%H:%M")
               'face 'my/dashboard-time))
  (+dashboard-insert ""))

(defun my/dashboard-widget-content ()
  "ウィンドウ幅に応じて本文を2カラムまたは1カラムで表示する。"
  (let* ((window-width (my/dashboard--window-width))
         (content-width (my/dashboard--content-width window-width))
         (today-title
          (if my/dashboard-category-filter
              (format "Today: %s" my/dashboard-category-filter)
            "Today"))
         (today (cons today-title (my/dashboard--org-todos)))
         (recent (cons "Recent files" (my/dashboard--recent-files)))
         (projects (cons "Projects" (my/dashboard--projects)))
         (unread (cons "Elfeed unread" (my/dashboard--elfeed-unread))))
    (setq-local my/dashboard--last-window-width window-width)
    (if (>= window-width my/dashboard--two-column-min-width)
        (progn
          ;; 左: Today / Recent、右: Projects / Elfeed unread。
          (+dashboard-insert
           (my/dashboard--section-pair-string
            today projects content-width))
          (+dashboard-insert
           (my/dashboard--section-pair-string
            recent unread content-width)))
      ;; 狭いterminalでは縦積みにして、横切れを防止する。
      (dolist (section (list today projects recent unread))
        (+dashboard-insert
         (my/dashboard--section-string
          section content-width (min 2 my/dashboard-item-count)))))))

(defun my/dashboard-widget-shortcuts ()
  "Dashboardのクイック操作を中央に表示する。"
  (+dashboard-insert "")
  (if (>= (my/dashboard--window-width) 96)
      (+dashboard-insert
       (my/dashboard--shortcut-string my/dashboard--quick-actions))
    ;; 狭いterminalでは2行に分けて操作名を省略しない。
    (+dashboard-insert
     (my/dashboard--shortcut-string
      (seq-take my/dashboard--quick-actions 4)))
    (+dashboard-insert
     (my/dashboard--shortcut-string
      (seq-drop my/dashboard--quick-actions 4))))
  (+dashboard-insert "")
  (+dashboard-insert
   (propertize "SPC o d / :Dashboard    K/J to move    RET to open"
               'face 'my/dashboard-muted)))

(defun my/dashboard--org-capture-active-p ()
  "Org Captureがどこかのbufferで動作中ならnon-nilを返す。"
  ;; `with-current-buffer'で全bufferを巡るとbuffer-list-update-hookが再発火し、
  ;; Dashboard再描画と相互再帰するため、bufferを切り替えず値だけを読む。
  (seq-some
   (lambda (buffer)
     (and (buffer-live-p buffer)
          (boundp 'org-capture-mode)
          (buffer-local-value 'org-capture-mode buffer)))
   (buffer-list)))

(defun my/dashboard--reload-after-resize (&rest _)
  "表示幅が変わったときだけダッシュボードを再描画する。"
  (when (timerp my/dashboard--resize-timer)
    (cancel-timer my/dashboard--resize-timer))
  ;; ドラッグ中の連続再描画を避け、操作が落ち着いてから一度だけ更新する。
  (setq my/dashboard--resize-timer
        (run-with-idle-timer
         0.15 nil
         (lambda ()
           ;; Capture入力中は背後のDashboardを触らない。
           (unless (or my/dashboard--collecting-org-data
                       (my/dashboard--org-capture-active-p))
             (when-let* ((buffer (get-buffer +dashboard-name))
                         (window (get-buffer-window buffer t)))
               (let ((width (window-body-width window)))
                 (let ((buffer-list-update-hook nil))
                   (with-current-buffer buffer
                     (unless (equal width my/dashboard--last-window-width)
                       (+dashboard-reload 'force)))))))))))

(defun my/dashboard--reload-visible ()
  "Dashboardが表示中のときだけ再描画する。"
  ;; Capture中に時計timerが割り込んで、入力bufferへ影響するのを避ける。
  (unless (or my/dashboard--collecting-org-data
              (my/dashboard--org-capture-active-p))
    (when-let* ((buffer (get-buffer +dashboard-name))
                (window (get-buffer-window buffer t)))
      ;; buffer切替hookから再びこの関数へ戻らないようにする。
      (let ((buffer-list-update-hook nil))
        (with-current-buffer buffer
          (+dashboard-reload 'force))))))

(defun my/dashboard--invalidate-org-cache ()
  "Org変更後にTODO cacheを無効化して表示を更新する。"
  (my/dashboard-clear-cache 'org-todos)
  (my/dashboard-clear-cache 'org-categories)
  (my/dashboard--reload-visible))

(defun my/dashboard--invalidate-after-org-save ()
  "Agenda対象のOrg fileを保存したらTODO cacheを無効化する。"
  (when (and buffer-file-name
             (boundp 'org-agenda-files)
             (member (file-truename buffer-file-name)
                     (mapcar #'file-truename (org-agenda-files t))))
    (my/dashboard--invalidate-org-cache)))

(defun my/dashboard--setup-org-save-hook ()
  "Org bufferへDashboard cache更新hookを追加する。"
  (add-hook 'after-save-hook
            #'my/dashboard--invalidate-after-org-save nil t))

;; 幅が本当に変わった時だけ再描画し、GUI/terminalのサイズへ追従する。
(add-hook 'window-size-change-functions
          #'my/dashboard--reload-after-resize)
(add-hook 'org-mode-hook #'my/dashboard--setup-org-save-hook)
(add-hook 'org-capture-after-finalize-hook
          #'my/dashboard--invalidate-org-cache)

;; 時計だけは毎分更新し、各セクションの重い取得結果はcacheを再利用する。
(when (timerp my/dashboard--clock-timer)
  (cancel-timer my/dashboard--clock-timer))
(setq my/dashboard--clock-timer
      (run-at-time 60 60 #'my/dashboard--reload-visible))

;; どのbufferからでもSPC o dでDashboardへ戻れるようにする。
(map! :leader
      :desc "Open dashboard"
      "o d" #'my/dashboard-open)

;; VimのExコマンドからも :Dashboard で開けるようにする。
(when (fboundp 'evil-ex-define-cmd)
  (evil-ex-define-cmd "Dashboard" #'my/dashboard-open))

;; Doom標準のbanner/footer/起動時間は維持し、中央の本文だけ差し替える。
;; 横方向の中央揃えはDoom標準の +dashboard-insert に任せる。
(setq +dashboard-anchor '(top . center)
      +dashboard-functions
      '(+dashboard-widget-banner
        my/dashboard-widget-date
        my/dashboard-widget-content
        my/dashboard-widget-shortcuts
        +dashboard-widget-footer
        +dashboard-widget-loaded))

;;; dashboard.el ends here
