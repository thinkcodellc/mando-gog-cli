# gogcli Railway Deployment

This repository contains the Docker configuration for deploying gogcli as a web service on Railway.

## Overview

This setup provides a REST API interface to execute gogcli commands via HTTP requests. The service automatically handles authentication using environment variables and persistent storage.

## Features

- **Secure Authentication**: Client secrets stored as Railway environment variables
- **Persistent Configuration**: Authentication tokens persist across container restarts
- **REST API Interface**: Execute gogcli commands via HTTP endpoints
- **Railway Optimized**: Pre-configured for Railway deployment with proper health checks

## API Usage

The service exposes a `/run` endpoint to execute gogcli commands:

```
GET /run?cmd=command&args=arg1&args=arg2
```

Example:
```
GET /run?cmd=list&args=owned
```

## Railway Configuration

### Environment Variables

Add the following environment variable to your Railway service:

- `GOG_CLIENT_SECRET_JSON`: Content of your `client_secret.json` file

### Persistent Volume

The service uses a persistent volume mounted at `/app/config` to store:
- `client_secret.json` (created from environment variable)
- Authentication tokens and configuration

## Setup Instructions

1. **Deploy to Railway**: Connect this repository to your Railway project
2. **Configure Environment**: Add `GOG_CLIENT_SECRET_JSON` environment variable
3. **Set Volume**: Ensure persistent volume is mounted at `/app/config`
4. **Test**: Make API requests to the `/run` endpoint

## Security Notes

- Never commit `client_secret.json` to the repository
- Use Railway environment variables for all sensitive configuration
- The service automatically handles authentication on startup
- Authentication tokens persist across container restarts via the persistent volume

## Docker Build

The Dockerfile uses a multi-stage build:
1. **Builder Stage**: Compiles the Go server
2. **Runtime Stage**: Creates minimal Alpine container with gogcli

## Health Checks

The service includes health check endpoints for Railway monitoring.