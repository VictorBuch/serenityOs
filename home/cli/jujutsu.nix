args@{
  config,
  pkgs,
  lib,
  mkHomeModule,
  ...
}:

mkHomeModule {
  _file = toString ./.;
  name = "jujutsu";
  description = "Jujutsu git";
  homeConfig =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      programs.jujutsu = {
        enable = true;
        package = pkgs.unstable.jujutsu;
        settings = {
          user = {
            email = "victorbuch@protonmail.com";
            name = "VictorBuch";
          };
          git = {
            auto-local-bookmark = true;
          };
          ui = {
            abandon-on-new = true;
            default-command = "log-recent";
          };
          template-aliases = {
            "format_short_change_id(id)" = "id.shortest()";
          };
          revset-aliases = {
            "closest_bookmark(to)" = "heads(::to & bookmarks())";
            "closest_pushable(to)" = ''heads(::to & ~description(exact:"") & (~empty() | merges()))'';
            "default()" = "coalesce(trunk(),root())::present(@) | ancestors(visible_heads() & recent(), 2)";
            "recent()" = ''committer_date(after:"1 month ago")'';
          };
          aliases = {
            tug = [
              "bookmark"
              "move"
              "--from"
              "closest_bookmark(@)"
              "--to"
              "closest_pushable(@)"
            ];
            log-recent = [
              "log"
              "-r"
              "default() & recent()"
            ];
            c = [ "commit" ];
            ci = [
              "commit"
              "--interactive"
            ];
            e = [ "edit" ];
            i = [
              "git"
              "init"
              "--colocate"
            ];
            nb = [
              "bookmark"
              "create"
              "-r"
              "@-"
            ];
            pull = [
              "git"
              "fetch"
            ];
            push = [
              "git"
              "push"
            ];
            r = [ "rebase" ];
            s = [ "squash" ];
            si = [
              "squash"
              "--interactive"
            ];
            d = [ "desc" ];
          };
        };
      };
    };
} args
