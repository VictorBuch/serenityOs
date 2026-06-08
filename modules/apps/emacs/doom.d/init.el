;;; init.el -*- lexical-binding: t; -*-

;; Doom module list. Bundled by nix-doom-emacs-unstraightened — nix rebuilds
;; packages on `darwin-rebuild`/`nixos-rebuild` switch (no `doom sync`).
;; SPC h d h -> Doom docs. K on a module -> its docs. gd -> its source.

(doom! :input

       :completion
       (corfu +orderless +icons +dabbrev)  ; modern in-buffer completion
       vertico                             ; minibuffer completion engine

       :ui
       doom                ; the look
       doom-dashboard      ; splash screen
       hl-todo             ; highlight TODO/FIXME/etc
       ligatures           ; pretty code symbols (JetBrainsMono)
       indent-guides       ; subtle indent columns
       modeline            ; the bar at the bottom
       nav-flash           ; flash cursor line after big jumps
       ophints             ; highlight operation regions
       (popup +defaults)   ; tame temporary windows
       (smooth-scroll)     ; buttery scrolling
       treemacs            ; project file tree (SPC o p)
       (vc-gutter +pretty) ; git diff in the fringe
       vi-tilde-fringe     ; ~ past end of buffer
       workspaces          ; per-project workspaces
       zen                 ; distraction-free writing (SPC t z)

       :editor
       (evil +everywhere)        ; vim everywhere
       file-templates            ; templates for new files
       fold                      ; code folding
       (format +onsave)          ; auto-format on save (apheleia)
       multiple-cursors          ; edit many places at once
       snippets                  ; yasnippet
       word-wrap                 ; language-aware soft wrap (good for prose)
       (whitespace +guess +trim) ; whitespace hygiene

       :emacs
       dired             ; file manager
       electric          ; smart indent
       ibuffer           ; buffer list
       (undo +tree)      ; persistent undo tree
       vc                ; version control
       tramp             ; remote files

       :term
       vterm             ; best terminal in emacs

       :checkers
       syntax            ; flycheck
       (spell +aspell)   ; spellcheck for prose

       :tools
       direnv            ; per-project env via .envrc
       editorconfig      ; respect .editorconfig
       (eval +overlay)   ; run code inline
       (lookup +dictionary +docsets) ; jump to defs/docs
       (lsp +eglot)      ; language server support (built-in eglot)
       magit             ; the best git porcelain
       tree-sitter       ; fast, accurate syntax highlighting

       :os
       (:if (featurep :system 'macos) macos)

       :lang
       data                ; csv/json/xml/etc
       emacs-lisp          ; for configuring doom itself
       (dart +flutter +lsp); dart + flutter
       (javascript +lsp)   ; js + typescript + jsx/tsx (React)
       (json +lsp)
       (kotlin +lsp)       ; kotlin / jetpack compose
       markdown            ; .md files
       (nix +lsp)          ; nix files (this repo)
       (org +roam2 +dragndrop) ; the reason we're here
       (sh +lsp)           ; shell scripts
       (web +lsp)          ; html + css (React styling, tsx markup)
       (yaml +lsp)

       :config
       literate                  ; tangle config.org -> config.el on `doom sync`
       (default +bindings +smartparens))
