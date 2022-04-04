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

    if set graphics (supergfxctl -g)
        set -a output  $graphics" |"
    else
        set -a output " misbehaving |"
    end

    set -a output  (btrfs filesystem usage -H / 2> /dev/null | string match -e "Free (estimated):" | string replace -r '\s*Free \(estimated\):\s+' '' | string replace -r '\s+\(min: [\d\.]+\w+\)' '')" |"

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

    if test -S /tmp/mpv-socket && set state (echo '{ "command": ["get_property", "pause"] }' | socat - /tmp/mpv-socket 2> /dev/null)
        if test (echo "$state" | jq -r '.data') = true
            set -a output 契
        else
            set -a output 
        end

        set -a output (echo '{ "command": ["get_property", "media-title"] }' | socat - /tmp/mpv-socket | jq -r '.data')

        set artist (echo '{ "command": ["get_property", "metadata/artist"] }' | socat - /tmp/mpv-socket | jq -r '.data')

        if test "$artist" != null
            set -a output "- $artist"
        end

        set -a output "|"
    end

    set -a output (date +' %a. %b %-d  %-I:%M:%S %p')" |"

    echo $output

    # TODO: make the interval more reliable to account for the time taken by commands
    sleep 1
end
