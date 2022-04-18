{ pkgs, config, self, username, homeDirectory, isNixOS, isGraphical, host, ...
}:
with builtins;
with pkgs;
with mylib; {
  home.packages = with pkgs;
    drvsExcept {
      core = {
        inherit acpi atool banner bash-completion bashInteractive bc binutils
          borgbackup bvi bzip2 cacert coreutils-full cowsay curl diffutils
          dos2unix ed fd file findutils gawk gnugrep gnused gnutar gzip
          inetutils iproute2 iputils ldns less libarchive libnotify loop lsof
          man-pages moreutils nano ncdu netcat-gnu niv nix-wrapped nix-tree nmap
          openssh p7zip patch perl pigz procps progress pv ripgrep rlwrap rsync
          sd socat strace time unzip usbutils watch wget which xxd xz zip
          bitwarden-cli libqalculate speedtest-cli tldr nix-top cmake
          nixos-install-tools;
      };
      ${attrIf isGraphical "graphical"} = {
        graphical-core = {
          inherit dzen2 graphviz i3-easyfocus i3lock imagemagick7 sway term
            nsxiv xclip xdotool xsel xterm maim;
          inherit (xorg) xdpyinfo xev xfontsel xmodmap;
        };
        inherit ffmpeg-full mediainfo pavucontrol sox qtbr breeze-icons
          signal-desktop discord zoom-us dejavu_fonts dejavu_fonts_nerd zathura;
      };
      development = {
        inherit bat colordiff ctags dhall git-trim gron highlight xh icdiff jq
          crystal nixpkgs-fmt shellcheck shfmt watchexec yarn
          yarn-bash-completion nodejs_latest gh git-ignore git-fuzzy
          terraform-ls cachix nle concurrently tasknix;
        inherit (nodePackages) npm-check-updates prettier;

      };
      inherit nr switch-to-configuration;
      inherit nle-cfg;
      bin-aliases = attrValues bin-aliases;
    } { ${attrIf isDarwin "darwin"} = { inherit progress; }; };

  home = {
    inherit username homeDirectory;
    sessionVariables = {
      HISTCONTROL = "ignoreboth";
      PAGER = "less";
      LESS = "-iR";
      EDITOR = "nvim";
    };
  };

  fonts.fontconfig.enable = true;

  programs = {
    home-manager.enable = true;
    home-manager.path = inputs.home-manager.outPath;
    zsh = {
      enable = true;
      inherit (config.home) sessionVariables;
      historyFileSize = -1;
      historySize = -1;
      shellAliases = {
        l = "ls -lh";
        ll = "l -a";
        ls = "ls --color=auto --group-directories-first";
        file = "file -s";
        sudo = "sudo ";
        su = "sudo su";
        grep = "grep --color -I";
        rg = "rg --color=always -S --hidden --no-require-git --glob '!/.git/'";
        ncdu = "ncdu --color dark -ex";
        wrun =
          "watchexec --debounce 50 --no-shell --clear --restart --signal SIGTERM -- ";
        root-symlinks = with {
          paths = words
            ".bash_profile .bashrc .inputrc .nix-profile .profile .config .local";
        };
          "sudo ln -sft /root ${homeDirectory}/{${concatStringsSep "," paths}}";
        qemu =
          ", qemu-system-x86_64 -net nic,vlan=1,model=pcnet -net user,vlan=1 -m 3G -vga std -enable-kvm";
      };
      initExtra = prefixIf (!isNixOS) ''
        if command -v nix &> /dev/null;then
          NIX_LINK=$HOME/.nix-profile/bin
          export PATH=$(echo "$PATH" | sed "s#:$NIX_LINK##; s#\(/usr/local/bin\)#$NIX_LINK:\1#")
          unset NIX_LINK
        else
          source ~/.nix-profile/etc/profile.d/nix.sh
          export XDG_DATA_DIRS="$HOME/.nix-profile/share:''${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
        fi
        source ~/.nix-profile/etc/profile.d/bash_completion.sh
        if [[ -d ~/.nix-profile/etc/bash_completion.d ]];then
          for script in ~/.nix-profile/etc/bash_completion.d/*;do
            source $script
          done
        fi
        export GPG_TTY=$(tty)
      '' ''
        [[ $UID -eq 0 ]] && _color=31 _prompt=# || _color=32 _prompt=$
        [[ -n $SSH_CLIENT ]] && _host="$(hostname --fqdn) " || _host=
        PS1="\[\e[1;32m\]''${_host}\[\e[s\e[\''${_place}C\e[1;31m\''${_status}\e[u\e[0;34m\]\w \[\e[0;''${_color}m\]''${_prompt}\[\e[m\] "

        set -o vi
        set +h
        _promptcmd() {
            ret=$?
            [[ $ret -eq 0 || $ret -eq 148 ]] && rstat= || rstat=$ret

            if [[ -z $rstat && -z $jstat ]];then
              _status=
            elif [[ -z $rstat ]];then
              _status=$jstat
            elif [[ -z $jstat ]];then
              _status=$rstat
            else
              _status="$rstat $jstat"
            fi

            _place=$(($COLUMNS - $((''${#_host} + ''${#_status}))))

            history -a
            tail -n1 ~/.bash_history >> ~/.bash_history-all
        }
        PROMPT_COMMAND='_promptcmd'

        source ${complete-alias}/bin/complete_alias
        complete -F _complete_alias $( alias | perl -lne 'print "$1" if /^alias ([^=]*)=/' )

        _completion_loader git
        ___git_complete g __git_main
      '';
      profileExtra = ''
        [[ -e ~/cfg/secrets/github-token ]] && export GITHUB_TOKEN=$(< ~/cfg/secrets/github-token)
      '';
    };

    starship = {
      enable = true;
      settings = {
        add_newline = false;
        golang = {
          style = "fg:#00ADD8";
          symbol = "go ";
        };
        directory.style = "fg:#d442f5";
        nix_shell = {
          pure_msg = "";
          impure_msg = "";
          format = "via [$symbol$state]($style) ";
        };

        # disabled plugins
        aws.disabled = true;
        cmd_duration.disabled = true;
        gcloud.disabled = true;
        package.disabled = true;
      };
    };

    readline = {
      enable = true;
      variables = {
        editing-mode = "vi";
        completion-query-items = -1;
        expand-tilde = false;
        match-hidden-files = false;
        mark-symlinked-directories = true;
        page-completions = false;
        skip-completed-text = true;
        colored-stats = true;
        keyseq-timeout = 0;
        bell-style = false;
        show-mode-in-prompt = true;
        revert-all-at-newline = true;
        vi-ins-mode-string = "\\1\\e[6 q\\2";
        vi-cmd-mode-string = "\\1\\e[2 q\\2";
      };
      bindings = {
        "\\C-p" = "history-search-backward";
        "\\C-n" = "history-search-forward";
        "\\e[A" = "history-search-backward";
        "\\e[B" = "history-search-forward";
        "\\C-d" = "possible-completions";
        "\\C-l" = "complete";
        "\\C-f" = "complete-filename";
        "\\C-e" = "complete-command";
        "\\C-a" = "insert-completions";
        "\\C-k" = "kill-whole-line";
        "\\C-w" = ''" \edba\b"'';
        "\\t" = "menu-complete";
        "\\e[Z" = "menu-complete-backward";
      };
    };
    ssh = {
      enable = true;
      compression = true;
    };
    neovim = {
      enable = true;
      withNodeJs = true;
      extraConfig = readFile ./init.vim;
      plugins = with rec {
        plugins = with vimPlugins; {
          inherit conflict-marker-vim fzf-vim nvim-scrollview quick-scope
            tcomment_vim vim-airline vim-bbye vim-better-whitespace
            vim-code-dark vim-easymotion vim-fugitive vim-lastplace
            vim-multiple-cursors vim-peekaboo vim-polyglot vim-sensible
            vim-startify vim-vinegar

            coc-nvim coc-eslint coc-git coc-json coc-lists coc-prettier
            coc-solargraph coc-tsserver coc-pyright coc-explorer;
        };
        makeExtraPlugins = map (name:
          vimUtils.buildVimPlugin rec {
            pname = name;
            version = src.version or src.rev or "unversioned";
            src = sources.${name};
          });
      };
        attrValues plugins ++ makeExtraPlugins [ "jsonc.vim" "vim-anyfold" ]
        ++ optional (!isDarwin) vimPlugins.vim-devicons;
    };
    htop = {
      enable = true;
      settings = with config.lib.htop; {
        account_guest_in_cpu_meter = true;
        fields = with fields; [
          PID
          USER
          STATE
          PERCENT_CPU
          PERCENT_MEM
          M_RESIDENT
          STARTTIME
          COMM
        ];
        header_margin = false;
        hide_userland_threads = true;
        hide_kernel_threads = true;
        left_meter_modes = with modes; [ Bar Text Bar Bar ];
        left_meters = words "LeftCPUs Blank Memory Swap";
        right_meter_modes = with modes; [ Bar Text Text Text ];
        right_meters = words "RightCPUs Tasks Uptime LoadAverage";
        show_program_path = false;
        show_thread_names = true;
        sort_key = fields.USER;
        tree_view = true;
        update_process_names = true;
        vim_mode = true;
      };
    };
    git = with {
      gs = text:
        let
          script = writeBash "git-script" ''
            set -eo pipefail
            cd -- ''${GIT_PREFIX:-.}
            ${text}
          '';
        in "! ${script}";
      tmpGitIndex = ''
        export GIT_INDEX_FILE=$(mktemp)
        index=$(git rev-parse --show-toplevel)/.git/index
        [[ -e $index ]] && cp "$index" "$GIT_INDEX_FILE" || rm "$GIT_INDEX_FILE"
        trap 'rm -f "$GIT_INDEX_FILE"' EXIT
      '';
    }; {
      enable = true;
      package = gitFull;
      aliases = {
        v = gs "nvim '+ Git | only'";
        a = "add -A";
        br = gs ''
          esc=$'\e'
          reset=$esc[0m
          red=$esc[31m
          yellow=$esc[33m
          green=$esc[32m
          git -c color.ui=always branch -vv "$@" | sed -E \
            -e "s/: (gone)]/: $red\1$reset]/" \
            -e "s/[:,] (ahead [0-9]*)([],])/: $green\1$reset\2/g" \
            -e "s/[:,] (behind [0-9]*)([],])/: $yellow\1$reset\2/g"
          git --no-pager stash list
        '';
        brf = gs "git f --quiet && git br";
        default = gs
          "git symbolic-ref refs/remotes/origin/HEAD | sed s@refs/remotes/origin/@@";
        branch-name = "rev-parse --abbrev-ref HEAD";
        gone = gs
          ''git branch -vv | sed -En "/: gone]/s/^..([^[:space:]]*)\s.*/\1/p"'';
        rmg = gs ''
          gone=$(git gone)
          echo About to remove branches: $gone
          read -n1 -p "Continue? [y/n] " continue
          echo
          [[ $continue = y ]] && git branch -D $gone
        '';
        ca = gs ''git a && git ci "$@"'';
        cap = gs ''git ca "$@" && git p'';
        ci = gs ''
          if [[ -t 0 && -t 1 ]];then
            git commit -v "$@"
          else
            echo unable to run "'git ci'" without a tty
            exit 1
          fi
        '';
        co = "checkout";
        cod = gs ''git co $(git default) "$@"'';
        df = gs ''
          ${tmpGitIndex}
          git add -A
          git -c core.pager='${nr delta} --dark' diff --staged "$@" || true
        '';
        dfo = gs ''git f && git df "origin/''${1:-$(git branch-name)}"'';
        f = "fetch --all";
        g = gs "git f && git mo";
        gr = gs "git pull origin $(git branch-name) --rebase --autostash";
        gd = gs "git fetch origin $(git default):$(git default)";
        md = gs "git merge $(git default)";
        mo = gs "git merge origin/$(git branch-name) --ff-only";
        gmd = gs "git gd && g md";
        rmo = gs "git branch -D $1 && git push origin --delete $1";
        hidden = gs "git ls-files -v | grep '^S' | cut -c3-";
        hide = gs ''git add -N "$@" && git update-index --skip-worktree "$@"'';
        unhide = "update-index --no-skip-worktree";
        l = "log";
        lg = gs "git lfo && git mo";
        lfo = gs
          "git f && git log HEAD..origin/$(git branch-name) --no-merges --reverse";
        p = "put";
        fp = gs ''
          set -e
          git fetch
          loga=$(mktemp)
          logb=$(mktemp)
          git log origin/$(git branch-name) > "$loga"
          git log > "$logb"
          ${nr delta} "$loga" "$logb" || true
          rm "$loga" "$logb"
          read -n1 -p "Continue? [y/n] " continue
          echo
          [[ $continue = y ]] && git put --force-with-lease
        '';
        put = gs ''git push --set-upstream origin $(git branch-name) "$@"'';
        ro = gs ''git reset --hard origin/$(git branch-name) "$@"'';
        ros = gs "git stash && git ro && git stash pop";
        rt = gs "git reset --hard \${1:-HEAD} && git clean -d";
        s = gs
          "git br && git -c color.status=always status | grep -E --color=never '^\\s\\S|:$' || true";
        sf = gs ''git f --quiet && git s "$@"'';
      };
      inherit userName userEmail;
      extraConfig = {
        clean.requireForce = false;
        checkout.defaultRemote = "origin";
        core.autocrlf = "input";
        core.hooksPath = "/dev/null";
        fetch.prune = true;
        pager.branch = false;
        push.default = "simple";
        pull.rebase = false;
        rebase.instructionFormat = "(%an) %s";
        init.defaultBranch = "main";
      };
    };
    direnv.enable = true;
    fzf = {
      enable = true;
      enableBashIntegration = false;
      defaultCommand = "fd -tf -c always -H --ignore-file ${./ignore} -E .git";
      defaultOptions = words "--ansi --reverse --multi --filepath-word";
    };
    dircolors.enable = true;
    vscode.enable = isGraphical;
  };

  dconf.enable = false;
}
