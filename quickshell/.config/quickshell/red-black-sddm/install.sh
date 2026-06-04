#!/bin/bash
set -e

echo "Installing Red-Black SDDM theme..."

sudo mkdir -p /usr/share/sddm/themes/red-black
sudo cp -r "$(dirname "$0")"/{Main.qml,theme.conf,metadata.desktop,background.png,angle-down.png} /usr/share/sddm/themes/red-black/
sudo chmod -R 755 /usr/share/sddm/themes/red-black

echo "Configuring SDDM..."
sudo tee /etc/sddm.conf.d/theme.conf > /dev/null <<'CONF'
[Theme]
Current=red-black
CursorTheme=Bibata-Modern-Classic
Font=Noto Sans,10

[General]
HaltCommand=/usr/bin/systemctl poweroff
RebootCommand=/usr/bin/systemctl reboot

[Users]
MaximumUid=60000
MinimumUid=1000
CONF

echo "Done! Restart SDDM or reboot to see the new theme."
echo "To test without rebooting: sudo systemctl restart sddm"
