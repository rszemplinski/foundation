{ pkgs, ... }:
let inherit (pkgs) fetchFromGithub;
in with builtins; {

  imports = [
    ../../modules/home-manager.nix
    ../../modules/cli.nix
    ../../modules/git.nix
  ];

  programs.zsh = mkMerge [({
    initExtra = optionalString stdenv.isDarwin ''
      # source the nix profiles
      if [[ -r "${config.home.homeDirectory}/.nix-profile/etc/profile.d/nix.sh" ]]; then
        source "${config.home.homeDirectory}/.nix-profile/etc/profile.d/nix.sh"
      fi
    '';
  })] {
    enable = true;
    inherit (config.home) sessionVariables;
    autocd = true;
    enableCompletion = false;

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
        name = "zsh-syntax-highlighting";
        src = fetchFromGitHub {
          owner = "zsh-users";
          repo = "zsh-syntax-highlighting";
          rev = "db6cac391bee957c20ff3175b2f03c4817253e60";
          sha256 = "0d9nf3aljqmpz2kjarsrb5nv4rjy8jnrkqdlalwm2299jklbsnmw";
        };
      }
    ];

    initExtraBeforeCompInit = builtins.readFile ../../configs/zsh/zshrc.zsh;
    initExtra = ''
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/config/p10k-lean.zsh
    '';
  };
}
