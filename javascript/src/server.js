import express from "express";
import fs from "fs";
import path from "path";

function utc7Now() {
  // Create a "shifted" Date, then use UTC getters for stable formatting.
  const d = new Date(Date.now() + 7 * 60 * 60 * 1000);
  const pad = (n) => String(n).padStart(2, "0");
  const ms = String(d.getUTCMilliseconds()).padStart(3, "0");
  return `${d.getUTCFullYear()}-${pad(d.getUTCMonth() + 1)}-${pad(d.getUTCDate())} ${pad(d.getUTCHours())}:${pad(d.getUTCMinutes())}:${pad(d.getUTCSeconds())}.${ms} +07:00`;
}

const firstName = process.env.FIRST_NAME || "นิฤมล";
const lastName = process.env.LAST_NAME || "ทดสอบ";
const nickName = process.env.NICK_NAME || "Test";
const languageValue = process.env.LANGUAGE_VALUE || "javascript";
const logFile = process.env.LOG_FILE || "/logs/javascript.log";

// Ensure log directory exists (e.g. /logs mounted via docker volume).
try {
  fs.mkdirSync(path.dirname(logFile), { recursive: true });
} catch (_) {}

const payload = {
  first_name: firstName,
  last_name: lastName,
  nick_name: nickName,
  language: languageValue,
};

const app = express();

app.get("/", (req, res) => {
  const body = JSON.stringify(payload);
  try {
    fs.appendFileSync(logFile, `${utc7Now()} [javascript] ${req.method} / -> ${body}\n`);
  } catch (_) {
    // If log file can't be written, still respond.
  }

  res.status(200);
  res.set("Content-Type", "application/json; charset=utf-8");
  res.send(body);
});

const port = 8080;
app.listen(port, "0.0.0.0", () => {
  // Best-effort startup log to stdout.
  console.log(`JavaScript server started on http://0.0.0.0:${port}`);
});

