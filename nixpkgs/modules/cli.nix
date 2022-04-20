{ config, pkgs, lib, username, homeDirectory, ... }:
let
  inherit (pkgs) fetchFromGithub;
  sources = import ../nix/sources.nix;
in with builtins;
with lib;
with pkgs; {
  home = {
    sessionVariables = {
      HISTCONTROL = "ignoreboth";
      PAGER = "less";
      LESS = "-iR";
      EDITOR = "nvim";
    };

    packages = lib.flatten [
      bat
      (python3.withPackages (pkgs: with pkgs; [ black ipdb ]))
      binutils
      coreutils
      cmake
      curl
      gitAndTools.delta
      gzip
      jq
      fzf
      less
      nix-direnv
      nix-info
      nix-zsh-completions
      nixpkgs-fmt
      unzip
      vim
      which
      wget
      watch
      watchman
      sources.LS_COLORS
      zsh
      zsh-powerlevel10k
      (writeShellScriptBin "hms" ''
        git -C ~/.config/nixpkgs/ pull origin main
        home-manager switch
      '')
    ];
  };

  programs = {
    direnv = {
      enable = true;
      enableNixDirenvIntegration = true;
    };

    fzf.enable = true;

    home.file.".dircolors".source = sources.LS_COLORS.outPath + "/LS_COLORS";
  };
}
