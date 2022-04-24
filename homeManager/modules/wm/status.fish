# TODO: replace this with something that caches values that don't need to be updated every second

while true
    set output

    if ip link show wg0 &>/dev/null
        set -a output "嬨 |"
    end

    if test (iwctl station (ip route show default | awk '{ print $5 }') show | grep -Po "(?<=State).*" | string trim) = connected
        set -a output 直 (iwctl station (ip route show default | awk '{ print $5 }') show | grep -Po "(?<=Connected network).*" | string trim)" |"
    else
        set -a output "睊 |"
    end

    if set graphics (supergfxctl -g | string replace -r '^Current graphics mode: ' '')
        set -a output  $graphics" |"
    else
        set -a output " misbehaving |"
    end

    set free_size (df -h / | tail -n1 | awk '{ print $4 }')
    if test (echo "$free_size" | tr -d '[:alpha:]') -le 100
        set -a output  "$free_size |"
    end

    set hs_bat (headsetcontrol -cb 2> /dev/null)
    if test "$status" -eq 0
        set -a output  $hs_bat"% |"
    end

    if test -d /sys/class/power_supply/BAT0 && set battery_percent (math -s 0 (cat /sys/class/power_supply/BAT0/energy_now) / (cat /sys/class/power_supply/BAT0/energy_full) \* 100)
        if test (cat /sys/class/power_supply/BAT0/status) != Discharging
            set -a output 
        else
            set -a output 
        end
        set -a output "$battery_percent% |"
    end

    if test (pulsemixer --get-mute) -eq 1
        set -a output 婢" |"
    else
        set -a output 墳 (pulsemixer --get-volume | awk '{ print $1 }')"% |"
    end

    if test -S $XDG_RUNTIME_DIR/mpv.sock && set state (echo '{ "command": ["get_property", "pause"] }' | socat - $XDG_RUNTIME_DIR/mpv.sock 2> /dev/null)
        if test (echo "$state" | jq -r '.data') = true
            set -a output 契
        else
            set -a output 
        end

        set -a output (echo '{ "command": ["get_property", "media-title"] }' | socat - $XDG_RUNTIME_DIR/mpv.sock | jq -r '.data')

        set artist (echo '{ "command": ["get_property", "metadata/artist"] }' | socat - $XDG_RUNTIME_DIR/mpv.sock | jq -r '.data')

        if test "$artist" != null
            set -a output "- $artist"
        end

        set -a output "|"
    end

    sleep (math 1 - (date +%N) / 1000000000)

    set -a output (date +' %a. %b %-d  %-I:%M:%S %p')" |"

    echo $output
end
