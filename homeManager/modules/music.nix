{ config, lib, ... }:

# TODO: wrap the mpv binary in a script that forces certain flags, such as the socket path
# TODO: make jam alias remember volume

{
  programs = {
    fish =
      let
        musicCmdStr =
          "mpv --shuffle --loop-playlist --no-audio-display --volume=35 --input-ipc-server=$XDG_RUNTIME_DIR/mpv.sock";
      in
      rec {
        shellAbbrs.jam = musicCmdStr;
        shellAliases = shellAbbrs;
        functions.bgjam.body = ''
          if tmux has-session -t music &>/dev/null
              tmux attach -t music
          else
              tmux new-session -d -s music -c ~/music fish -C "${musicCmdStr} ."
          end
        '';
      };
    lf.keybindings.gm = "cd ~/music";
  };

  wayland.windowManager.sway = lib.mkIf config.wayland.windowManager.sway.enable
    {
      config.keybindings =
        let mpvsock = "$XDG_RUNTIME_DIR/mpv.sock";
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
          "${modifier}+Shift+down" = ''
            exec echo '{ "command": ["add", "volume", "-2"] }' | socat - ${mpvsock}'';
          "${modifier}+Shift+up" = ''
            exec echo '{ "command": ["add", "volume", "2"] }' | socat - ${mpvsock}'';
        };
    };
}
