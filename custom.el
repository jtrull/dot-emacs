(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   (quote
    ("3c83b3676d796422704082049fc38b6966bcad960f896669dfc21a7a37a748fa" "a27c00821ccfd5a78b01e4f35dc056706dd9ede09a8b90c6955ae6a390eb1c1e" default)))
 '(safe-local-variable-values
   (quote
    ((eval progn
           (setq-local projectile-project-test-cmd
                       (function minitest-verify-all))
           (setq-local projectile-project-run-cmd
                       (function projectile-rails-server)))
     (projectile-project-run-cmd quote projectile-rails-server)
     (projectile-project-test-cmd quote minitest-verify-all)))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(default ((t (:inherit nil :stipple nil :background "#2b2b2b" :foreground "#e6e1dc" :inverse-video nil :box nil :strike-through nil :overline nil :underline nil :slant normal :weight normal :height 141 :width normal :foundry "nil" :family "Menlo")))))
