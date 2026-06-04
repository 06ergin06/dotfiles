#!/bin/bash
CACHE_FILE="$HOME/.cache/quickshell-apps.txt"

build_cache() {
    declare -A iconmap
    while IFS= read -r -d '' f; do
        name=$(basename "$f")
        noext="${name%.*}"
        iconmap["$noext"]="$f"
    done < <(find /usr/share/icons /usr/share/pixmaps ~/.local/share/icons -type f \( -name '*.png' -o -name '*.svg' \) -print0 2>/dev/null)

    tmp_cache=$(mktemp)
    find /usr/share/applications ~/.local/share/applications /var/lib/flatpak/exports/share/applications ~/.local/share/flatpak/exports/share/applications -name '*.desktop' 2>/dev/null | while read -r f; do
        name=$(grep -m1 '^Name=' "$f" | cut -d= -f2-)
        execline=$(grep -m1 '^Exec=' "$f" | cut -d= -f2-)
        iconname=$(grep -m1 '^Icon=' "$f" | cut -d= -f2-)
        nodisplay=$(grep -m1 '^NoDisplay=' "$f" | cut -d= -f2-)
        [[ "$nodisplay" == "true" ]] || [[ -z "$name" ]] && continue

        execline=$(echo "$execline" | sed 's/%[a-zA-Z]//g; s/[[:space:]]*$//; s/^"//; s/"$//')
        iconpath="${iconmap[$iconname]}"

        echo "$name|$execline|$iconpath"
    done | LC_ALL=C sort -t'|' -k1,1 | uniq > "$tmp_cache"
    mv "$tmp_cache" "$CACHE_FILE"
}

if [ ! -f "$CACHE_FILE" ]; then
    build_cache
elif [ $(find "$CACHE_FILE" -mmin +30 2>/dev/null) ]; then
    build_cache &
fi

cat "$CACHE_FILE"
