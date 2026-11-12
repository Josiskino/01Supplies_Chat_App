#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
out="$root/store_assets/chat/app-store/ipad-13"
fonts="${GOLDIE_FONTS:-$HOME/.nvm/versions/node/v20.20.0/lib/node_modules/goldie/assets/fonts}"
mkdir -p "$out"
scratch="$(mktemp -d)"

render() {
  local n="$1" title="$2" subtitle="$3" glow="$4" accent="$5" angle="$6"
  local raw="$out/raw/$n.png"
  local width=1470 height
  height="$(magick identify -format '%h' "$raw")"
  local source_width
  source_width="$(magick identify -format '%w' "$raw")"
  height=$((height * width / source_width))
  magick -size 2064x2752 xc:'#080811' \
    \( -size 2064x2200 radial-gradient:"$glow"-'#080811' \) -gravity south -composite \
    \( -size 86x86 xc:none -stroke '#FFFFFF15' -draw 'line 0,0 86,0 line 0,0 0,86' -write mpr:grid +delete -size 2064x2752 tile:mpr:grid \) \
    -gravity center -composite "$scratch/background.png"

  magick "$raw" -resize "${width}x" +repage "$scratch/screen.png"
  magick -size "$((width+62))x$((height+62))" xc:none \
    -fill '#12131c' -stroke '#77768A' -strokewidth 4 \
    -draw "roundrectangle 3,3 $((width+58)),$((height+58)) 72,72" \
    "$scratch/screen.png" -gravity center -compose Over -composite \
    -background none -rotate "$angle" "$scratch/device.png"

  magick "$scratch/background.png" \
    \( "$scratch/device.png" -background black -shadow 80x38+0+32 \) -gravity north -geometry +0+670 -compose Over -composite \
    "$scratch/device.png" -gravity north -geometry +0+660 -composite \
    \( -background none -fill "$accent" -font "$fonts/DMSans-700.ttf" -pointsize 55 label:'01 CHAT' \) -gravity north -geometry +0+125 -composite \
    \( -background none -fill '#FFFFFF' -font "$fonts/DMSans-700.ttf" -pointsize 124 -gravity center -size 1850x caption:"$title" \) -gravity north -geometry +0+235 -composite \
    \( -background none -fill '#DBD8EC' -font "$fonts/DMSans-400.ttf" -pointsize 58 -gravity center -size 1760x caption:"$subtitle" \) -gravity north -geometry +0+470 -composite \
    -alpha off -colorspace sRGB -define png:color-type=2 "$out/$n.png"
}

render 01 'Toutes vos discussions' 'Support et messages directs au même endroit.' '#4027A2' '#C2B3FF' -4
render 02 'Échangez en direct' 'Voyez quand votre interlocuteur vous répond.' '#213B72' '#A7C9FF' 3
render 03 'Gardez le fil des livraisons' 'Retrouvez chaque échange dans sa conversation.' '#56305F' '#FFC1E5' -3
render 04 'Un support plus humain' 'Identifiez la personne qui a répondu.' '#613529' '#FFC2A2' 4
