FROM golang:1.21-alpine AS builder
RUN apk add --no-cache git
WORKDIR /src

COPY . .

ENV CGO_ENABLED=0 GOOS=linux GOARCH=amd64

RUN GOBIN=/out go install github.com/steipete/gogcli/cmd/gog@latest

RUN cd /src/server && go build -o /out/gws-server

FROM alpine:3.18
RUN apk add --no-cache bash curl

COPY --from=builder /out/gog /usr/local/bin/gog
COPY --from=builder /out/gws-server /usr/local/bin/gws-server
RUN chmod +x /usr/local/bin/gog /usr/local/bin/gws-server

RUN mkdir -p /root/.config/gogcli

EXPOSE 8080
USER 1000

ENTRYPOINT ["/usr/local/bin/gws-server"]
