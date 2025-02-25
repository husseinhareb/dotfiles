#!/bin/bash

if [ "$1" = "--temp" ]; then
    # Function to check if 'sensors' is installed
    check_dependencies() {
        if ! command -v sensors &> /dev/null; then
            echo "Error: 'sensors' command not found. Please install lm-sensors."
            exit 1
        fi
    }

    # Function to get CPU temperature
    get_cpu_temp() {
        # Use sensors to fetch temperature and extract CPU data
        local temp=$(sensors | grep -i 'core 0' | awk '{print $3}')
        if [ -z "$temp" ]; then
            echo "Could not retrieve CPU temperature. Ensure lm-sensors is properly configured."
            exit 1
        fi

        echo "$temp"
    }

    # Main script
    check_dependencies
    get_cpu_temp

fi

if [ "$1" = "--mic" ]; then
    mic_source=$(pactl info | grep "Default Source:" | awk '{print $3}')

    if [ "$2" = "1" ]; then
        # Left mouse button clicked - toggle microphone mute status
        pactl set-source-mute "$mic_source" toggle
    fi

    # Get the microphone status (mute/unmute)
    mic_status=$(pactl list sources | awk -v mic_source="$mic_source" '/^Source/ {in_source=0} $0 ~ ("Name: " mic_source) {in_source=1} in_source && /Mute:/ {print $2}')

    mic_volume=$(pactl list sources | awk -v mic_source="$mic_source" '/^Source/ {in_source=0} $0 ~ ("Name: " mic_source) {in_source=1} in_source && /Volume:/ {print $5}')

    # Convert the volume to percentage
    mic_percentage=$(awk -v volume="$mic_volume" 'BEGIN {split(volume, a, "%"); print a[1]}')
    # Check the microphone status and set the output accordingly
    if [ "$mic_status" = "yes" ]; then
        echo " muted"
    else
        echo " $mic_percentage%"
    fi
fi


#Spotify

if [ "$1" = "--spotify-spotify" ]; then
    if ! command -v playerctl &> /dev/null; then
        echo "playerctl is not installed."
        exit 1
    fi

    get_spotify_song_linux() {
        playerctl -p spotify metadata --format "{{ artist }} - {{ title }}"
    }

    if pgrep -x "spotify" > /dev/null; then
        song=$(get_spotify_song_linux)

        if [[ -n "$song" ]]; then
            if [ ${#song} -gt 30 ]; then
                song="${song:0:30}..."
            else
                while [ ${#song} -lt 33 ]; do
                song="${song} "
            done
        fi
        echo "$song"
else
    echo "Paused."
fi

    else
        echo "Not running. Click to open."
    fi
fi

if [ "$1" = "--spotify-status" ]; then
    status=$(dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get string:"org.mpris.MediaPlayer2.Player" string:"PlaybackStatus" 2>/dev/null | grep "string")
    status="${status#*\"}"
    status="${status%\"*}"

    if [ -z "$status" ]; then
        echo ""
    elif [ "$status" == "Playing" ]; then
        echo "󰏤"
    else
        echo "󰐊"
    fi
fi

if [ "$1" = "--spotify-previous" ]; then
    dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Previous
fi

if [ "$1" = "--spotify-pause" ]; then
    status=$(dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get string:"org.mpris.MediaPlayer2.Player" string:"PlaybackStatus" | grep "string")

    status="${status#*\"}"
    status="${status%\"*}"

    if [ "$status" == "Playing" ]; then
        dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Pause > /dev/null 2>&1
        echo "󰐊"
    else
        dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Play > /dev/null 2>&1
        echo "󰏤"
    fi
fi

if [ "$1" = "--spotify-next" ]; then
    dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Next
fi
