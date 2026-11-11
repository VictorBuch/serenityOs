{
  flake.modules.nixos.decent-sampler =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.decent-sampler ];
    };
  flake.modules.homeManager.decent-sampler =
    { pkgs, ... }:
    {
      home.file.".vst3/DecentSampler.vst3".source = "${pkgs.decent-sampler}/lib/vst3/DecentSampler.vst3";
    };
}
