#!/bin/bash
# idle_handler.sh - ekran ve klavye ışığı yönetimi

action="$1"

KBD_DEV="asus::kbd_backlight"
BRIGHTNESS_SAVE="/tmp/idle_brightness_save"

case "$action" in
    dim)
        # Mevcut ekran parlaklığını kaydet
        brightnessctl -d amdgpu_bl1 g > "$BRIGHTNESS_SAVE" 2>/dev/null

        # Klavye ışığını kaydet ve kapat
        brightnessctl -d "$KBD_DEV" -s set 0 2>/dev/null

        # Ekranı kapat (DPMS)
        hyprctl dispatch 'hl.dsp.dpms("off")' 2>/dev/null
        ;;
    restore)
        # Ekranı aç
        hyprctl dispatch 'hl.dsp.dpms("on")' 2>/dev/null

        # Kısa bekle - DPMS'in gelmesi için
        sleep 0.3

        # Ekran parlaklığını geri yükle
        if [ -f "$BRIGHTNESS_SAVE" ]; then
            saved=$(cat "$BRIGHTNESS_SAVE")
            if [ -n "$saved" ] && [ "$saved" -gt 0 ] 2>/dev/null; then
                brightnessctl -d amdgpu_bl1 set "$saved" 2>/dev/null
            fi
        fi

        # Klavye ışığını geri yükle
        brightnessctl -d "$KBD_DEV" -r 2>/dev/null
        ;;
esac
