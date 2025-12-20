#!/bin/sh
set -euo pipefail

# Enhanced Video Generator - Creates single full video
# Reads from /data/scripts/story.mp3 and /data/scripts/story.srt
# Outputs to /data/files/final.mp4

SCRIPTS_DIR="/data/scripts"
CACHE_FILE="/data/scripts/validated_videos.txt"
OUTPUT_PATH="/data/files/final.mp4"

echo "🎬 Creating full video from Reddit story"

# Buffer for video (extra seconds)
BUFFER=2

# Get audio duration
AUDIO_DURATION=$(ffprobe -i "${SCRIPTS_DIR}/story.mp3" -show_entries format=duration -v quiet -of csv="p=0")
SAFE_DUR=$(echo "$AUDIO_DURATION + $BUFFER" | bc | awk '{print int($1+0.5)}')

echo "📏 Audio Duration: ${AUDIO_DURATION}s, Video needed: ${SAFE_DUR}s"

# Check for validated videos
if [ ! -s "$CACHE_FILE" ]; then
  echo "❌ Validated videos cache file is missing or empty!"
  exit 1
fi

# Create output directory
mkdir -p "$(dirname "$OUTPUT_PATH")"

# Crop filter function
get_crop_filter() {
  local video_file="$1"
  local dimensions=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "$video_file")
  local width=$(echo "$dimensions" | cut -d'x' -f1)
  local height=$(echo "$dimensions" | cut -d'x' -f2)
  local current_ratio=$(echo "scale=6; $width / $height" | bc -l)
  local target_ratio=$(echo "scale=6; 9 / 16" | bc -l)

  >&2 echo "📐 Video dimensions: ${width}x${height}"

  local diff=$(echo "scale=6; if ($current_ratio > $target_ratio) $current_ratio - $target_ratio else $target_ratio - $current_ratio" | bc -l)
  local tolerance="0.01"

  if [ "$(echo "$diff > $tolerance" | bc -l)" -eq 1 ]; then
    if [ "$(echo "$current_ratio > $target_ratio" | bc -l)" -eq 1 ]; then
      local new_width=$(echo "$height * 9 / 16" | bc | awk '{print int($1)}')
      new_width=$(echo "$new_width" | awk '{print int($1/2)*2}')
      local crop_x=$(echo "($width - $new_width) / 2" | bc | awk '{print int($1)}')
      >&2 echo "📱 Cropping to 9:16: crop=${new_width}:${height}:${crop_x}:0"
      echo "crop=${new_width}:${height}:${crop_x}:0"
    else
      local new_height=$(echo "$width * 16 / 9" | bc | awk '{print int($1)}')
      new_height=$(echo "$new_height" | awk '{print int($1/2)*2}')
      local crop_y=$(echo "($height - $new_height) / 2" | bc | awk '{print int($1)}')
      >&2 echo "📱 Cropping to 9:16: crop=${width}:${new_height}:0:${crop_y}"
      echo "crop=${width}:${new_height}:0:${crop_y}"
    fi
  else
    >&2 echo "✅ Video is already 9:16 ratio"
    echo ""
  fi
}

# Main loop - pick random valid video
ATTEMPT=0
MAX_ATTEMPTS=5

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
  ATTEMPT=$((ATTEMPT + 1))
  echo "🎬 Attempt $ATTEMPT: Selecting video..."
  
  VIDEO=$(shuf -n 1 "$CACHE_FILE")
  echo "🎬 Selected video: $VIDEO"

  VID_LEN=$(timeout 10s ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$VIDEO" 2>/dev/null | awk '{print int($1+0.5)}')
  
  if [ -z "$VID_LEN" ] || [ "$VID_LEN" -eq 0 ]; then
    echo "⚠️ Could not get video length, trying next..."
    continue
  fi

  echo "📏 Video length: ${VID_LEN}s"

  MAX_START=$(echo "$VID_LEN - $SAFE_DUR" | bc | awk '{print int($1)}')
  
  if [ "$MAX_START" -gt 0 ]; then
    START=$(shuf -i 0-"$MAX_START" -n 1)
  else
    START=0
  fi

  CROP_FILTER=$(get_crop_filter "$VIDEO")

  NEEDED=$(echo "$SAFE_DUR - ($VID_LEN - $START)" | bc | awk '{print int($1)}')
  if [ "$NEEDED" -lt 0 ]; then
    NEEDED=0
  fi

  SUBTITLE_FILTER="subtitles=${SCRIPTS_DIR}/story.srt:force_style='FontName=Arial Black,FontSize=16,Bold=1,PrimaryColour=&Hffffff,SecondaryColour=&Hffffff,OutlineColour=&H000000,BackColour=&H80000000,BorderStyle=3,Outline=2,Shadow=1,Alignment=2,MarginV=60'"

  if [ -n "$CROP_FILTER" ]; then
    if [ "$NEEDED" -gt 0 ]; then
      VF="${CROP_FILTER},${SUBTITLE_FILTER},tpad=stop_mode=clone:stop_duration=$NEEDED,scale=1080:1920:flags=lanczos,format=yuv420p"
    else
      VF="${CROP_FILTER},${SUBTITLE_FILTER},scale=1080:1920:flags=lanczos,format=yuv420p"
    fi
  else
    if [ "$NEEDED" -gt 0 ]; then
      VF="${SUBTITLE_FILTER},tpad=stop_mode=clone:stop_duration=$NEEDED,scale=1080:1920:flags=lanczos,format=yuv420p"
    else
      VF="${SUBTITLE_FILTER},scale=1080:1920:flags=lanczos,format=yuv420p"
    fi
  fi

  echo "🎨 Video filter: $VF"
  echo "⏱️ Video Start: ${START}s, Duration: ${SAFE_DUR}s"

  timeout 300s ffmpeg -y -hide_banner -loglevel error \
    -ss "$START" -i "$VIDEO" \
    -i "$SCRIPTS_DIR/story.mp3" \
    -t "$SAFE_DUR" \
    -map 0:v -map 1:a \
    -vf "$VF" \
    -c:v libx264 \
    -preset slow \
    -crf 18 \
    -profile:v high \
    -level 4.0 \
    -x264opts keyint=48:min-keyint=48:scenecut=-1 \
    -pix_fmt yuv420p \
    -c:a aac -b:a 192k -ac 2 -ar 44100 \
    -movflags +faststart \
    -max_muxing_queue_size 9999 \
    "$OUTPUT_PATH" && break

  echo "❌ Attempt $ATTEMPT failed, trying another..."
done

if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
  echo "💥 Failed after $MAX_ATTEMPTS attempts!"
  exit 1
fi

FINAL_DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$OUTPUT_PATH")

echo "✅ Created $OUTPUT_PATH"
echo "📊 Final video duration: ${FINAL_DURATION}s"

echo "{\"videoPath\": \"$OUTPUT_PATH\", \"duration\": $FINAL_DURATION, \"audioDuration\": $AUDIO_DURATION}"