;; -*- no-byte-compile: t; -*-
;;; $DOOMDIR/packages.el

;; This file is the DOOMDIR/packages.el bundled by nix-doom-emacs-unstraightened.
;; Nix builds every package listed here at rebuild time (no `doom sync`).
;; After editing: `darwin-rebuild switch --flake .` (or nixos-rebuild).

;; --- Org appearance / writing -------------------------------------------
(package! org-modern)   ; clean, modern org rendering (headings, tables, tags)
(package! org-appear)    ; reveal emphasis markers only under cursor
(package! mixed-pitch)   ; variable-pitch prose, fixed-pitch code in org

;; --- Org agenda dashboard -----------------------------------------------
(package! org-super-agenda) ; grouped, boxed sections in the agenda dashboard

;; --- Org-roam (zettelkasten) --------------------------------------------
(package! org-roam-ui)   ; live graph view of your notes in the browser

;; --- LSP / eglot --------------------------------------------------------
;; Speeds up eglot by routing LSP json-rpc through the `emacs-lsp-booster'
;; binary (provided on PATH from doom.nix). Not on MELPA -> github recipe.
(package! eglot-booster
  :recipe (:host github :repo "jdtsmith/eglot-booster")
  :pin "cab7803c4f0adc7fff9da6680f90110674bb7a22")

;; --- Jujutsu (jj) porcelain ---------------------------------------------
;; majutsu: magit-style interactive jj log/status (native buffer, not a vterm
;; TUI). Reuses magit/transient/with-editor (from :tools magit). Not on MELPA.
(package! majutsu
  :recipe (:host github :repo "0WD0/majutsu")
  :pin "5d1de143c22b494797cce92176f0068c819137e4")


;; --- Dired --------------------------------------------------------------
(package! dirvish :pin "d877433f957a363ad78b228e13a8e5215f2d6593") ; yazi-like dired

;; --- Web / markup -------------------------------------------------------
(package! emmet-mode)    ; Emmet abbreviation expansion (HTML/JSX/TSX/Vue/CSS)

;; --- Excalidraw drawings in org -----------------------------------------
(package! org-excalidraw
  :recipe (:host github :repo "wdavew/org-excalidraw")
  :pin "9750463dfda28b9ca70df048761c131aa94d6c12")
