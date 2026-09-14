#!/bin/bash
# idle_handler.sh - ekran (DPMS) ve klavye ışığı yönetimi
# AMD Radeon 860M + eDP panel için optimize edilmiş güvenli uyanma protokolü

action="$1"

KBD_DEV="asus::kbd_backlight"

case "$action" in
    dim)
        # Klavye ışığını kaydet ve kapat
        brightnessctl -d "$KBD_DEV" -s set 0 2>/dev/null

        # Ekranı tamamen kapat (DPMS)
        hyprctl dispatch 'hl.dsp.dpms("off")' 2>/dev/null
        ;;

    restore)
        # 1) Ekranı uyandır — hem genel hem eDP-1'e özel sinyal gönder
        hyprctl dispatch 'hl.dsp.dpms("on")' 2>/dev/null

        # 2) AMD eDP panel handshake'in tamamlanması için bekleme
        #    AMD Krackan (Radeon 860M) + China Star eDP panelde ~1 saniye gerekiyor
        sleep 1

        # 3) İkinci kez dpms on — ilk çağrı paneli uyandırmaya başlar,
        #    ikinci çağrı render döngüsünü garanti altına alır
        hyprctl dispatch 'hl.dsp.dpms("on")' 2>/dev/null

        # 4) Klavye ışığını geri yükle
        brightnessctl -d "$KBD_DEV" -r 2>/dev/null
        ;;
esac
