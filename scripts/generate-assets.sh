#!/usr/bin/env bash
set -Eeuo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
target_dir="${1:?Usage: generate-assets.sh OUTPUT_DIRECTORY}"
mkdir -p "$target_dir"

if command -v magick >/dev/null 2>&1; then
  image_command=(magick)
elif command -v convert >/dev/null 2>&1; then
  image_command=(convert)
else
  echo "ImageMagick is required to generate the boot artwork." >&2
  exit 1
fi

"${image_command[@]}" -background none "$root_dir/branding/logo.svg" -resize 256x256 "$target_dir/logo.png"
"${image_command[@]}" -background none "$root_dir/branding/xproductions.svg" -resize 400x63 "$target_dir/xproductions.png"
"${image_command[@]}" "$root_dir/branding/wallpaper.svg" -resize 1920x1080! "$target_dir/wallpaper.png"
"${image_command[@]}" -size 8x8 xc:none -fill '#77c9ff' -draw 'circle 4,4 4,0' "$target_dir/spinner-dot.png"
"${image_command[@]}" -size 32x32 xc:none -fill '#21364e' -draw 'roundrectangle 0,0 31,31 7,7' "$target_dir/select_c.png"

for edge in n s e w ne nw se sw; do
  cp "$target_dir/select_c.png" "$target_dir/select_${edge}.png"
done
