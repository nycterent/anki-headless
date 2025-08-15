# Anki Headless Docker Container

A Docker container that packages the Anki Linux client with AnkiConnect plugin to provide headless Anki functionality accessible via HTTP API.

## Features

- **Headless Operation**: Runs Anki without GUI using virtual display (Xvfb)
- **AnkiConnect Integration**: Full API access via HTTP on port 8765
- **Data Persistence**: Volume mounting for Anki collections and media
- **Security**: Runs as non-root user with minimal privileges
- **Health Checks**: Built-in health monitoring
- **CORS Support**: Configurable cross-origin resource sharing

## Quick Start

### Using Docker Compose (Recommended)

1. Clone or download the project files
2. Build and start the container:

```bash
docker-compose up -d
```

3. Test the AnkiConnect API:

```bash
curl -X POST http://localhost:8765 \
  -H "Content-Type: application/json" \
  -d '{"action": "version", "version": 6}'
```

### Using Docker Build

```bash
# Build the image
docker build -t anki-headless .

# Run the container
docker run -d \
  --name anki-headless \
  -p 8765:8765 \
  -v anki_data:/home/anki/.local/share/Anki2 \
  anki-headless
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `ANKI_DATA_DIR` | `/home/anki/.local/share/Anki2` | Anki data directory |
| `ANKI_PORT` | `8765` | AnkiConnect port |
| `ANKI_CORS_ORIGINS` | `*` | CORS allowed origins |

### Volume Mounts

- `/home/anki/.local/share/Anki2` - Main Anki data directory
- `/home/anki/.local/share/Anki2/User 1/collection.media` - Media files

## API Usage

### Basic API Test

```bash
curl -X POST http://localhost:8765 \
  -H "Content-Type: application/json" \
  -d '{"action": "version", "version": 6}'
```

### Create a Note

```bash
curl -X POST http://localhost:8765 \
  -H "Content-Type: application/json" \
  -d '{
    "action": "addNote",
    "version": 6,
    "params": {
      "note": {
        "deckName": "Default",
        "modelName": "Basic",
        "fields": {
          "Front": "What is Docker?",
          "Back": "A containerization platform"
        }
      }
    }
  }'
```

### List Decks

```bash
curl -X POST http://localhost:8765 \
  -H "Content-Type: application/json" \
  -d '{"action": "deckNames", "version": 6}'
```

### Import Deck

```bash
curl -X POST http://localhost:8765 \
  -H "Content-Type: application/json" \
  -d '{
    "action": "importPackage",
    "version": 6,
    "params": {
      "path": "/path/to/deck.apkg"
    }
  }'
```

## Development

### Building with Custom Versions

```bash
docker build \
  --build-arg ANKI_VERSION=25.07.5 \
  --build-arg ANKICONNECT_VERSION=23.10.29.0 \
  -t anki-headless:custom .
```

### Development Mode

Use the alternative docker-compose configuration for development:

```bash
# Create local directories
mkdir -p anki-data anki-media

# Use development configuration
docker-compose -f docker-compose.yml up -d
```

### Logs and Debugging

```bash
# View container logs
docker-compose logs -f anki-headless

# Access container shell
docker-compose exec anki-headless bash

# Check AnkiConnect status
docker-compose exec anki-headless curl http://localhost:8765
```

## File Structure

```
├── Dockerfile              # Multi-stage Docker build
├── docker-compose.yml      # Docker Compose configuration
├── start-anki.sh          # Container startup script
├── config.json            # AnkiConnect configuration
├── meta.json              # AnkiConnect metadata
└── README.md              # This file
```

## Troubleshooting

### Container Won't Start

1. Check logs: `docker-compose logs anki-headless`
2. Verify port availability: `netstat -tuln | grep 8765`
3. Check disk space for volumes

### AnkiConnect Not Responding

1. Verify container health: `docker-compose ps`
2. Test network connectivity: `docker-compose exec anki-headless curl localhost:8765`
3. Check AnkiConnect configuration in volume

### Import/Export Issues

1. Ensure proper file permissions on mounted volumes
2. Check available disk space
3. Verify file paths are accessible within container

### Memory Issues

1. Increase memory limit in docker-compose.yml
2. Monitor memory usage: `docker stats anki-headless`
3. Consider using swap if needed

## Security Considerations

- Container runs as non-root user (`anki`)
- Minimal system capabilities
- No new privileges allowed
- CORS configured for development (adjust for production)
- Consider adding authentication for production use

## Performance Optimization

- **Memory**: Default limit is 512MB, adjust based on collection size
- **CPU**: CPU shares set to 1024, modify for multi-container environments
- **Storage**: Use fast storage for better database performance
- **Network**: Use host networking for maximum performance if security allows

## Production Deployment

### Reverse Proxy Setup (Nginx)

```nginx
server {
    listen 80;
    server_name anki.example.com;
    
    location / {
        proxy_pass http://localhost:8765;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

### Docker Swarm Deployment

```yaml
version: '3.8'
services:
  anki-headless:
    image: anki-headless:latest
    deploy:
      replicas: 1
      resources:
        limits:
          memory: 512M
        reservations:
          memory: 256M
    ports:
      - "8765:8765"
    volumes:
      - anki_data:/home/anki/.local/share/Anki2
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is provided as-is for educational and development purposes. Please respect Anki and AnkiConnect licensing terms.

## Acknowledgments

- [Anki](https://apps.ankiweb.net/) - The fantastic spaced repetition software
- [AnkiConnect](https://foosoft.net/projects/anki-connect/) - The plugin that makes API access possible
- Community contributors and testers