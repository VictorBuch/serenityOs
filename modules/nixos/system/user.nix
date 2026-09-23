{
  lib,
  config,
  pkgs,
  ...
}:
let
  user = config.user;
in
{
  config = {
    users.users."${user.userName}" = {
      isNormalUser = true;
      home = "/home/${user.userName}";
      description = user.userName;
      extraGroups = [
        "networkmanager"
        "wheel"
        "audio"
        "corectrl"
      ];
      uid = user.uid;
      group = user.group;
      packages = with pkgs; [
        vim
        zsh
        nushell
        git
        os-prober
      ];
      shell = pkgs.nushell;
    };
  };
}
