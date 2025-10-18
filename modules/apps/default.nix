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
