#!/bin/bash
set -euo pipefail

# Part Processor - Creates video parts from full video
# Usage: ./part-processor.sh <video_id> <part_number>

VIDEO_ID="$1"
PART_NUMBER="$2"
STATE_DIR="/data/state"
STATE_FILE="${STATE_DIR}/${VIDEO_ID}.json"
PARTS_DIR="/data/files/parts"

mkdir -p "$PARTS_DIR"

if [ ! -f "$STATE_FILE" ]; then
    echo "❌ State file not found: $STATE_FILE"
    exit 1
fi

STATE_JSON=$(cat "$STATE_FILE")

PART_INFO=$(echo "$STATE_JSON" | jq -r ".parts[] | select(.partNumber == $PART_NUMBER)")
if [ "$PART_INFO" = "" ]; then
    echo "❌ Part $PART_NUMBER not found in state"
    exit 1
fi

START_TIME=$(echo "$PART_INFO" | jq -r '.startTime')
DURATION=$(echo "$PART_INFO" | jq -r '.duration')
TOTAL_PARTS=$(echo "$STATE_JSON" | jq -r '.totalParts')
VIDEO_TITLE=$(echo "$STATE_JSON" | jq -r '.title')
FULL_VIDEO_PATH=$(echo "$STATE_JSON" | jq -r '.fullVideoPath')

PART_FILE="${PARTS_DIR}/${VIDEO_ID}_part${PART_NUMBER}.mp4"

echo "Creating Part $PART_NUMBER/$TOTAL_PARTS"
echo "Start: ${START_TIME}s, Duration: ${DURATION}s"
echo "Output: $PART_FILE"

ffmpeg -y -hide_banner -loglevel error \
  -ss "$START_TIME" \
  -i "$FULL_VIDEO_PATH" \
  -t "$DURATION" \
  -c copy \
  -avoid_negative_ts make_zero \
  "$PART_FILE"

if [ ! -f "$PART_FILE" ]; then
    echo "❌ Failed to create part $PART_NUMBER"
    exit 1
fi

UPDATED_STATE=$(echo "$STATE_JSON" | jq ".parts[] |= if .partNumber == $PART_NUMBER then (.status = \"created\" | .filePath = \"$PART_FILE\") else . end")
echo "$UPDATED_STATE" > "$STATE_FILE"

ACTUAL_DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$PART_FILE")
FILE_SIZE=$(du -h "$PART_FILE" | cut -f1)

echo "✅ Part $PART_NUMBER/$TOTAL_PARTS created"
echo "Duration: ${ACTUAL_DURATION}s, Size: $FILE_SIZE"

cat << EOF
{
    "videoId": "$VIDEO_ID",
    "partNumber": $PART_NUMBER,
    "totalParts": $TOTAL_PARTS,
    "partFile": "$PART_FILE",
    "duration": $ACTUAL_DURATION,
    "title": "$VIDEO_TITLE (Part $PART_NUMBER/$TOTAL_PARTS)",
    "baseTitle": "$VIDEO_TITLE",
    "stateFile": "$STATE_FILE"
}
EOF