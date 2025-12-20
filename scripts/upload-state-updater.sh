#!/bin/bash
set -euo pipefail

# Upload State Updater - Updates state after uploads
# Usage: ./upload-state-updater.sh <video_id> <upload_type> <part_number> <upload_id>

VIDEO_ID="$1"
UPLOAD_TYPE="$2"
PART_NUMBER="${3:-0}"
UPLOAD_ID="$4"

STATE_DIR="/data/state"
STATE_FILE="${STATE_DIR}/${VIDEO_ID}.json"

if [ ! -f "$STATE_FILE" ]; then
    echo "❌ State file not found: $STATE_FILE"
    exit 1
fi

STATE_JSON=$(cat "$STATE_FILE")

if [ "$UPLOAD_TYPE" = "single" ]; then
    UPDATED_STATE=$(echo "$STATE_JSON" | jq ".uploadStatus.singleVideoUploaded = true | .status = \"completed\" | .singleUploadId = \"$UPLOAD_ID\"")
    echo "$UPDATED_STATE" > "$STATE_FILE"
    
    echo "✅ Single video upload recorded"
    echo "{\"status\": \"completed\", \"type\": \"single\", \"uploadId\": \"$UPLOAD_ID\"}"
    
elif [ "$UPLOAD_TYPE" = "part" ]; then
    UPDATED_STATE=$(echo "$STATE_JSON" | jq ".parts[] |= if .partNumber == $PART_NUMBER then (.status = \"uploaded\" | .uploadId = \"$UPLOAD_ID\") else . end")
    
    UPLOADED_COUNT=$(echo "$UPDATED_STATE" | jq '[.parts[] | select(.status == "uploaded")] | length')
    TOTAL_PARTS=$(echo "$UPDATED_STATE" | jq '.totalParts')
    
    UPDATED_STATE=$(echo "$UPDATED_STATE" | jq ".uploadStatus.partsUploadedCount = $UPLOADED_COUNT")
    
    if [ "$UPLOADED_COUNT" -eq "$TOTAL_PARTS" ]; then
        UPDATED_STATE=$(echo "$UPDATED_STATE" | jq ".uploadStatus.allPartsUploaded = true | .status = \"completed\"")
        ALL_COMPLETE=true
    else
        ALL_COMPLETE=false
    fi
    
    echo "$UPDATED_STATE" > "$STATE_FILE"
    
    echo "✅ Part $PART_NUMBER upload recorded ($UPLOADED_COUNT/$TOTAL_PARTS)"
    echo "{\"status\": \"part_uploaded\", \"partNumber\": $PART_NUMBER, \"totalParts\": $TOTAL_PARTS, \"uploadedCount\": $UPLOADED_COUNT, \"allComplete\": $ALL_COMPLETE, \"uploadId\": \"$UPLOAD_ID\"}"
else
    echo "❌ Invalid upload type: $UPLOAD_TYPE"
    exit 1
fi