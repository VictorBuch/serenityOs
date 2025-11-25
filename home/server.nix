{
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./home.nix
    ./cli
  ];

  config = {
    # Enable only the specific CLI tools for server
    home.cli = {
      enable = false;  
      git.enable = true;
      fzf.enable = true;
      nushell.enable = true;
      zsh.enable = false;
      starship.enable = true;
      tmux.enable = true;
      sesh.enable = true;
      neovim.enable = false;
    };
  };
}
