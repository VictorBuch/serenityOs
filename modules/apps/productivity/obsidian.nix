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
# Plugins track each project's *latest* GitHub release. The release assets
# (main.js/manifest.json/styles.css) come in as flake inputs pinned via
# flake.lock, so `nix flake update` bumps every plugin — no hashes to hand-edit
# here. The builder just reassembles the assets into the layout Obsidian loads.
#
# Note: because .obsidian/* files become read-only symlinks into the Nix store,
# toggling a declared plugin/setting from Obsidian's UI won't persist — change it
# here and rebuild. Plugins left with `settings = null` keep a writable data.json,
# so their in-app settings behave normally. The declared .obsidian files are
# force-linked (see `home.file` below), so a rebuild always wins over whatever
# Obsidian wrote to them at runtime.

args@{
  config,
  pkgs,
  lib,
  mkModule,
  inputs,
  ...
}:

mkModule {
  name = "obsidian";
  category = "productivity";
  description = "Obsidian note-taking app with declarative plugins + settings for ~/notes";

  homeConfig =
    { config, pkgs, lib, ... }:
    let
      # Assemble a community plugin from its release assets (flake inputs) into
      # the directory layout Obsidian loads from (.obsidian/plugins/<id>/).
      # `manifestId` is set as passthru so the home-manager module can name the
      # plugin folder without import-from-derivation (reading manifest.json at
      # eval time). Assets come from `inputs.*`, so versions are locked in
      # flake.lock and bumped by `nix flake update`.
      mkObsidianPlugin =
        {
          manifestId,
          main,
          manifest,
          styles ? null,
        }:
        pkgs.runCommandLocal "obsidian-plugin-${manifestId}"
          {
            passthru = { inherit manifestId; };
          }
          ''
            mkdir -p "$out"
            cp ${main} "$out/main.js"
            cp ${manifest} "$out/manifest.json"
            ${lib.optionalString (styles != null) ''cp ${styles} "$out/styles.css"''}
          '';

      # Tasks — checkbox tasks with emoji dates, recurrence and ✅ done-stamping.
      tasks = mkObsidianPlugin {
        manifestId = "obsidian-tasks-plugin";
        main = inputs.obsidian-tasks-main;
        manifest = inputs.obsidian-tasks-manifest;
        styles = inputs.obsidian-tasks-styles;
      };

      # Task Genius — task views/progress bars over the Tasks emoji syntax.
      # Note: manifest id is the legacy `obsidian-task-progress-bar`.
      taskGenius = mkObsidianPlugin {
        manifestId = "obsidian-task-progress-bar";
        main = inputs.obsidian-task-genius-main;
        manifest = inputs.obsidian-task-genius-manifest;
        styles = inputs.obsidian-task-genius-styles;
      };

      # Omnisearch — full-text fuzzy search across the vault.
      omnisearch = mkObsidianPlugin {
        manifestId = "omnisearch";
        main = inputs.obsidian-omnisearch-main;
        manifest = inputs.obsidian-omnisearch-manifest;
        styles = inputs.obsidian-omnisearch-styles;
      };

      # Templater — template engine (daily-note scaffolds, new-note frontmatter).
      templater = mkObsidianPlugin {
        manifestId = "templater-obsidian";
        main = inputs.obsidian-templater-main;
        manifest = inputs.obsidian-templater-manifest;
        styles = inputs.obsidian-templater-styles;
      };
    in
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

          # Community plugins. Left `settings = null` (no managed data.json) where
          # the plugin's own schema is large/volatile, so its in-app settings stay
          # writable; only Templater gets a pinned template folder.
          communityPlugins = [
            { pkg = tasks; }
            { pkg = taskGenius; }
            { pkg = omnisearch; }
            {
              pkg = templater;
              settings = {
                templates_folder = "templates";
                trigger_on_file_creation = false;
                auto_jump_to_cursor = true;
              };
            }
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
        "notes/.obsidian/community-plugins.json"
        "notes/.obsidian/daily-notes.json"
        "notes/.obsidian/templates.json"
      ] (_: { force = true; });
    };
} args
