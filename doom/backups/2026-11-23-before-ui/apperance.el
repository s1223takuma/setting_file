;;; doom/apperance.el -*- lexical-binding: t; -*-

;; 見た目の設定
;; 透明度
(set-frame-parameter nil 'alpha 80)
(add-to-list 'default-frame-alist
             '(alpha . 95))
;; テーマ
(setq doom-theme 'doom-nord)
;; フォント
(setq doom-font (font-spec :family "JetBrainsMono Nerd Font" :size 16))
