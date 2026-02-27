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

ENV GOG_CONFIG_DIR=/app/config
EXPOSE 8080
CMD ["/server"]