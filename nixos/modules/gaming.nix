{ pkgs, ... }: {
  programs.steam.enable = true;

  environment.systemPackages = with pkgs; [
    rpcs3
    osu-lazer
    wine
    legendary-gl
  ];
}
