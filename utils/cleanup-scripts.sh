#!/bin/bash
# Clean up old files and archived state

DAYS_OLD=7

echo "🧹 Cleaning up files older than $DAYS_OLD days..."

# Remove old videos
echo "Removing old video files..."
find /data/files -name "*.mp4" -mtime +$DAYS_OLD -delete
find /data/files/parts -name "*.mp4" -mtime +$DAYS_OLD -delete

# Archive old state files
echo "Archiving old state files..."
mkdir -p /data/state/archive
find /data/state -maxdepth 1 -name "*.json" -mtime +$DAYS_OLD -exec mv {} /data/state/archive/ \;

# Clean temp files
echo "Cleaning temp files..."
rm -rf /tmp/video_* 2>/dev/null || true

# Clean old logs
find /var/log -name "*.log" -mtime +$DAYS_OLD -delete 2>/dev/null || true

echo "✅ Cleanup complete"