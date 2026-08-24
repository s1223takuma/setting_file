;;; dashboard.el -*- lexical-binding: t; -*-

;; Doom標準のダッシュボード部品を活かした、個人用スタート画面。
;; 外部パッケージは追加せず、Doom/Emacs/有効化済みモジュールのAPIだけを使う。

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

(defvar my/dashboard--open-guard-map
  (let ((map (make-sparse-keymap)))
    ;; 画面切替直後に残ったRETや矢印のキーリピートだけを吸収する。
    (dolist (key '("RET" "<return>" "<up>" "<down>" "<left>" "<right>"))
      (define-key map (kbd key) #'ignore))
    map)
  "Dashboardから項目を開いた直後のキーリピートを防ぐmap。")

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

(defun my/dashboard-capture-task ()
  "Todo用テンプレートを直接開く。"
  (interactive)
  ;; Insert状態への遷移はDoomのorg-capture-mode-hookに任せる。
  (org-capture nil "t"))

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

(defun my/dashboard--guard-opening-input ()
  "画面切替直後のキーリピートを短時間だけ無視する。"
  ;; 未定義キーは通常mapへそのまま渡るため、文字入力は妨げない。
  (let ((deadline (+ (float-time) 0.35)))
    (set-transient-map
     my/dashboard--open-guard-map
     (lambda () (< (float-time) deadline))
     nil nil 0.35)))

(defun my/dashboard--open-todo (marker)
  "OrgのMARKERを開き、TODO見出し末尾で編集を開始する。"
  ;; Agendaと同じOrg標準APIでmarkerへ移動し、独自timerやhookは使わない。
  (org-goto-marker-or-bmk marker)
  (widen)
  (org-back-to-heading t)
  (org-show-context 'agenda)
  (org-reveal)
  (end-of-line)
  (when (fboundp 'evil-insert-state)
    (evil-insert-state))
  (my/dashboard--guard-opening-input))

(defun my/dashboard--org-date (timestamp)
  "OrgのTIMESTAMPからYYYY-MM-DDを取り出す。"
  (when (and timestamp
             (string-match "[0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\}"
                           timestamp))
    (match-string 0 timestamp)))

(defun my/dashboard--collect-org-todos ()
  "今日までの未完了Org TODOを収集し、優先順に並べる。"
  (require 'org)
  (let ((today (format-time-string "%Y-%m-%d"))
        records)
    (org-map-entries
     (lambda ()
       (let* ((deadline (my/dashboard--org-date
                         (org-entry-get nil "DEADLINE")))
              (scheduled (my/dashboard--org-date
                          (org-entry-get nil "SCHEDULED")))
              (dates (delq nil (list deadline scheduled)))
              (date (car (sort dates #'string<))))
         (push (list :title (org-get-heading t t t t)
                     :marker (copy-marker (point))
                     :date date
                     :overdue (and date (string< date today)))
               records)))
     (format
      (concat "+TODO<>\"DONE\"+TODO<>\"CANCELLED\""
              "+DEADLINE<=\"<%s>\""
              "|+TODO<>\"DONE\"+TODO<>\"CANCELLED\""
              "+SCHEDULED<=\"<%s>\"")
      today today)
     'agenda)
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
             (todo-limit (max 0 (1- my/dashboard-item-count)))
             (items
              (mapcar
               (lambda (record)
                 (let ((marker (plist-get record :marker))
                       (title (plist-get record :title))
                       (overdue (plist-get record :overdue)))
                   (my/dashboard--make-item
                    (if overdue
                        (concat (propertize "OVERDUE " 'face 'error) title)
                      title)
                    (lambda () (my/dashboard--open-todo marker)))))
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
         (today (cons "Today" (my/dashboard--org-todos)))
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
  (if (>= (my/dashboard--window-width) 74)
      (+dashboard-insert
       (my/dashboard--shortcut-string my/dashboard--quick-actions))
    ;; 狭いterminalでは2行に分けて操作名を省略しない。
    (+dashboard-insert
     (my/dashboard--shortcut-string
      (seq-take my/dashboard--quick-actions 3)))
    (+dashboard-insert
     (my/dashboard--shortcut-string
      (seq-drop my/dashboard--quick-actions 3))))
  (+dashboard-insert "")
  (+dashboard-insert
   (propertize "SPC o d / :Dashboard    TAB to move    RET to open"
               'face 'my/dashboard-muted)))

(defun my/dashboard--reload-after-resize (&rest _)
  "表示幅が変わったときだけダッシュボードを再描画する。"
  (when (timerp my/dashboard--resize-timer)
    (cancel-timer my/dashboard--resize-timer))
  ;; ドラッグ中の連続再描画を避け、操作が落ち着いてから一度だけ更新する。
  (setq my/dashboard--resize-timer
        (run-with-idle-timer
         0.15 nil
         (lambda ()
           (when-let* ((buffer (get-buffer +dashboard-name))
                       (window (get-buffer-window buffer t)))
             (let ((width (window-body-width window)))
               (with-current-buffer buffer
                 (unless (equal width my/dashboard--last-window-width)
                   (+dashboard-reload 'force)))))))))

(defun my/dashboard--reload-visible ()
  "Dashboardが表示中のときだけ再描画する。"
  (when-let* ((buffer (get-buffer +dashboard-name))
              (window (get-buffer-window buffer t)))
    (with-current-buffer buffer
      (+dashboard-reload 'force))))

(defun my/dashboard--invalidate-org-cache ()
  "Org変更後にTODO cacheを無効化して表示を更新する。"
  (my/dashboard-clear-cache 'org-todos)
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
