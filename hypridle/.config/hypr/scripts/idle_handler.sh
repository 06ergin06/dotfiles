#!/bin/bash
# idle_handler.sh - ekran ve klavye ışığı yönetimi

action="$1"

case "$action" in
    dim)
        # Mevcut klavye ışığını kaydet ve kapat
        brightnessctl -d 'asus::kbd_backlight' -s set 0

        # Ekranı tamamen kapat (DPMS)
        hyprctl dispatch 'hl.dsp.dpms("off")'
        ;;
    restore)
        # Ekranı aç
        hyprctl dispatch 'hl.dsp.dpms("on")'

        # Klavye ışığını geri yükle
        brightnessctl -d 'asus::kbd_backlight' -r
        ;;
esac
