<?php

declare(strict_types=1);

$firstName = getenv('FIRST_NAME') ?: 'นิฤมล';
$lastName = getenv('LAST_NAME') ?: 'ทดสอบ';
$nickName = getenv('NICK_NAME') ?: 'Test';
$languageValue = getenv('LANGUAGE_VALUE') ?: 'php';
$logFile = getenv('LOG_FILE') ?: '/logs/php.log';

// Ensure log directory exists (e.g. /logs mounted via docker volume).
$logDir = dirname($logFile);
if (!is_dir($logDir)) {
  @mkdir($logDir, 0777, true);
}

$payload = [
  'first_name' => $firstName,
  'last_name' => $lastName,
  'nick_name' => $nickName,
  'language' => $languageValue,
];

function utc7Timestamp(): string {
  $dt = new DateTime('now', new DateTimeZone('+07:00'));
  // e.g. 2026-03-20 23:42:08+07:00
  return $dt->format('Y-m-d H:i:sP');
}

if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'GET') {
  http_response_code(405);
  header('Content-Length: 0');
  exit;
}

$body = json_encode($payload, JSON_UNESCAPED_UNICODE);

try {
  $ts = utc7Timestamp();
  file_put_contents($logFile, "{$ts} [php] {$_SERVER['REQUEST_METHOD']} {$_SERVER['REQUEST_URI']} -> {$body}\n", FILE_APPEND | LOCK_EX);
} catch (Throwable $e) {
  // ignore logging failures
}

header('Content-Type: application/json; charset=utf-8');
http_response_code(200);
echo $body;
