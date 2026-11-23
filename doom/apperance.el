;;; doom/apperance.el -*- lexical-binding: t; -*-

;; VS Code風UIの実験。元の設定は master ブランチに保存済み。
;; 背景を不透明にすると、Dark+ の色と境界線が安定して見える。
(set-frame-parameter nil 'alpha 100)
(add-to-list 'default-frame-alist '(alpha . 100))
(setq doom-theme 'doom-dark+)
;; フォント
(setq doom-font (font-spec :family "JetBrainsMono Nerd Font" :size 15))

;; エディタの密度を上げ、ペインの境界を見やすくする。
(when (display-graphic-p)
  (setq-default line-spacing 0.08)
  (pixel-scroll-precision-mode 1))
(setq window-divider-default-right-width 1
      window-divider-default-bottom-width 1)
(add-hook 'after-init-hook #'window-divider-mode)
