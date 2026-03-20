package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"time"
)

type Payload struct {
	FirstName string `json:"first_name"`
	LastName  string `json:"last_name"`
	NickName  string `json:"nick_name"`
	Language  string `json:"language"`
}

func getenv(key, def string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return def
}

func main() {
	firstName := getenv("FIRST_NAME", "นิฤมล")
	lastName := getenv("LAST_NAME", "ทดสอบ")
	nickName := getenv("NICK_NAME", "Test")
	language := getenv("LANGUAGE_VALUE", "go")
	logFile := getenv("LOG_FILE", "/logs/go.log")

	// Ensure log directory exists (e.g. /logs mounted via docker volume).
	_ = os.MkdirAll(filepath.Dir(logFile), 0o755)

	logWriter, err := os.OpenFile(logFile, os.O_CREATE|os.O_APPEND|os.O_WRONLY, 0o644)
	if err != nil {
		log.Printf("failed to open log file %s: %v", logFile, err)
	} else {
		// We'll write our own timestamped lines into logWriter.
	}

	payload := Payload{
		FirstName: firstName,
		LastName:  lastName,
		NickName:  nickName,
		Language:  language,
	}

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			w.WriteHeader(http.StatusMethodNotAllowed)
			return
		}

		b, _ := json.Marshal(payload)
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write(b)

		if logWriter != nil {
			fmt.Fprintf(logWriter, "%s [go] %s %s -> %s\n", utc7Timestamp(), r.Method, r.URL.Path, string(b))
		}
	})

	srv := &http.Server{
		Addr:              ":8080",
		ReadHeaderTimeout: 5 * time.Second,
	}

	if logWriter != nil {
		fmt.Fprintf(logWriter, "%s [go] Go server started on http://0.0.0.0:8080\n", utc7Timestamp())
	}
	log.Fatal(srv.ListenAndServe())
}

func utc7Timestamp() string {
	loc := time.FixedZone("UTC+7", 7*3600)
	t := time.Now().In(loc)
	// Example: 2026-03-20 23:42:08.379 +07:00
	return t.Format("2006-01-02 15:04:05.000 -07:00")
}

