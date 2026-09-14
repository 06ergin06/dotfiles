#!/bin/bash
# idle_handler.sh - ekran (DPMS) ve klavye ışığı yönetimi
# Çift tetiklenmeyi ve GPU çökmesini önlemek için flock (kilit) mekanizması eklendi

exec 9>/tmp/idle_handler.lock
if ! flock -n 9; then
    exit 0
fi

# Mevcut DPMS durumunu kontrol et
# dpmsStatus: true (açık), false (kapalı)
dpms_state=$(hyprctl monitors -j | grep -q '"dpmsStatus": true' && echo "on" || echo "off")

case "$1" in
    dim)
        if [ "$dpms_state" = "on" ]; then
            brightnessctl -d "asus::kbd_backlight" -s set 0 2>/dev/null
            hyprctl dispatch 'hl.dsp.dpms("off")' 2>/dev/null
        fi
        ;;
    restore)
        if [ "$dpms_state" = "off" ]; then
            hyprctl dispatch 'hl.dsp.dpms("on")' 2>/dev/null
            brightnessctl -d "asus::kbd_backlight" -r 2>/dev/null
            
            # AMD GPU'nun uyanma sırasında (handshake) hyprlock kapanırsa çökmesini önlemek için
            sleep 2
        fi
        ;;
esac
