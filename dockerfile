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
