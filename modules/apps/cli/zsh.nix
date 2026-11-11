let
  aliases = {
    v = "sudo nvim ";
    vi = "sudo nvim ";
    zshrc = "sudo nvim ~/.zshrc";
    lg = "lazygit";
    en = "nvim ~/serenityOs/ ";
    r = "source ~/.zshrc";
    ".." = "(cd ..) && (ls)";
  };
in
{
  flake.modules.homeManager.zsh =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      home.packages = with pkgs; [
        zsh
      ];

      programs.zsh = {
        enable = true;
        shellAliases = aliases;
        autosuggestion.enable = true;
        initContent = ''
          eval "$(starship init zsh)"
          eval "$(zoxide init zsh)"
        '';
      };
    };
}
