FROM golang:1.21-alpine AS builder
RUN apk add --no-cache git
WORKDIR /src

# Copy repository files (server source lives in ./server)
COPY . .

ENV CGO_ENABLED=0 GOOS=linux GOARCH=amd64

# Build googleworkspace/cli (gws) from upstream
RUN git clone --depth 1 https://github.com/googleworkspace/cli.git /tmp/gws \
    && cd /tmp/gws/cmd/gws \
    && go build -o /out/gws

# Build the local HTTP wrapper server
RUN cd /src/server && go build -o /out/gws-server

FROM alpine:3.18
RUN apk add --no-cache ca-certificates bash

# Copy binaries from builder
COPY --from=builder /out/gws /usr/local/bin/gws
COPY --from=builder /out/gws-server /usr/local/bin/gws-server
RUN chmod +x /usr/local/bin/gws /usr/local/bin/gws-server

RUN mkdir -p /secrets
ENV GOOGLE_APPLICATION_CREDENTIALS=/secrets/sa.json

EXPOSE 8080
USER 1000

# Run the persistent HTTP wrapper service
ENTRYPOINT ["/usr/local/bin/gws-server"]
FROM golang:1.21-alpine AS builder
WORKDIR /app
# A tiny Go server to execute gog commands
RUN echo 'package main; import ("net/http"; "os/exec"; "fmt"); func main() { http.HandleFunc("/run", func(w http.ResponseWriter, r *http.Request) { cmd := r.URL.Query().Get("cmd"); args := r.URL.Query()["args"]; out, err := exec.Command("gog", append([]string{cmd}, args...)...).CombinedOutput(); if err != nil { http.Error(w, string(out), 500); return }; fmt.Fprint(w, string(out)) }); http.ListenAndServe(":8080", nil) }' > main.go
RUN go build -o server main.go

FROM alpine:latest
RUN apk add --no-cache curl ca-certificates tar

# Install gogcli
RUN curl -L https://github.com/steipete/gogcli/releases/latest/download/gog_Linux_x86_64.tar.gz | tar xz -C /usr/local/bin

COPY --from=builder /app/server /server

# Configuration environment variables
ENV GOG_CONFIG_DIR=/app/config

# This entrypoint script creates the secret file from the environment variable 
# and then registers it with gog before starting the server.
ENTRYPOINT ["sh", "-c", "mkdir -p $GOG_CONFIG_DIR && echo \"$GOG_CLIENT_SECRET_JSON\" > $GOG_CONFIG_DIR/client_secret.json && gog auth credentials $GOG_CONFIG_DIR/client_secret.json && /server"]

EXPOSE 8080
