;;; xcode.el -*- lexical-binding: t; -*-

(require 'seq)
(require 'subr-x)

;; ─────────────────────────────────────
;; Project
;; ─────────────────────────────────────

(defun my/xcode--find-project-in-directory (dir)
  "Return an .xcodeproj or .xcworkspace found directly inside DIR."
  (let ((files (directory-files dir t)))
    ;; workspaceを優先
    (or (seq-find
         (lambda (file)
           (string-match-p "\\.xcworkspace\\'" file))
         files)
        (seq-find
         (lambda (file)
           (string-match-p "\\.xcodeproj\\'" file))
         files))))

(defun my/xcode-project ()
  "Find the nearest Xcode project/workspace."
  (let ((dir (file-name-as-directory
              (expand-file-name default-directory)))
        found)

    (while (and dir (not found))
      (setq found (my/xcode--find-project-in-directory dir))

      (unless found
        (let ((parent
               (file-name-directory
                (directory-file-name dir))))
          (setq dir
                (unless (equal parent dir)
                  parent)))))

    found))

(defun my/xcode-project-root ()
  "Return the directory containing the current Xcode project."
  (let ((project (my/xcode-project)))
    (when project
      (file-name-directory project))))

;; ─────────────────────────────────────
;; xcodebuild
;; ─────────────────────────────────────

(defun my/xcode--project-argument (project)
  "Return the xcodebuild argument for PROJECT."
  (cond
   ((string-suffix-p ".xcworkspace" project)
    (format "-workspace %s"
            (shell-quote-argument project)))

   ((string-suffix-p ".xcodeproj" project)
    (format "-project %s"
            (shell-quote-argument project)))

   (t
    (user-error "Unknown Xcode project type: %s" project))))

(defun my/xcode--schemes (project)
  "Return the schemes available in PROJECT."
  (let* ((root (file-name-directory project))
         (default-directory root)
         (project-arg (my/xcode--project-argument project))
         (json
          (shell-command-to-string
           (format
            "xcodebuild %s -list -json 2>/dev/null"
            project-arg))))

    (condition-case nil
        (let* ((data (json-parse-string
                      json
                      :object-type 'alist
                      :array-type 'list))
               ;; -list -json can return project or workspace
               (container
                (or (alist-get 'project data)
                    (alist-get 'workspace data)))
               (schemes
                (alist-get 'schemes container)))

          schemes)

      (error
       (user-error "Failed to read Xcode schemes")))))

(defun my/xcode-select-scheme (project)
  "Select a scheme for PROJECT.

If there is only one scheme, return it automatically."
  (let ((schemes (my/xcode--schemes project)))

    (cond
     ((null schemes)
      (user-error "No Xcode schemes found"))

     ((= (length schemes) 1)
      (car schemes))

     (t
      (completing-read
       "Scheme: "
       schemes
       nil
       t)))))
;;; ─────────────────────────────────────
;;; Simulator
;;; ─────────────────────────────────────

(defun my/xcode--booted-simulator ()
  "Return the UDID of the first booted iOS Simulator, or nil."
  (let* ((json (shell-command-to-string
                "xcrun simctl list devices available -j"))
         (data (json-parse-string
                json
                :object-type 'alist
                :array-type 'list))
         (devices (alist-get 'devices data))
         found)

    (dolist (runtime devices)
      ;; iOS runtimeだけを見る
      (when (string-match-p "iOS" (symbol-name (car runtime)))
        (dolist (device (cdr runtime))
          (when (and (not found)
                     (equal (alist-get 'state device) "Booted"))
            (setq found (alist-get 'udid device))))))

    found))


(defun my/xcode--available-simulators ()
  "Return available iOS Simulators as (DISPLAY . UDID)."
  (let* ((json (shell-command-to-string
                "xcrun simctl list devices available -j"))
         (data (json-parse-string json
                                  :object-type 'alist
                                  :array-type 'list))
         (devices (alist-get 'devices data))
         result)

    (dolist (runtime devices)
      ;; iOS runtimeだけ
      (when (string-match-p "iOS" (symbol-name (car runtime)))
        (dolist (device (cdr runtime))
          (let ((name (alist-get 'name device))
                (udid (alist-get 'udid device))
                (state (alist-get 'state device)))

            (push
             (cons
              (format "%s [%s]" name state)
              udid)
             result)))))

    (nreverse result)))


(defun my/xcode-select-simulator ()
  "Select an available iOS Simulator and return its UDID."
  (let* ((devices (my/xcode--available-simulators)))

    (unless devices
      (user-error "No iOS Simulators found"))

    (let* ((choice
            (completing-read
             "Simulator: "
             (mapcar #'car devices)
             nil
             t))
           (udid (cdr (assoc choice devices))))

      udid)))


(defun my/xcode--ensure-simulator ()
  "Return a booted Simulator UDID.

Use an already booted Simulator when possible.
Otherwise ask the user which Simulator to boot."
  (or
   (my/xcode--booted-simulator)

   (let ((udid (my/xcode-select-simulator)))

     (message "Booting Simulator...")

     (unless
         (= 0
            (call-process
             "xcrun"
             nil
             nil
             nil
             "simctl"
             "boot"
             udid))
       (user-error "Failed to boot Simulator"))

     ;; Simulator.appを表示
     (call-process
      "open"
      nil
      nil
      nil
      "-a"
      "Simulator")

     ;; 起動完了まで待機
     (call-process
      "xcrun"
      nil
      nil
      nil
      "simctl"
      "bootstatus"
      udid
      "-b")

     udid)))


;;; ─────────────────────────────────────
;;; Build settings
;;; ─────────────────────────────────────

(defun my/xcode--build-setting (project scheme key)
  "Return build setting KEY for PROJECT and SCHEME."
  (let* ((root (file-name-directory project))
         (default-directory root)
         (project-arg (my/xcode--project-argument project))
         (command
          (format
           "xcodebuild %s -scheme %s \
-configuration Debug \
-destination 'generic/platform=iOS Simulator' \
-showBuildSettings"
           project-arg
           (shell-quote-argument scheme)))

         (output (shell-command-to-string command)))

    (when
        (string-match
         (format "^[ \t]*%s = \\(.+\\)$"
                 (regexp-quote key))
         output)

      (string-trim
       (match-string 1 output)))))


;;; ─────────────────────────────────────
;;; Build & Run
;;; ─────────────────────────────────────

(defun my/xcode-run ()
  "Build and run the current Xcode project in an iOS Simulator."
  (interactive)

  (let ((project (my/xcode-project)))

    (unless project
      (user-error "No .xcodeproj or .xcworkspace found"))

    (let* ((root (file-name-directory project))
           (default-directory root)

           ;; Scheme
           (scheme
            (my/xcode-select-scheme project))

           ;; Simulator
           (udid
            (my/xcode--ensure-simulator))

           ;; Project argument
           (project-arg
            (my/xcode--project-argument project))

           ;; Build settings
           (product-name
            (my/xcode--build-setting
             project scheme "FULL_PRODUCT_NAME"))

           (build-dir
            (my/xcode--build-setting
             project scheme "TARGET_BUILD_DIR"))

           (bundle-id
            (my/xcode--build-setting
             project scheme "PRODUCT_BUNDLE_IDENTIFIER")))

      (unless product-name
        (user-error "Could not determine FULL_PRODUCT_NAME"))

      (unless build-dir
        (user-error "Could not determine TARGET_BUILD_DIR"))

      (unless bundle-id
        (user-error "Could not determine PRODUCT_BUNDLE_IDENTIFIER"))

      (let* ((app-path
              (expand-file-name
               product-name
               build-dir))

             (buffer
              (get-buffer-create "*Xcode Run*")))

        ;; Build
        (message "Building %s..." scheme)

        (with-current-buffer buffer
          (erase-buffer))

        (let ((exit-code
               (call-process-shell-command
                (format
                 "xcodebuild %s \
-scheme %s \
-configuration Debug \
-destination 'platform=iOS Simulator,id=%s' \
build"
                 project-arg
                 (shell-quote-argument scheme)
                 udid)
                nil
                buffer
                t)))

          (unless (= exit-code 0)
            (pop-to-buffer buffer)
            (compilation-mode)
            (user-error "Xcode build failed")))

        ;; Install
        (message "Installing %s..." product-name)

        (unless
            (= 0
               (call-process
                "xcrun"
                nil
                buffer
                t
                "simctl"
                "install"
                udid
                app-path))

          (pop-to-buffer buffer)
          (user-error "Failed to install app"))

        ;; Launch
        (message "Launching %s..." bundle-id)

        (unless
            (= 0
               (call-process
                "xcrun"
                nil
                buffer
                t
                "simctl"
                "launch"
                udid
                bundle-id))

          (pop-to-buffer buffer)
          (user-error "Failed to launch app"))

        ;; Simulatorを前面へ
        (call-process
         "open"
         nil
         nil
         nil
         "-a"
         "Simulator")

        (message "Xcode: %s launched successfully" scheme)))))

;; ─────────────────────────────────────
;; Commands
;; ─────────────────────────────────────

(defun my/xcode--run (action)
  "Run xcodebuild ACTION for the current project."
  (let ((project (my/xcode-project)))

    (unless project
      (user-error "No .xcodeproj or .xcworkspace found"))

    (let* ((root (file-name-directory project))
           (default-directory root)
           (scheme (my/xcode-select-scheme project))
           (project-arg (my/xcode--project-argument project))
           (command
            (format
             "xcodebuild %s \
-scheme %s \
-configuration Debug \
-destination 'generic/platform=iOS Simulator' \
%s"
             project-arg
             (shell-quote-argument scheme)
             action)))

      (compile command))))

(defun my/xcode-build ()
  "Build the current Xcode project."
  (interactive)
  (my/xcode--run "build"))

(defun my/xcode-clean ()
  "Clean the current Xcode project."
  (interactive)
  (my/xcode--run "clean"))

(defun my/xcode-test ()
  "Run tests for the current Xcode project."
  (interactive)
  (my/xcode--run "test"))

;; ─────────────────────────────────────
;; Doom keymaps
;; ─────────────────────────────────────

(map! :leader
      (:prefix ("m x" . "Xcode")
       :desc "Build" "b" #'my/xcode-build
       :desc "Run"   "r" #'my/xcode-run
       :desc "Clean" "c" #'my/xcode-clean
       :desc "Test"  "t" #'my/xcode-test))

;; ─────────────────────────────────────
;; Evil Ex commands
;; ─────────────────────────────────────

(after! evil
  (evil-ex-define-cmd "Xb" #'my/xcode-build)
  (evil-ex-define-cmd "Xr" #'my/xcode-run)
  (evil-ex-define-cmd "Xc" #'my/xcode-clean)
  (evil-ex-define-cmd "Xt" #'my/xcode-test))

