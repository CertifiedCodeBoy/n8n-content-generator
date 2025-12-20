#!/bin/bash
# State File Viewer and Manager
# Usage: ./state-viewer.sh [list|view|clean] [video_id]

STATE_DIR="/data/state"
ACTION="${1:-list}"
VIDEO_ID="${2:-}"

case "$ACTION" in
  list)
    echo "=== All State Files ==="
    if [ ! -d "$STATE_DIR" ]; then
      echo "No state directory found"
      exit 0
    fi
    
    for state_file in "$STATE_DIR"/*.json; do
      if [ -f "$state_file" ]; then
        VIDEO_ID=$(basename "$state_file" .json)
        TITLE=$(jq -r '.title' "$state_file")
        STATUS=$(jq -r '.status' "$state_file")
        NEEDS_SPLIT=$(jq -r '.needsSplitting' "$state_file")
        DURATION=$(jq -r '.audioDuration' "$state_file")
        
        echo ""
        echo "Video ID: $VIDEO_ID"
        echo "  Title: $TITLE"
        echo "  Status: $STATUS"
        echo "  Duration: ${DURATION}s"
        echo "  Needs Splitting: $NEEDS_SPLIT"
        
        if [ "$NEEDS_SPLIT" = "true" ]; then
          UPLOADED=$(jq -r '.uploadStatus.partsUploadedCount' "$state_file")
          TOTAL=$(jq -r '.totalParts' "$state_file")
          echo "  Parts Uploaded: $UPLOADED/$TOTAL"
        else
          SINGLE_UPLOADED=$(jq -r '.uploadStatus.singleVideoUploaded' "$state_file")
          echo "  Uploaded: $SINGLE_UPLOADED"
        fi
      fi
    done
    echo ""
    ;;
    
  view)
    if [ -z "$VIDEO_ID" ]; then
      echo "Error: Video ID required"
      echo "Usage: $0 view <video_id>"
      exit 1
    fi
    
    STATE_FILE="$STATE_DIR/${VIDEO_ID}.json"
    if [ ! -f "$STATE_FILE" ]; then
      echo "Error: State file not found: $STATE_FILE"
      exit 1
    fi
    
    echo "=== Full State for $VIDEO_ID ==="
    jq '.' "$STATE_FILE"
    ;;
    
  clean)
    echo "=== Cleaning Completed State Files ==="
    CLEANED=0
    
    for state_file in "$STATE_DIR"/*.json; do
      if [ -f "$state_file" ]; then
        STATUS=$(jq -r '.status' "$state_file")
        if [ "$STATUS" = "completed" ]; then
          VIDEO_ID=$(basename "$state_file" .json)
          echo "Archiving: $VIDEO_ID"
          
          mkdir -p "$STATE_DIR/archive"
          mv "$state_file" "$STATE_DIR/archive/"
          CLEANED=$((CLEANED + 1))
        fi
      fi
    done
    
    echo "Archived $CLEANED completed state files"
    ;;
    
  *)
    echo "Usage: $0 [list|view|clean] [video_id]"
    echo ""
    echo "Actions:"
    echo "  list         - List all state files"
    echo "  view <id>    - View full state file"
    echo "  clean        - Archive completed files"
    exit 1
    ;;
esac