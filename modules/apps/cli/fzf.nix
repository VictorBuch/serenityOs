{
  flake.modules.homeManager.fzf =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      programs.fzf = {
        enable = true;
        package = pkgs.fzf;
        enableZshIntegration = true;
        tmux.enableShellIntegration = true;
      };
    };
}
