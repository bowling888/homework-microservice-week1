#!/usr/bin/env bash
set -u

FIRST_NAME="${FIRST_NAME:-นิฤมล}"
LAST_NAME="${LAST_NAME:-ทดสอบ}"
NICK_NAME="${NICK_NAME:-Test}"
LANGUAGE_VALUE="${LANGUAGE_VALUE:-bash}"
LOG_FILE="${LOG_FILE:-/logs/bash.log}"

utc7_ts() {
  # Force timezone to UTC+7 without relying on system tzdata.
  # Etc/GMT-7 corresponds to UTC+7.
  local ts
  ts="$(TZ=Etc/GMT-7 date +'%Y-%m-%d %H:%M:%S')"
  echo "${ts} +07:00"
}

# Ensure log directory exists.
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true

read_line() {
  # Read a single line from stdin; strip trailing CR if present.
  if ! IFS= read -r line; then
    return 1
  fi
  printf "%s" "${line%$'\r'}"
  return 0
}

request_line="$(read_line || true)"
request_line="${request_line%$'\r'}"
method="${request_line%% *}"

# Consume headers until we reach an empty line.
while IFS= read -r hdr; do
  hdr="${hdr%$'\r'}"
  if [[ -z "$hdr" ]]; then
    break
  fi
done || true

if [[ "$method" == "GET" ]]; then
  body="{\"first_name\":\"${FIRST_NAME}\",\"last_name\":\"${LAST_NAME}\",\"nick_name\":\"${NICK_NAME}\",\"language\":\"${LANGUAGE_VALUE}\"}"
  # Content-Length must be in bytes (UTF-8 Thai chars are multi-byte).
  content_length="$(printf '%s' "$body" | wc -c)"

  printf "HTTP/1.1 200 OK\r\nContent-Type: application/json; charset=utf-8\r\nContent-Length: %s\r\n\r\n%s" "$content_length" "$body"
  printf "%s [bash] %s %s -> %s\n" "$(utc7_ts)" "$method" "/" "$body" >> "$LOG_FILE" || true
else
  printf "HTTP/1.1 405 Method Not Allowed\r\nContent-Length: 0\r\n\r\n"
fi

