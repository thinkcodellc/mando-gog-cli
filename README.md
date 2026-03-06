## googleworkspace CLI Railway Deployment

This repository provides a minimal HTTP wrapper that runs the official Google Workspace CLI (`gws`) inside a container and keeps the container always on. Use the `/run` HTTP endpoint to execute `gws` commands remotely.

Important: do NOT commit service account JSON to the repo. Store it as a Railway secret named `GSA_JSON`.

Usage

- POST /run with JSON body: `{ "args": ["users", "list", "--format=json"] }`
- Or GET /run?arg=users&arg=list

Examples

Run locally (mount a service account file):

```bash
docker build -t gws-railway .
docker run --rm -e PORT=8080 -e GSA_JSON="$(cat service-account.json | sed 's/"/\\"/g')" -p 8080:8080 gws-railway
```

Then call:

```bash
curl -X POST http://localhost:8080/run -d '{"args":["users","list","--format=json"]}' -H 'Content-Type: application/json'
```

Railway configuration

Set the following Railway environment variables for your service:

- `GSA_JSON` — full service account JSON contents (paste into Railway secret)
- `PORT` — service port (default `8080`)

Railway build

The repository uses `Dockerfile` (multi-stage) to build the `gws` binary from https://github.com/googleworkspace/cli and the small HTTP wrapper server.

Security

- Store service account JSON in Railway secrets only.
- Grant the service account the least-privilege roles required for the CLI operations you will run.

Notes

- The container runs an always-on HTTP service; each `/run` request executes `gws` and returns its stdout/stderr.
- For scheduled tasks, use Railway cron or an external scheduler to POST `/run` to the service.
