{ ... }:

# TODO: wrap the mpv binary in a script that forces certain flags, such as the socket path

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
}
