#!/usr/bin/env bash
# Requires fonttools (pyftsubset). Source fonts are supplied by the owner.
set -euo pipefail

font_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../assets/fonts" && pwd)"
latin_faces=(
  SpaceGrotesk-Medium SpaceGrotesk-Bold
  IBMPlexSans-Regular IBMPlexSans-Medium IBMPlexSans-SemiBold
  IBMPlexMono-Regular IBMPlexMono-Medium
)
arabic_faces=(
  IBMPlexSansArabic-Regular IBMPlexSansArabic-Medium IBMPlexSansArabic-SemiBold
)

# Check all inputs before replacing any previously generated subset.
for face in "${latin_faces[@]}" "${arabic_faces[@]}"; do
  if [[ ! -s "$font_root/$face.ttf" ]]; then
    printf 'Missing source font: %s\n' "$font_root/$face.ttf" >&2
    exit 1
  fi
done
if ! command -v pyftsubset >/dev/null 2>&1; then
  printf 'pyftsubset is required. Install fonttools and brotli in a Python environment.\n' >&2
  exit 1
fi

subset_dir="$(mktemp -d "$font_root/.subsets.XXXXXX")"
trap 'rm -rf "$subset_dir"' EXIT
for face in "${latin_faces[@]}"; do
  pyftsubset "$font_root/$face.ttf" \
    --unicodes="U+0000-00FF,U+0131,U+0152-0153,U+2000-206F,U+2074,U+20AC,U+2122,U+2212" \
    --layout-features="kern,liga,tnum,onum" \
    --output-file="$subset_dir/$face-subset.ttf"
done
for face in "${arabic_faces[@]}"; do
  # All OpenType features are essential: Latin flags destroy Arabic joining.
  pyftsubset "$font_root/$face.ttf" \
    --unicodes="U+0600-06FF,U+0750-077F,U+08A0-08FF,U+FB50-FDFF,U+FE70-FEFF,U+0000-00FF,U+2000-206F" \
    --layout-features="*" \
    --output-file="$subset_dir/$face-subset.ttf"
done

total_bytes=0
for subset in "$subset_dir"/*-subset.ttf; do
  total_bytes=$((total_bytes + $(wc -c < "$subset")))
done
if (( total_bytes > 480000 )); then
  printf 'Font budget exceeded: %s bytes (maximum 480000).\n' "$total_bytes" >&2
fi
for subset in "$subset_dir"/*-subset.ttf; do
  destination="$font_root/$(basename "$subset")"
  # Preserve timestamps as well as bytes on repeated runs.
  if ! cmp -s "$subset" "$destination"; then
    mv "$subset" "$destination"
  fi
done
printf 'Generated ten subsets: %s bytes / 480000-byte budget.\n' "$total_bytes"
