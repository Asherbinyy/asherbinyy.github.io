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
  #
  # The ranges are modern Arabic only, and two earlier inclusions are
  # deliberately gone:
  #
  # - U+FB50-FDFF and U+FE70-FEFF are the Arabic Presentation Forms. They are
  #   legacy precomposed shapes; HarfBuzz derives initial, medial, final and
  #   isolated forms from the base block through GSUB, so shipping them cost
  #   36KB a face and changed nothing on screen.
  # - U+0750-077F and U+08A0-08FF are extended blocks for languages this site
  #   does not publish in. Arabic here is Arabic, not Persian or Urdu.
  #
  # Together these took the three Arabic faces from 543KB to 303KB.
  pyftsubset "$font_root/$face.ttf" \
    --unicodes="U+0600-0605,U+060C-061F,U+0621-064A,U+064B-0652,U+0660-0669,U+066A-066D,U+0670,U+06D4,U+0000-00FF,U+2000-206F" \
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
