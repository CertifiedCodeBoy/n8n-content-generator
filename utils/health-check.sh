#!/bin/bash
# System health check script

echo "🏥 Running health checks..."

# Check disk space
DISK_USAGE=$(df /data/files 2>/dev/null | tail -1 | awk '{print $5}' | sed 's/%//')
if [ ! -z "$DISK_USAGE" ]; then
    if [ "$DISK_USAGE" -gt 80 ]; then
        echo "⚠️ WARNING: Disk usage is ${DISK_USAGE}%"
    else
        echo "✅ Disk usage: ${DISK_USAGE}%"
    fi
fi

# Check if n8n container is running
if docker ps | grep -q reddit-video-n8n; then
    echo "✅ n8n container is running"
else
    echo "❌ ERROR: n8n container is not running"
fi

# Check state files
STATE_COUNT=$(ls -1 /data/state/*.json 2>/dev/null | wc -l)
echo "📊 Active state files: $STATE_COUNT"

# Check for stuck processing
STUCK_COUNT=$(find /data/state -name "*.json" -mtime +1 -type f 2>/dev/null | wc -l)
if [ "$STUCK_COUNT" -gt 0 ]; then
    echo "⚠️ WARNING: $STUCK_COUNT state files older than 1 day"
fi

# Check background videos
VIDEO_COUNT=$(ls -1 /data/gameplay/*.mp4 2>/dev/null | wc -l)
if [ "$VIDEO_COUNT" -lt 5 ]; then
    echo "⚠️ WARNING: Only $VIDEO_COUNT background videos found"
else
    echo "✅ Background videos: $VIDEO_COUNT"
fi

echo "✅ Health check complete"