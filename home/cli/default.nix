{ pkgs, lib, ... }:
{

  imports = [
    ./zsh.nix
    ./nushell.nix
    ./fzf.nix
    ./tmux.nix
    ./sesh.nix
    ./starship.nix
    ./neovim/nixvim/neovim.nix
    ./neovim/nvf/nvf.nix
    ./git.nix
  ];

  config = {
    home.cli = {
      zsh.enable = lib.mkDefault false;
      nushell.enable = lib.mkDefault true;
      fzf.enable = lib.mkDefault true;
      tmux.enable = lib.mkDefault true;
      sesh.enable = lib.mkDefault true;
      starship.enable = lib.mkDefault true;
      git.enable = lib.mkDefault true;
      neovim = {
        nixvim.enable = lib.mkDefault false;
        nvf.enable = lib.mkDefault true;
      };
    };
  };
}
