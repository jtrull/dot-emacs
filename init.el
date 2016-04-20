(defconst emacs-start-time (current-time))

(unless noninteractive
  (message "Loading %s..." load-file-name))

(setq message-log-max 16384)

(setq inhibit-startup-screen t)

;; Customization interface
(setq custom-file (concat user-emacs-directory "custom.el"))
(load custom-file)

;; Set window appearance
(setq default-frame-alist
      '((width . 100)
        (height . 45)
        (tool-bar-lines . 0)
        (menu-bar-lines . 0)
        (background-mode 'dark)
        (vertical-scroll-bars . nil)))
;; Enable menu-bar on Mac OS X since it's going to be there anyway.
(setq window-system-default-frame-alist
      '((ns (menu-bar-lines . 1))
        (mac (menu-bar-lines . 1))))

;; Getting old...
(set-face-attribute 'default nil :height 140)

(add-hook 'tty-setup-hook
          (lambda ()
            (require 'mwheel)
            (xterm-mouse-mode 1)
            (mwheel-install)
            (if (string= (tty-type nil) "screen-256color")
                (terminal-init-xterm))))

(setq mac-option-modifier 'meta
      mac-command-modifier 'super)

;; Configure load paths and bootstrap use-package
(eval-and-compile
  (mapc #'(lambda (path)
            (add-to-list 'load-path
                         (expand-file-name path user-emacs-directory)))
        '("site-lisp" "lisp" "site-lisp/use-package" "site-lisp/diminish"))
  (defvar use-package-verbose t)
  (require 'use-package))

(require 'bind-key)
(require 'diminish nil t)

;; Enable disabled commands
(setq disabled-command-function nil)

;; Configure libraries
(eval-and-compile
  (add-to-list 'load-path (expand-file-name "lib" user-emacs-directory)))

(use-package async       :defer t :load-path "lib/async")
(use-package dash        :defer t :load-path "lib/dash")
(use-package epl         :defer t :load-path "lib/epl")
(use-package f           :defer t :load-path "lib/f-el")
(use-package inflections :defer t :load-path "lib/inflections")
(use-package let-alist   :defer t)
(use-package pkg-info    :defer t :load-path "lib/pkg-info")
(use-package s           :defer t :load-path "lib/s-el")
(use-package seq         :defer t :load-path "lib/seq")

;; Configure paths
(use-package exec-path-from-shell
  :if (memq window-system '(mac ns))
  :load-path "site-lisp/exec-path-from-shell"
  :config
  (progn
    (dolist (var '("SSH_AUTH_SOCK" "SSH_AGENT_PID" "LANG"
                   "TWO_TASK" "TNS_ADMIN" "NLS_LANG"))
      (add-to-list 'exec-path-from-shell-variables var))
    (exec-path-from-shell-initialize)))

;; Appearance
(add-to-list 'custom-theme-load-path (expand-file-name "themes/base16" user-emacs-directory))
(load-theme 'base16-railscasts-dark t)
(global-hl-line-mode 1)
(set-face-background 'hl-line "gray20")
(set-face-background 'region "SteelBlue4")

;; Backups, auto-saves and lock files
(setq backup-directory-alist `(("." . ,(concat user-emacs-directory "backups")))
      backup-by-copying t
      auto-save-interval 0
      auto-save-timeout 30
      auto-save-file-name-transforms `(("\\`/?\\(?:[^/]*/\\)*\\([^/]*\\)\\'"
                                        ,(concat user-emacs-directory "auto-saves/\\1") t))
      create-lockfiles nil)

;; Scrolling tweaks
(setq scroll-conservatively 101
      scroll-error-top-bottom t
      scroll-preserve-screen-position t
      mouse-wheel-scroll-amount '(1 ((shift) . 1))  ; one line at a time
      mouse-wheel-progressive-speed t
      mouse-wheel-follow-mouse t)

;; Indentation
(setq-default indent-tabs-mode nil
              tab-width 4
              c-basic-offset 4)
(setq tab-stop-list (number-sequence 4 120 4))

;; Aliases
(defalias 'qrr 'query-replace-regexp)
(defalias 'qr 'query-replace)
(defalias 'yes-or-no-p 'y-or-n-p)

;; Miscellaneous custom commands
(defvar jt/silent-commands () "Commands that won't ring the bell.")
(setq jt/silent-commands
      '(mwheel-scroll previous-line next-line backward-char forward-char
                      scroll-down scroll-up))
(defun jt/ring-bell-function ()
  "Rings the bell unless `this-command' is in `jt/silent-commands'."
  (unless (memq this-command jt/silent-commands)
    (ding)))
(setq ring-bell-function 'jt/ring-bell-function)

(defun jt/join-next-line ()
  "Joins the current line to the next line, just like (join-line t).
Convenience for key binding."
  (interactive)
  (join-line t))

(defun jt/smart-beginning-of-line ()
  "Move point to first non-whitespace character or beginning-of-line.

Move point to the first non-whitespace character on this line.
If point was already at that position, move point to beginning-of-line."
  (interactive "^")
  (let ((oldpos (point)))
    (back-to-indentation)
    (and (= oldpos (point))
         (beginning-of-line))))

(defun jt/new-frame-on-temp-buffer ()
  "Creates a new temporary buffer and a new frame displaying that buffer."
  (interactive)
  (select-frame (make-frame))
  (switch-to-buffer (generate-new-buffer "*notes*"))
  (setq default-directory (expand-file-name "~/"))
  (org-mode))

(defun jt/dwim-close ()
  "Do-What-I-Mean close. Deletes the current window. If that is the last window
on the current buffer, kills the buffer. If that is the last window on the
current frame, deletes the frame. Never kills the scratch buffer."
  (interactive)
  (let ((do-kill-buffer (and (= (length (get-buffer-window-list nil nil 0)) 1)
                             (not (equal (buffer-name) "*scratch*"))))
        (do-kill-frame (= (length (window-list)) 1)))
    (cond ((and do-kill-buffer do-kill-frame) (and (kill-buffer) (delete-frame)))
          (do-kill-buffer (kill-buffer-and-window))
          (do-kill-frame (delete-frame))
          (t (delete-window)))))

(defun jt/set-scroll-margin ()
  "Sets scroll-margin for the current buffer."
  (set (make-local-variable 'scroll-margin) 5))
(add-hook 'prog-mode-hook 'jt/set-scroll-margin)
(add-hook 'text-mode-hook 'jt/set-scroll-margin)

;; Unique buffer names
(require 'uniquify)
(setq uniquify-buffer-name-style 'forward)

;; Miscellaneous settings
(add-to-list 'completion-ignored-extensions ".idea/")
(add-to-list 'completion-ignored-extensions ".DS_Store")
(setq-default truncate-lines t)
(electric-pair-mode 1)
(desktop-save-mode 1)

;; Keybindings
(bind-key "C-a" 'jt/smart-beginning-of-line)
(bind-key "s-j" 'jt/join-next-line)
(bind-key "s-J" 'join-line)
(bind-key "s-n" 'jt/new-frame-on-temp-buffer)
(bind-key "s-w" 'jt/dwim-close)
(bind-key "s-[" 'previous-buffer)
(bind-key "s-]" 'next-buffer)
(bind-key "<home>" 'beginning-of-buffer)
(bind-key "<end>" 'end-of-buffer)
(windmove-default-keybindings 'shift)

;; Packages
(use-package abbrev
  :defer t
  :diminish abbrev-mode)

(use-package ag
  :load-path "site-lisp/ag-el"
  :commands (ag ag-regexp)
  :init
  (use-package helm-ag
    :load-path "site-lisp/helm-ag"
    :commands helm-ag))

(use-package autorevert
  :commands auto-revert-mode
  :diminish auto-revert-mode
  :init
  (add-hook 'find-file-hook #'(lambda () (auto-revert-mode 1))))

(use-package cperl-mode
  :defer t
  :init (defalias 'perl-mode 'cperl-mode)
  :config (setq cperl-indent-level 4))

(use-package comint
  :defer t
  :config
  (defun jt/comint-mode-hook ()
    (setq tab-width 8))
  (add-hook 'comint-mode-hook 'jt/comint-mode-hook))

(use-package diff-hl
  :load-path "site-lisp/diff-hl"
  :defer 5
  :config
  (global-diff-hl-mode))

(use-package enh-ruby-mode
  :load-path "site-lisp/enh-ruby-mode"
  :mode (("\\.rb\\'" . enh-ruby-mode)
         ("\\.rake\\'" . enh-ruby-mode)
         ("\\.rabl\\'" . enh-ruby-mode)
         ("\\`Rakefile\\'" . enh-ruby-mode)
         ("\\.gemspec\\'" . enh-ruby-mode)
         ("\\.ru\\'" . enh-ruby-mode)
         ("\\`Gemfile\\'" . enh-ruby-mode)
         ("\\`Vagrantfile\\'" . enh-ruby-mode)
         ("\\.jbuilder\\'" . enh-ruby-mode))
  :interpreter ("ruby" . enh-ruby-mode)
  :config
  (progn
    (setq enh-ruby-bounce-deep-indent t
          enh-ruby-hanging-brace-indent-level 2)

    (use-package inf-ruby :load-path "site-lisp/inf-ruby")
    (add-hook 'enh-ruby-mode-hook 'inf-ruby-minor-mode)

    (use-package robe :load-path "site-lisp/robe")
    (add-hook 'enh-ruby-mode-hook 'robe-mode)

    (use-package yard-mode :load-path "site-lisp/yard-mode")
    (add-hook 'enh-ruby-mode-hook 'yard-mode)

    (use-package rspec-mode
      :disabled t
      :load-path "site-lisp/rspec-mode"
      :config
      (add-to-list 'display-buffer-alist
                   '("\\*rspec-compilation\\*" . (display-buffer-reuse-window . ((reusable-frames . t)
                                                                                 (inhibit-switch-frame . t))))))

    (use-package minitest
      :disabled t
      :load-path "site-lisp/minitest")

    (use-package rake
      :load-path "site-lisp/rake"
      :commands (rake rake-find-task))

    (use-package projectile-rails :load-path "site-lisp/projectile-rails")
    (add-hook 'projectile-mode-hook 'projectile-rails-on)

    (use-package rails-log-mode
      :load-path "site-lisp/rails-log-mode"
      :commands (rails-log-show-development
                 rails-log-show-test
                 rails-log-show-production))

    (defvar jt/enh-ruby-mode-extra-keywords-alist ()
      "Adds sub-filetype-specific keywords to enh-ruby-mode files.
See `jt/enh-ruby-mode-add-keywords'.")

    (setq jt/enh-ruby-mode-extra-keywords-alist
          '(("\\.rabl\\'" "object" "extends" "node" "glue" "child" "attribute"
                          "attributes" "collection" "partial" "cache")
            ("\\`Gemfile\\'" "source" "ruby" "gem" "group")
            ("\\.jbuilder\\'" "json")))

    (defun jt/enh-ruby-mode-add-keywords ()
      "Processes `jt/enh-ruby-mode-extra-keywords-alist' and adds enh-ruby-mode
extra keywords based on the sub-filetype."
      (let ((extra-keywords
             (assoc-default buffer-file-name jt/enh-ruby-mode-extra-keywords-alist 'string-match)))
        (when extra-keywords
          (set (make-local-variable 'enh-ruby-extra-keywords) extra-keywords)
          (enh-ruby-local-enable-extra-keywords))))

    (add-hook 'enh-ruby-mode-hook 'jt/enh-ruby-mode-add-keywords)))

(use-package erc
  :commands erc
  :config
  (add-to-list 'erc-modules 'replace)
  (add-to-list 'erc-modules 'truncate)

  (erc-update-modules)
  (setq erc-default-server "localhost")
  (setq erc-query-display 'buffer)
  (setq erc-auto-query 'bury)
  (setq erc-hide-list '("JOIN" "PART" "QUIT"))
  (setq erc-track-exclude-types '("JOIN" "NICK" "PART" "QUIT" "MODE"
                                  "324" "329" "332" "333" "353" "477"))
  (setq erc-track-exclude-server-buffer t)
  (setq erc-keywords '("\\bjtrull\\b" "\\bjonathan\\b" "\\bjt\\b"))
  ;; (setq erc-replace-alist
  ;;       '(("^<root> Message from unknown participant \\([^:]+\\):" . (replace-match "<\\1>"))))
  (setq erc-prompt (lambda () (concat (car erc-default-recipients) " >")))
  (add-hook 'erc-insert-modify-hook 'erc-replace-insert)
  (add-hook 'erc-mode-hook 'visual-line-mode)
  (erc-truncate-mode 1))

(use-package eshell
  :commands eshell
  :config
  (progn
    (defalias 'eshell/ff 'find-file)
    (defalias 'eshell/ffow 'find-file-other-window)
    (defun eshell/clear () "Clear the eshell buffer"
           (interactive)
           (let ((inhibit-read-only t))
             (erase-buffer)))
    (setq eshell-hist-ignoredups t)
    (setq-default eshell-history-size 10000)))

(use-package flycheck
  :load-path "site-lisp/flycheck"
  :defer 20
  :config
  (global-flycheck-mode))

(use-package flyspell-mode
  :commands flyspell-mode
  :init
  (add-hook 'text-mode-hook 'flyspell-mode))

(use-package helm-config
  :demand t
  :load-path "site-lisp/helm"
  :bind (("M-x" . helm-M-x)
         ("M-y" . helm-show-kill-ring)
         ("C-x C-f" . helm-find-files)
         ("C-x b" . helm-mini)
         ("C-s" . helm-occur)
         ("C-h a" . helm-apropos))
  :config
  (use-package helm-mode
    :diminish helm-mode
    :init
    (helm-mode 1))

  (helm-autoresize-mode 1)

  (bind-key "<tab>" #'helm-execute-persistent-action helm-map)
  (bind-key "C-i" #'helm-execute-persistent-action helm-map)
  (bind-key "C-z" #'helm-select-action helm-map))

(use-package js2-mode
  :load-path "site-lisp/js2-mode"
  :mode "\\.js\\'")

(use-package magit
  :load-path ("site-lisp/magit/lisp"
              "site-lisp/with-editor")
  :commands (magit-status magit-find-file magit-blame))

(use-package markdown-mode
  :load-path "site-lisp/markdown-mode"
  :mode (("\\.md\\'" . markdown-mode)
         ("\\.markdown\\'" . markdown-mode)))

(use-package org
  :commands org-mode
  :config
  (unbind-key "<home>" org-mode-map)
  (unbind-key "<end>" org-mode-map)
  (add-hook 'org-mode-hook
            (lambda ()
              (org-indent-mode 1)
              (visual-line-mode 1))))

(use-package plsql
  :commands plsql-mode
  :config
  (setq plsql-indent 4))

(use-package projectile
  :load-path "site-lisp/projectile"
  :diminish projectile-mode
  :defer 5
  :config
  (projectile-global-mode)
  (use-package helm-projectile
    :load-path "site-lisp/helm-projectile"
    :demand t
    :bind (("s-p" . helm-projectile-find-file)
           ("s-b" . helm-projectile-switch-to-buffer))
    :config
    (setq projectile-completion-system 'helm
          projectile-switch-project-action 'helm-projectile-find-file)
    (helm-projectile-on)))

(use-package restclient
  :disabled t
  :load-path "site-lisp/restclient"
  :commands restclient-mode
  :init
  (progn
    (defun restclient ()
      "Create a new buffer in restclient-mode"
      (interactive)
      (switch-to-buffer (generate-new-buffer "*restclient*"))
      (restclient-mode))))

(use-package scss-mode
  :load-path "site-lisp/scss-mode"
  :mode "\\.scss\\'"
  :config
  (setq scss-compile-at-save nil))

(use-package smart-mode-line
  :load-path "site-lisp/smart-mode-line"
  :init
  (use-package rich-minority :load-path "site-lisp/rich-minority")
  :config
  (line-number-mode 1)
  (column-number-mode 1)
  (setq sml/use-projectile-p 'before-prefixes)
  (sml/setup))

(use-package sql
  :defer t
  :config
  (setq-default sql-product 'oracle)
  (add-to-list 'display-buffer-alist
               '("\\*SQL\\*" . (display-buffer-reuse-window . ((reusable-frames . t)
                                                               (inhibit-switch-frame . t))))))

(use-package sqlplus
  :commands sqlplus
  :config
  ;; Remove ostentatious global menu
  (define-key global-map [menu-bar SQL*Plus] nil)
  ;; Remove broken switch-to-buffer advice that I don't use anyway.
  (ad-remove-advice 'switch-to-buffer 'around 'switch-to-buffer-around-advice)
  (ad-activate 'switch-to-buffer))

(use-package string-edit
  :load-path "site-lisp/string-edit"
  :bind ("C-c e" . string-edit-at-point))

(use-package undo-tree
  :diminish undo-tree-mode
  :config
  (global-undo-tree-mode 1))

(use-package volatile-hightlights
  :load-path "site-lisp/volatile-highlights"
  :defer 5
  :config
  (volatile-highlights-mode t))

(use-package web-mode
  :load-path "site-lisp/web-mode"
  :mode (("\\.cfml?\\'" . web-mode)
         ("\\.html?\\'" . web-mode)
         ("\\.erb\\'" . web-mode))
  :config
  (setq-default web-mode-markup-indent-offset 2
                web-mode-css-indent-offset 2
                web-mode-code-indent-offset 2)
  (setq web-mode-style-padding 2
        web-mode-script-padding 2
        web-mode-block-padding 4))

(use-package which-key
  :load-path "site-lisp/which-key"
  :diminish which-key-mode
  :defer 5
  :config
  (which-key-mode t))

(use-package whitespace
  :diminish whitespace-mode
  :defer t
  :init
  (add-hook 'prog-mode-hook 'whitespace-mode)
  (add-hook 'text-mode-hook 'whitespace-mode)
  :config
  (setq whitespace-style '(face trailing tabs empty))
  (when (display-color-p)
    (set-face-background 'whitespace-tab "#660000")
    (set-face-background 'whitespace-trailing "#660000")
    (set-face-foreground 'whitespace-line nil)
    (set-face-background 'whitespace-line "#440000")
    (set-face-background 'whitespace-empty "#660000")))

(use-package yaml-mode
  :load-path "site-lisp/yaml-mode"
  :mode (("\\.ya?ml\\'" . yaml-mode)))

;; server
(ignore-errors (server-start))

;;; After initialization
(when window-system
  (let ((elapsed (float-time (time-subtract (current-time)
                                            emacs-start-time))))
    (message "Loading %s...done (%.3f)" load-file-name elapsed))
  (add-hook 'after-init-hook
            `(lambda ()
               (let ((elapsed (float-time (time-subtract (current-time)
                                                         emacs-start-time))))
                 (message "Loading %s...done (%.3f) [after-init]"
                          ,load-file-name elapsed)))
            t))

;;; init.el ends here
