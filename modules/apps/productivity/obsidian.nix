# Obsidian — fully declarative config for the ~/notes vault (Phase 3 of the
# friction-free notes + tasks stack; see modules/apps/cli/notes.nix for Phase 1).
#
# What is reproducible vs. what is not:
#   - The VAULT CONTENT (~/notes/*.md, daily/, etc.) is deliberately NOT managed
#     by Nix. It is user data, synced by Syncthing, git-history'd + Quartz-published
#     on mal. home-manager would make it read-only, so we leave it alone.
#   - The VAULT CONFIG (~/notes/.obsidian/*) IS fully declared here via
#     home-manager's `programs.obsidian`. Plugins, core-plugin toggles, app +
#     appearance settings and daily-note/template config are pinned to Nix, so a
#     fresh machine reproduces the exact editor setup without any UI clicking.
#
# Note: because .obsidian/* files become read-only symlinks into the Nix store,
# toggling a declared plugin/setting from Obsidian's UI won't persist — change it
# here and rebuild. The declared .obsidian files are
# force-linked (see `home.file` below), so a rebuild always wins over whatever
# Obsidian wrote to them at runtime.

args@{
  config,
  pkgs,
  lib,
  mkModule,
  ...
}:

mkModule {
  name = "obsidian";
  category = "productivity";
  description = "Obsidian note-taking app with declarative plugins + settings for ~/notes";

  homeConfig =
    { config, pkgs, lib, ... }:
    {
      programs.obsidian = {
        enable = true;

        defaultSettings = {
          # app.json — editor behaviour tuned for a flat, wikilink-based, ADHD
          # friction-free vault (search over folders; new notes land at the root
          # so `nn <title>` keeps the title as the search key).
          app = {
            newFileLocation = "root";
            attachmentFolderPath = "attachments";
            useMarkdownLinks = false; # [[wikilinks]] — Obsidian + Quartz friendly
            newLinkFormat = "shortest";
            alwaysUpdateLinks = true;
            livePreview = true;
            defaultViewMode = "source";
            readableLineLength = true;
            strictLineBreaks = false;
            showLineNumber = false;
            spellcheck = true;
            promptDelete = false;
            showUnsupportedFiles = false;
          };

          # appearance.json (theme, base16 colours, font size) is intentionally
          # NOT set here — Stylix owns it via its own programs.obsidian module so
          # Obsidian stays consistent with the system theme. Setting it here would
          # collide (conflicting definition values).

          # Core plugins. daily-notes + templates carry settings that match the
          # vault scaffold (`daily/` folder, `YYYY-MM-DD`, `templates/` folder)
          # created by notes-init; the rest are plain enables.
          corePlugins = [
            {
              name = "daily-notes";
              settings = {
                folder = "daily";
                format = "YYYY-MM-DD";
                template = "";
                autorun = false;
              };
            }
            {
              name = "templates";
              settings = {
                folder = "templates";
              };
            }
            "file-explorer"
            "global-search"
            "switcher"
            "command-palette"
            "editor-status"
            "backlink"
            "outgoing-link"
            "tag-pane"
            "outline"
            "page-preview"
            "note-composer"
            "bookmarks"
            "properties"
            "file-recovery"
            "word-count"
            "graph"
            "canvas"
          ];
        };

        # The vault itself. `target` is relative to $HOME, so this manages
        # ~/notes/.obsidian/. Settings inherit from defaultSettings above.
        vaults."notes" = {
          target = "notes";
        };
      };

      # Obsidian rewrites these at runtime (unlink + recreate), replacing the
      # store symlink with a plain file. Without `force` the next activation
      # tries to back that file up, hits the .hm-backup left by the previous
      # switch, and aborts the whole home-manager generation.
      home.file = lib.genAttrs [
        "notes/.obsidian/app.json"
        "notes/.obsidian/appearance.json"
        "notes/.obsidian/core-plugins.json"
        "notes/.obsidian/daily-notes.json"
        "notes/.obsidian/templates.json"
      ] (_: { force = true; });
    };
} args
