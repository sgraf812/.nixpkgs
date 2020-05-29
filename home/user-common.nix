{ pkgs, lib, ... }:

# Worth considering:
# - [starship](https://starship.rs): Cool cross-shell prompt
# - [sxhkd](https://github.com/baskerville/sxhkd): For X keyboard shortcuts
# - muchsync: If I ever get the E-Mail stuff working
# - xsuspend: Might be useful on the laptop
# - getmail: Automatically fetch mail in a systemd service

{
  imports = [ 
  ];

  home.packages = with pkgs; [
    bat
    bench
    binutils # ar and stuff
    cabal2nix
    cabal-install
    cloc
    creduce
    dtrx
    entr
    exa
    fd
    fzf
    ghc
    gitAndTools.tig
    gnumake
    # gthumb # can crop images # segfaults in ubuntu...
    haskellPackages.ghcid
    # haskellPackages.hkgr # Hackage release management, but it's broken
    haskellPackages.lhs2tex
    haskellPackages.hasktags
    man
    manpages
    ncdu
    ncurses
    nix-diff
    nix-index
    nix-prefetch-scripts
    nofib-analyse # see overlay
    p7zip
    stack
    # stack2nix # broken
    ranger
    rename # prename -- https://stackoverflow.com/a/20657563/388010
    ripgrep
    tldr
    tmux
    tree
    xclip # Maybe use clipit instead?
    xdg_utils
    vlc

    # Haskell/Cabal/Stack stuff
    # haskell-ci # old version, can't get it to work on unstable either
    zlib.dev
    gmp.static
    numactl
  ];

  programs.command-not-found.enable = true;

  programs.zathura.enable = true;

  programs.broot = {
    enable = true;
    enableZshIntegration = true;
  };

  # Used with lorri
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.git = {
    enable = true;
    userName = "Sebastian Graf";
    aliases = {
      a = "add";
      ap = "add --patch";
      abort = "rebase --abort";
      amend = "commit --amend";
      cat = "cat-file -p";
      ci = "commit -a";
      co = "checkout";
      conflict = ''!"$EDITOR" -c '/^[<=|>]\\{7\\}' `git ls-files --unmerged | cut -c 51- | uniq`'';
      contains = "branch --contains";
      continue = "!git add -u && git rebase --continue";
      cx = "commit";
      da = "diff HEAD";
      di = "diff";
      dx = "diff --cached";
      fixup = "commit --amend --reuse-message=HEAD"; # reuses timestamp and authorship info
      # (f)etch (o)rigin and (s)witch to new branch from origin/master
      fos = ''!bash -ec 'if (( $# != 1)); then echo >&2 git fos: 1 parameter expected; exit 2; fi; git fetch origin && git switch --create $1 --no-track origin/master' fos'';
      graph = "log --decorate --graph";
      less = "-p cat-file -p";
      l = "log --decorate --graph --oneline";
      lg = "log --decorate --graph --name-status";
      s = "status -sb";
      sf = "svn fetch";
      suir = "submodule update --init --recursive";
      tar = "archive --format=tar";
      wta = "worktree add --detach"; # "worktree add --force --detach";
      wtas = ''!bash -ec 'if (( $# != 1)); then echo >&2 git wtas: 1 parameter expected; exit 2; fi; tree=\"$(python -c \"from __future__ import print_function; import os, os.path, sys; print(os.path.normpath(os.path.join(os.getenv(\\\"PWD\\\"), sys.argv[1])))\" \"$1\")\"; git wta \"$tree\"; cd \"$(git rev-parse --git-dir)\"; for mod in $(git config --blob HEAD:.gitmodules -l --name-only|gawk -F . \"/\\.path$/ {print \\$2}\"); do [ -d modules/$mod ] && git -C modules/$mod wta \"$tree/$(git config --blob HEAD:.gitmodules --get submodule.$mod.path)\"; done' wtas'';
    };
    extraConfig = {
      core = { 
        editor = "vim";
        pager = "less -x 4 -R -~"; # -F -c
        # excludesfile = "$HOME/.gitignore";
        whitespace = "trailing-space,space-before-tab";
      };
      color.ui = "auto";
      push.default = "simple";
      "url \"git://github.com/ghc/packages-\"".insteadOf = "git://github.com/ghc/packages/";
      "url \"http://github.com/ghc/packages-\"".insteadOf = "http://github.com/ghc/packages/";
      "url \"https://github.com/ghc/packages-\"".insteadOf = "https://github.com/ghc/packages/";
      "url \"ssh://git@github.com/ghc/packages-\"".insteadOf = "ssh://git@github.com/ghc/packages/";
      "url \"git@github.com/ghc/packages-\"".insteadOf = "git@github.com/ghc/packages/";
    };
  };

  programs.home-manager = {
    enable = true;
    path = "https://github.com/rycee/home-manager/archive/release-" + lib.fileContents ../release + ".tar.gz";
  };

  programs.kakoune.enable = true;

  programs.vim = {
    enable = true;
    extraConfig = builtins.readFile vim/vimrc.vim;
    settings = {
      relativenumber = true;
      number = true;
    };
    plugins = with pkgs.vimPlugins; [
      ctrlp                # Fuzzy file finder etc.
      nerdcommenter        # Comment scripts
      nerdtree             # File browser
      fugitive             # Git commands
      sensible             # Sensible defaults
      sleuth               # Heuristically set buffer options
      # Solarized 
      airline              # Powerline in vimscript
      vim-dispatch         # Asynchronous dispatcher
      gitgutter            # Show git changes in gutter
      # align              # Align stuff
      tabular              # Also aligns stuff
      tagbar               # ctags
    ];
  };

  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];
      theme = "robbyrussell";
    };
    initExtra = builtins.readFile zsh/init.zsh;
    sessionVariables = {
      # disable default rprompt...?
      RPROMPT = "";
      # hide user in shell prompt
      DEFAULT_USER = "sgraf";
    };
    shellAliases = {
      nix-zsh = "nix-shell --command zsh";
      nix-stray-roots = "nix-store --gc --print-roots | egrep -v '^(/nix/var|/run/\\w+-system|\\{memory)' | cut -d' ' -f1";
      setclip = "xclip -selection clipboard -in";
      getclip = "xclip -selection clipboard -out";
      e = "vim";
      less = ''\less -XFR'';
      info = "info --vi-keys";
      cg = "valgrind --tool=cachegrind";
      ls = "exa --color=automatic";
      l = "ls -l";
      ll = "l --group --header --links --extended --git";
      la = "ll -a";
      hb = "hadrian/build -j$(($(ncpus) +1))";
      hbq = "hb --flavour=quick";
      hbqs = "hbq --skip='//*.mk' --skip='stage1:lib:rts'";
      hbqf = "hbqs --freeze1";
      hbd2 = "hb --flavour=devel2 --build-root=_devel2";
      hbd2s = "hbd2 --skip='//*.mk'";
      hbd2f = "hbd2s --freeze1";
      hbp = "hb --flavour=prof --build-root=_prof";
      hbps = "hbp --skip='//*.mk'";
      hbpf = "hbps --freeze1";
      hbv = "hb --flavour=validate --build-root=_validate";
      hbvs = "hbv --skip='//*.mk' --skip='stage1:lib:rts'";
      hbvf = "hbvs --freeze1";
      hbt = "mkdir -p _ticky; [ -e _ticky/hadrian.settings ] || echo 'stage1.*.ghc.hs.opts += -ticky\\nstage1.ghc-bin.ghc.link.opts += -ticky' > _ticky/hadrian.settings; hb --flavour=validate --build-root=_ticky";
      hbts = "hbt --skip='//*.mk' --skip='stage1:lib:rts'";
      hbtf = "hbts --freeze1";
      hbd = "mkdir -p _dwarf; [ -e _dwarf/hadrian.settings ] || echo 'stage1.*.ghc.hs.opts += -g3\\nstage1.*.cabal.configure.opts += --disable-library-stripping --disable-executable-stripping' > _dwarf/hadrian.settings; hb --flavour=perf --build-root=_dwarf";
      hbds = "hbd --skip='//*.mk' --skip='stage1:lib:rts'";
      hbdf = "hbds --freeze1";
      head-hackage = ''
        cat << EOF >> cabal.project.local
        repository head.hackage.ghc.haskell.org
            url: https://ghc.gitlab.haskell.org/head.hackage/
            secure: True
            key-threshold: 3
            root-keys:
                f76d08be13e9a61a377a85e2fb63f4c5435d40f8feb3e12eb05905edb8cdea89
                7541f32a4ccca4f97aea3b22f5e593ba2c0267546016b992dfadcd2fe944e55d
                26021a13b401500c8eb2761ca95c61f2d625bfef951b939a8124ed12ecf07329
        EOF
      '';
      ghcconfigure = "./configure $CONFIGURE_ARGS";
    };
  };

  home.keyboard.layout = "de";

  home.language = {
    base = "en_US.UTF-8";
    address = "de_DE.UTF-8";
    monetary = "de_DE.UTF-8";
    paper = "de_DE.UTF-8";
    time = "de_DE.UTF-8";
  };

  home.file = {
    ".tmux.conf".source = ./tmux/tmux.conf;
  };

  home.stateVersion = "19.03";

  services.lorri.enable = true;

  systemd.user.services = {
    onedrive = {
      Unit = {
        Description = "OneDrive Free Client";
        Documentation = "man:onedrive(1)";
        After = [ "local-fs.target" "network.target" ];
      };

      Service = {
        ExecStart = "${pkgs.unstable.onedrive}/bin/onedrive --monitor";
        Restart = "on-abnormal";
      };

      Install = {
        WantedBy = [ "multi-user.target" ];
      };
    };
  };
}
