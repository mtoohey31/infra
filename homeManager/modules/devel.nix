_:
{ config, lib, pkgs, ... }:

let cfg = config.local.devel;
in
with lib; {
  options.local.devel.enable = mkOption {
    type = types.bool;
    default = false;
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      uncommitted-go
      docker

      rnix-lsp
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
          da = "direnv allow";
          dr = "direnv reload";
          nfi = "nix flake init --template github:mtoohey31/templates#";
          g = "git";
        };
        shellAliases = shellAbbrs;
      };
      git = {
        enable = true;
        userName = "Matthew Toohey";
        userEmail = "contact@mtoohey.com";
        iniContent = {
          branch = { autosetuprebase = "always"; };
          init = { defaultBranch = "main"; };
        };
        ignores = [ ".direnv/" ];
        aliases = {
          a = "add --verbose";
          aa = "add --all --verbose";
          af = "add --force --verbose";
          afp = "add --force --patch";
          afhp = "add --force --patch .";
          ah = "add --verbose .";
          ahp = "add --patch .";
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
          cu = "reset HEAD~";
          d = "diff";
          dh = "diff .";
          dl = "diff HEAD~ HEAD";
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
          sh = "status --short .";
          ssh =
            "!git remote set-url origin $(git remote get-url origin | sed -E 's/^https?:\\/\\/github.com\\//git@github.com:/g')";
          t = "stash push --include-untracked";
          td = "stash drop";
          tl = "stash list";
          tp = "stash pop";
          tpp = "stash push --patch";
          ts = "stash show";
          u = "pull";
          ut = "pull --autostash";
          w = "worktree";
          wa = "worktree add";
          wm = "worktree move";
          wr = "worktree remove";
          x = "rm";
          xc = "rm --cached";
          xch = "rm --cached .";
          xrc = "rm -r --cached";
          xrch = "rm -r --cached .";
          y = "cherry-pick";
          ya = "cherry-pick --abort";
          yc = "cherry-pick --continue";
          unbare = ''
            !f() { TARGET="$(echo "$1" | sed -E 's/\.git\/?$//')" && mkdir "$TARGET" && cp -r "$1" "$TARGET/.git" && cd "$TARGET" && git config --local --bool core.bare false && git reset --hard; }; f'';
        } // (pkgs.lib.optionalAttrs (builtins.hasAttr "copy" config.programs.fish.shellAliases)
          { h = "!${config.programs.fish.shellAliases.copy} \"$(git rev-parse HEAD)\""; });
      };
      gh = {
        enable = true;
        enableGitCredentialHelper = true;
        settings = { git_protocol = "ssh"; };
      };
    };

    home.sessionVariables.GOPATH = "${config.home.homeDirectory}/.go";
  };
}
