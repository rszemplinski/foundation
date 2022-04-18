{ pkgs, lib, config, self, ... }: {
  environment.etc."nixpkgs-path".source = pkgs.path;
  nix.nixPath = [ "nixpkgs=/etc/nixpkgs-path" ];
  nix.extraOptions = self.nixConf;
  programs.ssh.extraConfig = "";
  programs.ssh.knownHosts = { };
  networking.networkmanager.enable = true;

  hardware.enableRedistributableFirmware = true;
  hardware.enableAllFirmware = true;

  nixpkgs = { inherit (self) config overlays; };

  zramSwap = {
    enable = true;
    memoryPercent = 100;
  };

  console = {
    earlySetup = true;
    font = "default8x16";
  };

  fonts.enableDefaultFonts = config.services.xserver.enable;

  security.rtkit.enable = true;
  services = {
    dbus.packages = with pkgs; [ dconf ];
    chrony.enable = true;
    tlp.enable = false;
    logind.lidSwitch = "ignore";
    journald.extraConfig = "SystemMaxUse=100M";
  };

  users = {
    users."ryan.szemplinski" = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
    };
  };

  security.sudo.wheelNeedsPassword = false;
  system.stateVersion = "21.11";
  programs.command-not-found.enable = false;
}
