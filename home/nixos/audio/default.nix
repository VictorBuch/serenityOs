args@{ mkHomeCategory, ... }:

mkHomeCategory {
  _file = toString ./.;
  name = "audio";
} args
