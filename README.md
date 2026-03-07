# gogcli Railway Deployment

This repository provides a minimal HTTP wrapper that runs [gogcli](https://github.com/steipete/gogcli) (Google Workspace CLI) inside a container and keeps it always-on. Use the `/run` HTTP endpoint to execute `gog` commands remotely.

## Quick Start

### Railway Setup

1. **Create a Railway project** (or use existing)
2. **Create a volume** for persistent credentials:
   - Click your project canvas → New → Volume
   - Name: `gogcli-config`
   - Size: 0.5GB (Free) or 5GB (Hobby)
3. **Create a service** from this repository:
   - New → GitHub Repo → Select this repo
4. **Mount the volume** to the service:
   - Go to Service → Settings → Volumes
   - Mount Path: `/root/.config/gogcli`
5. **Set environment variables**:
   - `GOG_KEYRING_BACKEND` = `file`
   - `GOG_ACCOUNT` = your Gmail address (e.g., `jari.edo@gmail.com`)

### Post-Deployment Authentication

Since Railway has no browser, you need to authenticate via the manual OAuth flow:

1. **Shell into the container**:
   - Service → Shell (or use Railway CLI: `railway run`)

2. **Store OAuth credentials**:
   ```bash
   # Create OAuth client JSON file (from Google Cloud Console)
   cat > /tmp/oauth-client.json << 'EOF'
   {
     "installed": {
       "client_id": "YOUR_CLIENT_ID.apps.googleusercontent.com",
       "client_secret": "YOUR_CLIENT_SECRET",
       "redirect_uris": ["http://localhost"]
     }
   }
   EOF
   
   gog auth credentials /tmp/oauth-client.json
   ```

3. **Start OAuth flow**:
   ```bash
   gog auth add jari.edo@gmail.com --services gmail,calendar,drive --manual
   ```
   
   This will output a URL like:
   ```
   Visit this URL to authorize: https://accounts.google.com/o/oauth2/auth?client_id=...
   ```

4. **Authorize in your browser**:
   - Copy the URL to your local browser
   - Log in and authorize
   - After authorization, browser redirects to `http://127.0.0.1:8080/oauth2/callback?code=...&state=...`
   - Copy the **entire redirect URL** from browser address bar

5. **Complete auth in container**:
   ```bash
   # Replace with your actual redirect URL
   gog auth add jari.edo@gmail.com --manual --auth-url 'http://127.0.0.1:8080/oauth2/callback?code=XXX&state=YYY'
   ```

6. **Verify**:
   ```bash
   gog gmail labels list
   gog calendar calendars
   ```

7. **Restart the service** - Tokens are now saved to the volume and will persist.

## Usage

### HTTP API

**POST /run** (recommended):
```bash
curl -X POST http://localhost:8080/run \
  -H 'Content-Type: application/json' \
  -d '{"args": ["gmail", "labels", "list"]}'
```

**GET /run**:
```bash
curl 'http://localhost:8080/run?arg=gmail&arg=labels&arg=list'
```

### Example Commands

| Action | Command |
|--------|---------|
| List Gmail labels | `gmail labels list` |
| Search emails | `gmail search "is:unread newer_than:1d"` |
| List calendars | `calendar calendars` |
| Today's events | `calendar events primary --today` |
| List Drive files | `drive ls` |
| Search Drive | `drive search "filename"` |

### OpenClaw Integration

In OpenClaw, create a skill or use HTTP to call this service:

```javascript
// Example: Call gogcli from OpenClaw
const response = await fetch('https://your-service.railway.app/run', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    args: ['gmail', 'search', 'is:unread']
  })
});
const result = await response.json();
```

## Security

- Store OAuth credentials as Railway secrets if embedding
- Tokens are stored in volume at `/root/.config/gogcli`
- Use `--readonly` flag for limited access: `gog auth add email --readonly`

## Local Development

```bash
# Build
docker build -t gogcli .

# Run with volume mount
docker run -p 8080:8080 -v $(pwd)/config:/root/.config/gogcli gogcli

# Test
curl -X POST http://localhost:8080/run \
  -H 'Content-Type: application/json' \
  -d '{"args": ["gmail", "labels", "list"]}'
```
