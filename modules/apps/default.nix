{ pkgs, lib, ... }:
{

  imports = [
    ./browsers
    ./audio
    ./communication
    ./gaming
    ./emulation
    ./development
    ./productivity
    ./media
    ./utilities
    ./emacs
  ];

}
#
# args@{ config, pkgs, lib, isLinux, mkCategory, ... }:
#
# mkCategory {
#   _file = toString ./.;
#   name = "apps";
# } args
