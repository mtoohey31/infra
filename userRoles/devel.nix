{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    (rWrapper.override {
      packages = with rPackages; [ ggplot2 ];
    }) # TODO: add configuration

    docker
    gcc
    gnumake
    cargo
  ];

  programs = {
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
    fish = rec {
      shellAbbrs = {
        dc = "docker compose";
        dcu = "docker compose up -d --remove-orphans";
        dcd = "docker compose down --remove-orphans";
        dcdu = "docker compose -f docker-compose-dev.yaml up --remove-orphans";
        dcdd =
          "docker compose -f docker-compose-dev.yaml down --remove-orphans";
        g = "git";
      };
      shellAliases = shellAbbrs // {
        R = "R --quiet --save";
        python3 = "python3 -q";
      };
    };
    git = {
      enable = true;
      userName = "Matthew Toohey";
      userEmail = "contact@mtoohey.com";
      iniContent = {
        branch = { autosetuprebase = "always"; };
        init = { defaultBranch = "main"; };
      };
      ignores = [ ".direnv/" ".envrc" ];
      # TODO: add prompts for dangerous stuff that doesn't already include it by default
      aliases = {
        a = "add --verbose";
        aa = "add --all --verbose";
        af = "add --force --verbose";
        afp = "add --force --patch --verbose";
        ah = "add --verbose .";
        ap = "add --patch --verbose";
        add = "add --verbose";
        b = "!git --no-pager branch";
        bd = "branch --delete";
        bm = "branch --move";
        br = "!git branch -m $(git rev-parse --abbrev-ref HEAD)";
        bs = "branch --set-upstream-to";
        bt = "branch --track";
        bv = "!git --no-pager branch --verbose";
        c = "commit";
        ca = "commit --amend";
        cap = "!git commit --amend && git push";
        cm = ''!f() { git commit --message "$*"; }; f'';
        can = "commit --amend --no-edit";
        canp = "!git commit --amend --no-edit && git push";
        d = "diff";
        dl = "diff HEAD^ HEAD";
        ds = "diff --staged";
        e = "rebase";
        ea = "rebase --abort";
        ec = "rebase --continue";
        ei = "rebase --interactive";
        eir = "rebase --interactive --root";
        eirt = "rebase --interactive --root --autostash";
        eit = "rebase --interactive --autostash";
        et = "rebase --autostash";
        f = "fetch";
        fu = "fetch --unshallow";
        g = "reflog";
        i = "init";
        k = "checkout";
        kb = "checkout -b";
        l = "log";
        m = "remote --verbose";
        ma = "remote add";
        mao = "remote add origin";
        mau = "remote add upstream";
        mp = "remote prune";
        mpo = "remote prune origin";
        mr = "remote rename";
        mro = "remote rename origin";
        ms = "remote set-url";
        mso = "remote set-url origin";
        msu = "remote set-url upstream";
        o = "clone";
        ob = "clone --bare";
        p = "push";
        pf = "push --force";
        pu =
          "!git push --set-upstream origin $(git rev-parse --abbrev-ref HEAD)";
        puf =
          "!git push --force --set-upstream origin $(git rev-parse --abbrev-ref HEAD)";
        r = "restore";
        rh = "restore .";
        rs = "restore --staged";
        rp = "restore --patch";
        rsh = "restore --staged .";
        rsp = "restore --staged --patch .";
        s = "status --short";
        ssh =
          "!git remote set-url origin $(git remote get-url origin | sed -E 's/^https?:\\/\\/github.com\\//git@github.com:/g')";
        t = "stash push --include-untracked";
        tc = "stash clear";
        td = "stash drop";
        tl = "stash list";
        tp = "stash pop";
        u = "pull";
        ut = "pull --autostash";
        w = "worktree";
        wa = "worktree add";
        wm = "worktree move";
        wr = "worktree remove";
        x = "rm";
        xc = "rm --cached";
        xrc = "rm -r --cached";
        unbare = ''
          !f() { TARGET="$(echo "$1" | sed -E 's/\.git\/?$//')" && mkdir "$TARGET" && cp -r "$1" "$TARGET/.git" && cd "$TARGET" && git config --local --bool core.bare false && git reset --hard; }; f'';
      };
    };
    gh = {
      enable = true;
      enableGitCredentialHelper = true;
      settings = { git_protocol = "ssh"; };
    };
    go = {
      enable = true;
      goPath = ".go";
      package = pkgs.go_1_18;
    };
    kakoune = { plugins = with pkgs.kakounePlugins; [ kak-lsp ]; };
  };
}
