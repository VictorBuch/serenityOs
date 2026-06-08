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

;; --- Excalidraw drawings in org -----------------------------------------
(package! org-excalidraw
  :recipe (:host github :repo "wdavew/org-excalidraw")
  :pin "9750463dfda28b9ca70df048761c131aa94d6c12")
