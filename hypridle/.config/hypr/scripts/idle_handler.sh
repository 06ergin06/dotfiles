#!/bin/bash
# idle_handler.sh - ekran arka aydınlatması ve klavye ışığı yönetimi (DPMS yerine güvenli yöntem)

action="$1"

KBD_DEV="asus::kbd_backlight"
SCREEN_DEV="amdgpu_bl1"
SAVE_FILE="/tmp/idle_brightness_save"

case "$action" in
    dim)
        # Ekranın mevcut parlaklığını al
        current_screen=$(brightnessctl -d "$SCREEN_DEV" g 2>/dev/null)
        
        # Eğer parlaklık sıfırdan büyükse kaydet (0 ise eski kaydı ezme)
        if [ -n "$current_screen" ] && [ "$current_screen" -gt 0 ]; then
            echo "$current_screen" > "$SAVE_FILE"
        fi

        # Klavye ışığını kaydet ve kapat
        brightnessctl -d "$KBD_DEV" -s set 0 2>/dev/null

        # Ekran arka aydınlatmasını tamamen kapat (ekran kararır, DPMS bug'ı yaşanmaz)
        brightnessctl -d "$SCREEN_DEV" set 0 2>/dev/null
        ;;

    restore)
        # Ekran parlaklığını geri yükle
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

        # Klavye ışığını eski haline döndür
        brightnessctl -d "$KBD_DEV" -r 2>/dev/null
        ;;
esac
