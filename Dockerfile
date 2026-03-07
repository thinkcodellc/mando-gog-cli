# gogcli Docker container - downloads pre-built binary from GitHub releases
FROM golang:1.21-alpine AS builder
RUN apk add --no-cache git
WORKDIR /src

COPY server/main.go /src/server/main.go

ENV CGO_ENABLED=0 GOOS=linux GOARCH=amd64 GOTOOLCHAIN=auto

RUN go build -o /out/gws-server

FROM alpine:3.18
RUN apk add --no-cache bash curl ca-certificates

RUN curl -fsSL https://github.com/steipete/gogcli/releases/download/v0.11.0/gogcli_0.11.0_linux_amd64.tar.gz | tar -xz -C /usr/local/bin && \
    chmod +x /usr/local/bin/gog

COPY --from=builder /out/gws-server /gws-server
RUN chmod +x /gws-server

RUN mkdir -p /root/.config/gogcli

EXPOSE 8080
USER 1000

ENTRYPOINT ["/gws-server"]
