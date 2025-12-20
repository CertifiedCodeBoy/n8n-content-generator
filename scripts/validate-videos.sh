#!/bin/bash
set -euo pipefail

# Validate background videos and create cache file

GAMEPLAY_DIR="/data/gameplay"
CACHE_FILE="/data/scripts/validated_videos.txt"

echo "🔍 Validating background videos..."

if [ ! -d "$GAMEPLAY_DIR" ]; then
    echo "❌ Gameplay directory not found: $GAMEPLAY_DIR"
    exit 1
fi

> "$CACHE_FILE"

COUNT=0
for video in "$GAMEPLAY_DIR"/*.mp4; do
    if [ -f "$video" ]; then
        DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$video" 2>/dev/null || echo "0")
        
        if [ "$(echo "$DURATION > 120" | bc)" -eq 1 ]; then
            echo "$video" >> "$CACHE_FILE"
            COUNT=$((COUNT + 1))
            echo "✅ Valid: $(basename "$video") (${DURATION}s)"
        else
            echo "⚠️ Too short: $(basename "$video") (${DURATION}s)"
        fi
    fi
done

echo ""
echo "📊 Validated $COUNT videos"
echo "📄 Cache file: $CACHE_FILE"