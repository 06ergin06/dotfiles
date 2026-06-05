#!/bin/bash
CACHE_FILE="$HOME/.cache/quickshell-apps.txt"
ICON_INDEX="$HOME/.cache/quickshell-icons.idx"

build_icon_index() {
    find /usr/share/icons /usr/share/pixmaps ~/.local/share/icons \
        -type f \( -name '*.png' -o -name '*.svg' \) 2>/dev/null > "$ICON_INDEX"
}

lookup_icon() {
    local iconname="$1"
    [[ -z "$iconname" ]] && return 1
    local path
    path=$(grep -m1 -F "/$iconname.png" "$ICON_INDEX" 2>/dev/null)
    if [[ -z "$path" ]]; then
        path=$(grep -m1 -F "/$iconname.svg" "$ICON_INDEX" 2>/dev/null)
    fi
    echo "$path"
}

build_cache() {
    tmp_cache=$(mktemp) || return 1

    build_icon_index

    find /usr/share/applications ~/.local/share/applications \
         /var/lib/flatpak/exports/share/applications \
         ~/.local/share/flatpak/exports/share/applications \
         -name '*.desktop' 2>/dev/null | while read -r f; do
        name=$(grep -m1 '^Name=' "$f" | cut -d= -f2-)
        execline=$(grep -m1 '^Exec=' "$f" | cut -d= -f2-)
        iconname=$(grep -m1 '^Icon=' "$f" | cut -d= -f2-)
        nodisplay=$(grep -m1 '^NoDisplay=' "$f" | cut -d= -f2-)
        [[ "$nodisplay" == "true" ]] && continue
        [[ -z "$name" ]] && continue

        execline=$(echo "$execline" | sed 's/%[a-zA-Z]//g; s/[[:space:]]*$//; s/^"//; s/"$//')
        iconpath=$(lookup_icon "$iconname")

        echo "$name|$execline|$iconpath"
    done | LC_ALL=C sort -t'|' -k1,1 | uniq > "$tmp_cache"
    mv "$tmp_cache" "$CACHE_FILE"
}

if [[ ! -f "$CACHE_FILE" ]]; then
    build_cache
elif [[ $(find /usr/share/applications ~/.local/share/applications \
         /var/lib/flatpak/exports/share/applications \
         ~/.local/share/flatpak/exports/share/applications \
         -name '*.desktop' -newer "$CACHE_FILE" -print -quit 2>/dev/null) ]]; then
    build_cache
fi

cat "$CACHE_FILE"
