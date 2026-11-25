#!/usr/bin/env bash
# Shrinks every video in ./videos to a web-friendly H.264 file (same file names, same place).
# Your untouched originals are moved to ../leerick-videos-original (outside this site folder).
# Needs ffmpeg:  sudo apt install ffmpeg     (Mac: brew install ffmpeg)
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p ../leerick-videos-original
shopt -s nullglob
# Pick an H.264 encoder this ffmpeg actually has (Fedora builds ship openh264, not x264).
ENCODERS="$(ffmpeg -hide_banner -encoders 2>/dev/null)"
if [ "${FORCE_ENC:-}" != "libopenh264" ] && grep -q libx264 <<<"$ENCODERS"; then
  VENC=(-c:v libx264 -preset slow -crf 26 -profile:v high)
elif grep -q libopenh264 <<<"$ENCODERS"; then
  VENC=(-c:v libopenh264 -b:v 2000k)
else
  echo "No H.264 encoder found in ffmpeg. Install one (Fedora: sudo dnf install ffmpeg --allowerasing after enabling RPM Fusion), then run again."; exit 1
fi
echo "Using encoder: ${VENC[1]}"
for f in videos/*.mp4 videos/*.MP4 videos/*.mov videos/*.MOV; do
  name="$(basename "$f")"
  out="videos/.tmp-${name%.*}.mp4"
  echo "Compressing: $name"
  ffmpeg -nostdin -y -loglevel error -i "$f" \
    -vf "scale='if(gt(iw,ih),min(1280,iw),min(720,iw))':-2" \
    "${VENC[@]}" -pix_fmt yuv420p \
    -c:a aac -b:a 96k -movflags +faststart "$out"
  mv -n "$f" "../leerick-videos-original/$name"
  mv "$out" "videos/${name%.*}.mp4"
done
echo "Done. Total size of videos/:"; du -sh videos
