{ config, pkgs, lib, username, homeDirectory, ... }:
let 
  inherit (pkgs) fetchFromGithub;
  powerlevel10k = fetchFromGitHub {
    owner = "romkatv";
    repo = "powerlevel10k";
    rev = "b7d90c84671183797bdec17035fc2d36b5d12292";
    sha256 = "0nzvshv3g559mqrlf4906c9iw4jw8j83dxjax275b2wi8ix0wgmj";
  };
in 
with builtins;
with lib;
with pkgs; {
  home = {
    inherit username homeDirectory;
    sessionVariables = {
      HISTCONTROL = "ignoreboth";
      PAGER = "less";
      LESS = "-iR";
      EDITOR = "nvim";
    };

    packages = lib.flatten [
      (python3.withPackages (pkgs: with pkgs; [ black ipdb ]))
      coreutils-full
      cmake
      gitAndTools.delta
      gzip
      jq
      less
      nix-direnv
      nix-info
      nixpkgs-fmt
      unzip
      vim
      which
      wget
      zsh
      binutils
      (writeShellScriptBin "hms" ''
        git -C ~/.config/nixpkgs/ pull origin main
        home-manager switch
      '')
    ];
  };

  programs = {
    home-manager.enable = true;
    zsh = mkMerge [
      ({ initExtra = optionalString stdenv.isDarwin ''
        # source the nix profiles
        if [[ -r "${config.home.homeDirectory}/.nix-profile/etc/profile.d/nix.sh" ]]; then
          source "${config.home.homeDirectory}/.nix-profile/etc/profile.d/nix.sh"
        fi
      '';})
    ]
    {
      enable = true;
      inherit (config.home) sessionVariables;
      autocd = true;
      enableCompletion = true;
      enableAutosuggestions = true;

      shellAliases = {
        mkdir = "mkdir -pv";
        hm = "home-manager";

        # misc
        space = "du -Sh | sort -rh | head -10";
        now = "date +%s";
        fzfp = "fzf --preview 'bat --style=numbers --color=always {}'";
      };

      history = {
        expireDuplicatesFirst = true;
        save = 100000000;
        size = 1000000000;
      };

      oh-my-zsh = {
        enable = true;
        plugins = [ "git" "sudo" "thefuck" "history" ];
        theme = "powerlevel10k/powerlevel10k";
      };

      plugins = [
        {
          name = "nix-shell";
          src = fetchFromGitHub {
            owner = "chisui";
            repo = "zsh-nix-shell";
            rev = "03a1487655c96a17c00e8c81efdd8555829715f8";
            sha256 = "1avnmkjh0zh6wmm87njprna1zy4fb7cpzcp8q7y03nw3aq22q4ms";
          };
        }
        {
          name = "zsh-completions";
          src = fetchFromGitHub {
            owner = "zsh-users";
            repo = "zsh-completions";
            rev = "0.27.0";
            sha256 = "1c2xx9bkkvyy0c6aq9vv3fjw7snlm0m5bjygfk5391qgjpvchd29";
          };
        }
        {
          name = "zsh-syntax-highlighting";
          src = fetchFromGitHub {
            owner = "zsh-users";
            repo = "zsh-syntax-highlighting";
            rev = "db6cac391bee957c20ff3175b2f03c4817253e60";
            sha256 = "0d9nf3aljqmpz2kjarsrb5nv4rjy8jnrkqdlalwm2299jklbsnmw";
          };
        }
        {
          name = "powerlevel10k";
          src = powerlevel10k;
        }
      ];
    };

    direnv = {
      enable = true;
      nix-direnv = { 
        enable = true;
      };
    };
  };
}
