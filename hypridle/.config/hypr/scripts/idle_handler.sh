#!/bin/bash
# idle_handler.sh - gerçek ekran kapatma (DPMS) ve güvenli uyanma yönetimi

action="$1"

KBD_DEV="asus::kbd_backlight"
SCREEN_DEV="amdgpu_bl1"
SAVE_FILE="/tmp/idle_brightness_save"

case "$action" in
    dim)
        # Mevcut parlaklık seviyesini kaydet
        current_screen=$(brightnessctl -d "$SCREEN_DEV" g 2>/dev/null)
        if [ -n "$current_screen" ] && [ "$current_screen" -gt 0 ]; then
            echo "$current_screen" > "$SAVE_FILE"
        fi

        # Klavye ışığını kaydet ve kapat
        brightnessctl -d "$KBD_DEV" -s set 0 2>/dev/null

        # Ekranı tamamen kapat (DPMS OFF)
        hyprctl dispatch 'hl.dsp.dpms("off")' 2>/dev/null
        ;;

    restore)
        # Ekranı uyandır
        hyprctl dispatch 'hl.dsp.dpms("on")' 2>/dev/null
        hyprctl dispatch 'hl.dsp.dpms("on", "eDP-1")' 2>/dev/null

        # GPU ve panelin uyanması için kısa bir bekleme
        sleep 0.2

        # Ekran parlaklığını geri yükle (sıfırda takılı kalmasını önlemek için)
        if [ -f "$SAVE_FILE" ]; then
            saved_screen=$(cat "$SAVE_FILE" 2>/dev/null)
            if [ -n "$saved_screen" ] && [ "$saved_screen" -gt 0 ]; then
                brightnessctl -d "$SCREEN_DEV" set "$saved_screen" 2>/dev/null
            else
                brightnessctl -d "$SCREEN_DEV" set 50% 2>/dev/null
            fi
        else
            brightnessctl -d "$SCREEN_DEV" set 50% 2>/dev/null
        fi

        # Klavye ışığını geri yükle
        brightnessctl -d "$KBD_DEV" -r 2>/dev/null
        ;;
esac
