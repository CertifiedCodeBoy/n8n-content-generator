#!/bin/bash
set -euo pipefail

# Video State Manager - Creates and manages state files
# Usage: ./video-state-manager.sh <audio_duration> <video_title>

AUDIO_DURATION="$1"
VIDEO_TITLE="$2"
STATE_DIR="/data/state"
TIMESTAMP=$(date +%s)
VIDEO_ID="video_${TIMESTAMP}"
STATE_FILE="${STATE_DIR}/${VIDEO_ID}.json"

mkdir -p "$STATE_DIR"

# Determine if video needs splitting (90+ seconds)
NEEDS_SPLITTING=false
TOTAL_PARTS=1
PARTS_ARRAY="[]"

if (( $(echo "$AUDIO_DURATION >= 90" | bc -l) )); then
    NEEDS_SPLITTING=true
    
    # Calculate parts (50s each, last part gets remainder if >= 10s)
    SEGMENT_DURATION=50
    CURRENT_START=0
    PART_NUM=1
    PARTS_JSON="["
    
    while (( $(echo "$CURRENT_START < $AUDIO_DURATION" | bc -l) )); do
        REMAINING=$(echo "$AUDIO_DURATION - $CURRENT_START" | bc -l)
        
        if (( $(echo "$REMAINING <= $SEGMENT_DURATION" | bc -l) )); then
            # Last segment
            if (( $(echo "$REMAINING >= 10" | bc -l) || $PART_NUM == 1 )); then
                # Include if >= 10s or it's the only part
                DURATION="$REMAINING"
            else
                # Skip if < 10s and not the only part
                break
            fi
        else
            DURATION="$SEGMENT_DURATION"
        fi
        
        if [ "$PART_NUM" -gt 1 ]; then
            PARTS_JSON="${PARTS_JSON},"
        fi
        
        PARTS_JSON="${PARTS_JSON}{\"partNumber\":${PART_NUM},\"startTime\":${CURRENT_START},\"duration\":${DURATION},\"status\":\"pending\",\"uploadId\":null,\"filePath\":null}"
        
        CURRENT_START=$(echo "$CURRENT_START + $DURATION" | bc -l)
        PART_NUM=$((PART_NUM + 1))
    done
    
    PARTS_JSON="${PARTS_JSON}]"
    TOTAL_PARTS=$((PART_NUM - 1))
    PARTS_ARRAY="$PARTS_JSON"
fi

# Create state file
cat > "$STATE_FILE" << EOF
{
    "videoId": "$VIDEO_ID",
    "title": "$VIDEO_TITLE",
    "audioDuration": $AUDIO_DURATION,
    "needsSplitting": $NEEDS_SPLITTING,
    "totalParts": $TOTAL_PARTS,
    "status": "created",
    "createdAt": "$TIMESTAMP",
    "fullVideoPath": "/data/files/final.mp4",
    "compressedVideoPath": "/data/files/compressed.mp4",
    "parts": $PARTS_ARRAY,
    "uploadStatus": {
        "singleVideoUploaded": false,
        "allPartsUploaded": false,
        "partsUploadedCount": 0
    }
}
EOF

echo "State file created: $STATE_FILE"

# Output JSON for n8n
cat << EOF
{
    "videoId": "$VIDEO_ID",
    "stateFile": "$STATE_FILE",
    "needsSplitting": $NEEDS_SPLITTING,
    "totalParts": $TOTAL_PARTS,
    "audioDuration": $AUDIO_DURATION,
    "parts": $PARTS_ARRAY
}
EOF