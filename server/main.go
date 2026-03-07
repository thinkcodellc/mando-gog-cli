package main

import (
    "context"
    "encoding/json"
    "io"
    "log"
    "net/http"
    "os"
    "os/exec"
    "time"
)

type RunRequest struct {
    Args []string `json:"args"`
}

func writeServiceAccount() {
    sa := os.Getenv("GSA_JSON")
    if sa == "" {
        return
    }
    _ = os.MkdirAll("/secrets", 0700)
    _ = os.WriteFile("/secrets/sa.json", []byte(sa), 0600)
    _ = os.Setenv("GOOGLE_APPLICATION_CREDENTIALS", "/secrets/sa.json")
}

func runHandler(w http.ResponseWriter, r *http.Request) {
    var req RunRequest
    if r.Method == http.MethodPost {
        defer r.Body.Close()
        body, err := io.ReadAll(r.Body)
        if err != nil {
            http.Error(w, "failed to read body: "+err.Error(), http.StatusBadRequest)
            return
        }
        if err := json.Unmarshal(body, &req); err != nil {
            http.Error(w, "invalid json: "+err.Error(), http.StatusBadRequest)
            return
        }
    } else {
        // support query args: ?arg=users&arg=list
        qs := r.URL.Query()["arg"]
        if len(qs) == 0 {
            http.Error(w, "no args provided; use POST {\"args\": [...] } or ?arg=...", http.StatusBadRequest)
            return
        }
        req.Args = qs
    }

    if len(req.Args) == 0 {
        http.Error(w, "no args", http.StatusBadRequest)
        return
    }

    ctx, cancel := context.WithTimeout(r.Context(), 2*time.Minute)
    defer cancel()

    cmd := exec.CommandContext(ctx, "gog", req.Args...)
    out, err := cmd.CombinedOutput()
    w.Header().Set("Content-Type", "application/json")
    if err != nil {
        w.WriteHeader(http.StatusInternalServerError)
        w.Write(out)
        return
    }
    w.WriteHeader(http.StatusOK)
    w.Write(out)
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
    w.WriteHeader(http.StatusOK)
    w.Write([]byte("OK"))
}

func main() {
    writeServiceAccount()

    port := os.Getenv("PORT")
    if port == "" {
        port = "8080"
    }

    mux := http.NewServeMux()
    mux.HandleFunc("/health", healthHandler)
    mux.HandleFunc("/run", runHandler)

    srv := &http.Server{
        Addr:         ":" + port,
        Handler:      mux,
        ReadTimeout:  10 * time.Second,
        WriteTimeout: 120 * time.Second,
        IdleTimeout:  120 * time.Second,
    }

    log.Printf("gws server listening on %s", srv.Addr)
    if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
        log.Fatalf("server failed: %v", err)
    }
}
