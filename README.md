# Reddit Video Automation Workflow

An automated n8n workflow that creates engaging YouTube Shorts videos from Reddit stories. The system scrapes viral Reddit posts, generates AI-powered narration with subtitles, creates video content, and uploads to YouTube with proper metadata.

## Features

- **Automated Reddit Scraping**: Fetches high-engagement stories from popular subreddits
- **AI-Powered Content Processing**: Uses Google Gemini to clean and optimize stories for TTS
- **Text-to-Speech Integration**: Generates natural voice narration using custom TTS API
- **Video Generation**: Creates professional video content with subtitles and effects
- **Smart Video Splitting**: Automatically handles long content by splitting into multiple YouTube Shorts
- **YouTube Upload Automation**: Direct upload to YouTube with optimized titles and descriptions
- **Telegram Notifications**: Real-time updates on upload status
- **Google Sheets Logging**: Tracks all uploaded videos for analytics
- **Docker Support**: Containerized deployment for easy scaling

## Prerequisites

- n8n instance (self-hosted or cloud)
- Reddit API credentials
- Google Gemini API key
- YouTube API credentials
- Telegram Bot API token
- Google Sheets API credentials
- TTS API server (custom implementation)
- Video processing server with FFmpeg
- Docker and Docker Compose (for containerized deployment)

## Installation

### Option 1: Docker Deployment

1. Clone this repository:

```bash
git clone <repository-url>
cd app
```

2. Configure environment variables:

```bash
cp docker/.env.example docker/.env
# Edit docker/.env with your actual credentials
```

3. Start the services:

```bash
docker-compose -f docker/docker-compose.yml up -d
```

### Option 2: Manual Setup

1. Install n8n and required dependencies
2. Import the workflow from `workflows/reddit-video-workflow.json`
3. Configure all credential placeholders in the workflow
4. Ensure all scripts in `scripts/` are executable and properly configured

## Configuration

### Environment Variables

Create a `.env` file in the docker directory with:

```env
# TTS API Configuration
TTS_API_URL=your-tts-api-endpoint
TTS_API_KEY=your-tts-api-key

# Video Server Configuration
VIDEO_SERVER_URL=your-video-server-url
VIDEO_STORAGE_PATH=/data/files

# Database/Storage
REDIS_URL=redis://redis:6379
POSTGRES_URL=postgresql://user:pass@db:5432/n8n

# External APIs
REDDIT_CLIENT_ID=your-reddit-client-id
REDDIT_CLIENT_SECRET=your-reddit-client-secret
GEMINI_API_KEY=your-gemini-api-key
YOUTUBE_CLIENT_ID=your-youtube-client-id
YOUTUBE_CLIENT_SECRET=your-youtube-client-secret
TELEGRAM_BOT_TOKEN=your-telegram-bot-token
GOOGLE_SHEETS_CREDENTIALS=your-google-sheets-credentials
```

### n8n Workflow Configuration

1. Import `workflows/reddit-video-workflow.json` into your n8n instance
2. Update all credential placeholders:
   - `YOUR_REDDIT_CREDENTIALS_ID`
   - `YOUR_GEMINI_CREDENTIALS_ID`
   - `YOUR_YOUTUBE_CREDENTIALS_ID`
   - `YOUR_TELEGRAM_CREDENTIALS_ID`
   - `YOUR_GOOGLE_SHEETS_CREDENTIALS_ID`
3. Update API endpoints:
   - `YOUR_TTS_API_URL`
   - `YOUR_VIDEO_SERVER_URL`
4. Configure Telegram chat ID: `YOUR_TELEGRAM_CHAT_ID`
5. Set Google Sheet ID: `YOUR_GOOGLE_SHEET_ID`

## Usage

### Running the Workflow

1. Ensure all credentials and configurations are set
2. Activate the workflow in n8n
3. The workflow runs automatically based on the configured schedule
4. Monitor execution through n8n's workflow interface

### Manual Trigger

You can trigger the workflow manually from n8n or set up webhooks for external triggering.

### Monitoring

- Check Telegram notifications for real-time updates
- Review Google Sheets for upload history
- Monitor n8n logs for execution details
- Use the state management scripts for debugging

## Scripts Overview

The `scripts/` directory contains various automation scripts:

- `video-state-manager.sh`: Manages video processing states and queue
- `enhanced-video-generator.sh`: Main video creation script with effects and subtitles
- `part-processor.sh`: Handles video splitting for multi-part content
- `upload-state-updater.sh`: Updates upload status and metadata
- `state-viewer.sh`: Debug tool for viewing current processing states
- `validate-videos.sh`: Quality assurance and validation checks

### Script Dependencies

All scripts require:

- FFmpeg for video processing
- ImageMagick for image manipulation
- Python 3.8+ with required libraries
- Access to shared storage volumes

## Documentation

Detailed documentation is available in the `docs/` directory:

- [Setup Guide](docs/SETUP.md): Complete installation and configuration
- [Configuration](docs/CONFIGURATION.md): Advanced configuration options
- [Troubleshooting](docs/TROUBLESHOOTING.md): Common issues and solutions
- [Architecture](docs/ARCHITECTURE.md): System design and component overview

## API Endpoints

### TTS Service

- `POST /api/tts`: Generate audio from text
- Body: `{"text": "story text", "voice": "voice-id"}`

### Video Server

- `GET /files/{filename}`: Serve generated video files
- `POST /process`: Trigger video processing

## Development

### Adding New Features

1. Modify the n8n workflow JSON
2. Update corresponding scripts if needed
3. Test in development environment
4. Update documentation

### Testing

Use the provided example files:

- `examples/state-file-example.json`: Sample state file for testing
- `examples/workflow-screenshots/`: UI reference screenshots

## Security Considerations

- Store all credentials securely using n8n's credential management
- Use environment variables for sensitive configuration
- Regularly rotate API keys and tokens
- Monitor access logs for unauthorized usage
- Implement rate limiting on external APIs

## Troubleshooting

### Common Issues

1. **TTS API Connection Failed**

   - Verify TTS_API_URL and credentials
   - Check network connectivity

2. **YouTube Upload Errors**

   - Confirm YouTube API quotas
   - Validate video file format and size

3. **Reddit API Rate Limits**

   - Implement delays between requests
   - Use multiple Reddit accounts if needed

4. **Video Processing Failures**
   - Check FFmpeg installation
   - Verify input file formats
   - Review script logs

### Logs and Debugging

- n8n workflow execution logs
- Script output in `/data/logs/`
- Telegram notifications for status updates
- Google Sheets for upload tracking

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

### Code Standards

- Follow n8n workflow best practices
- Document all new features
- Include error handling
- Test with various content types

## License

This project is licensed under the terms specified in the LICENSE file.

## Support

For support and questions:

- Check the troubleshooting documentation
- Review n8n community forums
- Create an issue in the repository

## Changelog

### Version 1.0.0

- Initial release with full Reddit to YouTube automation
- AI-powered content processing
- Multi-part video support
- Comprehensive logging and notifications
