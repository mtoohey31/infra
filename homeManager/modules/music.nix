_:
{ config, lib, ... }:

# TODO: wrap the mpv binary in a script that forces certain flags, such as the socket path

let cfg = config.local.music; in
with lib; {
  options.local.music.enable = mkOption {
    type = types.bool;
    default = false;
  };

  config = mkIf cfg.enable {
    programs = {
      fish =
        let
          musicCmdStr =
            ''mpv --shuffle --loop-playlist --no-audio-display --input-ipc-server="$XDG_RUNTIME_DIR/mpv.sock"'';
        in
        rec {
          shellAbbrs.jam = musicCmdStr;
          shellAliases = shellAbbrs;
          functions.bgjam.body = ''
            if tmux has-session -t music &>/dev/null
                tmux attach -t music
            else if status --is-interactive
                tmux new-session -s music -c ~/music fish -C "${musicCmdStr} ."
            else
                tmux new-session -d -s music -c ~/music fish -C "${musicCmdStr} ."
            end
          '';
        };
      lf.keybindings.gm = "cd ~/music";
    };

    wayland.windowManager.sway = lib.mkIf config.wayland.windowManager.sway.enable
      {
        extraConfig = let wobsock = "$XDG_RUNTIME_DIR/wob.sock"; in
          ''
            bindsym --locked Mod4+Shift+Up exec /bin/sh -c 'pulsemixer --list-sink | grep mpv | grep -Po "sink-input-\d+" | xargs -I {} /bin/sh -c "pulsemixer --change-volume +2 --id {}; pulsemixer --get-volume --id {} | cut -d\\" \\" -f1 > ${wobsock}"'
            bindsym --locked Mod4+Shift+Down exec /bin/sh -c 'pulsemixer --list-sink | grep mpv | grep -Po "sink-input-\d+" | xargs -I {} /bin/sh -c "pulsemixer --change-volume -2 --id {}; pulsemixer --get-volume --id {} | cut -d\\" \\" -f1 > ${wobsock}"'
          '';
        config.keybindings =
          let
            mpvsock = "$XDG_RUNTIME_DIR/mpv.sock";
            inherit (config.wayland.windowManager.sway.config) modifier;
          in
          {
            "${modifier}+Shift+space" = ''
              exec test -S ${mpvsock} && echo '{ "command": ["cycle", "pause"] }' | socat - ${mpvsock} || fish -C "bgjam"
            '';
            "${modifier}+Shift+return" = "exec tmux kill-session -t music";
            "${modifier}+Shift+right" = ''
              exec echo '{ "command": ["playlist-next"] }' | socat - ${mpvsock}'';
            "${modifier}+Shift+left" = ''
              exec echo '{ "command": ["playlist-prev"] }' | socat - ${mpvsock}'';
          };
      };
  };
}
