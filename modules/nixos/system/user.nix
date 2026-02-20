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
  options.user = {
    userName = lib.mkOption {
      default = "default";
      description = ''
        username
      '';
    };
    uid = lib.mkOption {
      default = 1000;
    };
    group = lib.mkOption {
      default = "users";
    };
  };

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
