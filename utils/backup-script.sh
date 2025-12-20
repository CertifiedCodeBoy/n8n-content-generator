#!/bin/bash
# Backup important data

BACKUP_DIR="/backups/reddit-automation"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

echo "💾 Starting backup..."

# Backup n8n data
echo "Backing up n8n data..."
docker run --rm \
    -v reddit-story-automation_n8n_data:/data \
    -v "$BACKUP_DIR":/backup \
    alpine tar czf "/backup/n8n-data-$DATE.tar.gz" /data

# Backup state files
echo "Backing up state files..."
if [ -d "/data/state" ]; then
    tar czf "$BACKUP_DIR/state-data-$DATE.tar.gz" /data/state/
fi

# Backup scripts
echo "Backing up scripts..."
if [ -d "/data/scripts" ]; then
    tar czf "$BACKUP_DIR/scripts-$DATE.tar.gz" /data/scripts/*.sh
fi

# Keep only last 7 days of backups
echo "Cleaning old backups..."
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +7 -delete

echo "✅ Backup complete: $BACKUP_DIR"
ls -lh "$BACKUP_DIR" | tail -5