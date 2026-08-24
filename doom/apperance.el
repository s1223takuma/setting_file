;;; doom/apperance.el -*- lexical-binding: t; -*-

;; 見た目の設定
;; 透明度
(set-frame-parameter nil 'alpha 90)
(add-to-list 'default-frame-alist
             '(alpha . 90))
;; テーマ
(setq doom-theme 'doom-nord)
