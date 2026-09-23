{ lib, ... }:

{
  options.user = {
    userName = lib.mkOption {
      type = lib.types.str;
      default = "default";
      description = "Primary user of this host. Names the system account and the Home Manager user.";
    };
    uid = lib.mkOption {
      type = lib.types.int;
      default = 1000;
    };
    group = lib.mkOption {
      type = lib.types.str;
      default = "users";
    };
  };
}
