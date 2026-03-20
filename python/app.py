import json
import os
from datetime import datetime, timedelta, timezone
from flask import Flask, Response, request

app = Flask(__name__)

FIRST_NAME = os.environ.get("FIRST_NAME", "นิฤมล")
LAST_NAME = os.environ.get("LAST_NAME", "ทดสอบ")
NICK_NAME = os.environ.get("NICK_NAME", "Test")
LANGUAGE_VALUE = os.environ.get("LANGUAGE_VALUE", "python")
LOG_FILE = os.environ.get("LOG_FILE", "/logs/python.log")

payload = {
    "first_name": FIRST_NAME,
    "last_name": LAST_NAME,
    "nick_name": NICK_NAME,
    "language": LANGUAGE_VALUE,
}


def log_line(line: str) -> None:
    try:
        dir_path = os.path.dirname(LOG_FILE)
        if dir_path:
            os.makedirs(dir_path, exist_ok=True)
        dt = datetime.now(timezone(timedelta(hours=7)))
        ts = dt.strftime("%Y-%m-%d %H:%M:%S.%f")[:-3] + " +07:00"
        with open(LOG_FILE, "a", encoding="utf-8") as f:
            f.write(f"{ts} {line}\n")
    except Exception:
        pass


@app.get("/")
def root():
    body = json.dumps(payload, ensure_ascii=False)
    log_line(f"[python] {request.method} {request.path} -> {body}")
    return Response(body, status=200, content_type="application/json; charset=utf-8")


if __name__ == "__main__":
    # Note: Flask dev server; inside Docker it's fine for a demo.
    app.run(host="0.0.0.0", port=8080)

