;; -*- no-byte-compile: t; -*-
;;; $DOOMDIR/packages.el

;; This file is the DOOMDIR/packages.el bundled by nix-doom-emacs-unstraightened.
;; Nix builds every package listed here at rebuild time (no `doom sync`).
;; After editing: `darwin-rebuild switch --flake .` (or nixos-rebuild).

;; --- Org appearance / writing -------------------------------------------
(package! org-modern)   ; clean, modern org rendering (headings, tables, tags)
(package! org-appear)    ; reveal emphasis markers only under cursor
(package! mixed-pitch)   ; variable-pitch prose, fixed-pitch code in org

;; --- Org-roam (zettelkasten) --------------------------------------------
(package! org-roam-ui)   ; live graph view of your notes in the browser

;; --- LSP / eglot --------------------------------------------------------
;; Speeds up eglot by routing LSP json-rpc through the `emacs-lsp-booster'
;; binary (provided on PATH from doom.nix). Not on MELPA -> github recipe.
(package! eglot-booster
  :recipe (:host github :repo "jdtsmith/eglot-booster")
  :pin "cab7803c4f0adc7fff9da6680f90110674bb7a22")

;; --- Web / markup -------------------------------------------------------
(package! emmet-mode)    ; Emmet abbreviation expansion (HTML/JSX/TSX/Vue/CSS)

;; --- Excalidraw drawings in org -----------------------------------------
(package! org-excalidraw
  :recipe (:host github :repo "wdavew/org-excalidraw")
  :pin "9750463dfda28b9ca70df048761c131aa94d6c12")
