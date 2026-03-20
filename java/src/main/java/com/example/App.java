package com.example;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpServer;

import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.logging.FileHandler;
import java.util.logging.Logger;
import java.util.logging.Formatter;
import java.util.logging.LogRecord;

import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;

public class App {
    private static final Logger logger = Logger.getLogger("java_service");

    private static String env(String key, String defaultValue) {
        String v = System.getenv(key);
        return (v == null || v.isBlank()) ? defaultValue : v;
    }

    private static String jsonEscape(String s) {
        // Minimal escaping for safe JSON string output.
        return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "\\r");
    }

    private static void setupLogger(String logFile) throws IOException {
        logger.setUseParentHandlers(false);
        if (logger.getHandlers().length > 0) return;

        java.io.File logPath = new java.io.File(logFile);
        java.io.File parent = logPath.getParentFile();
        if (parent != null) parent.mkdirs();

        FileHandler fileHandler = new FileHandler(logFile, true);
        fileHandler.setFormatter(new UtcPlus7Formatter());
        logger.addHandler(fileHandler);
        logger.setLevel(java.util.logging.Level.INFO);
    }

    private static class UtcPlus7Formatter extends Formatter {
        private static final DateTimeFormatter FMT =
                DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss.SSS XXX");

        @Override
        public String format(LogRecord record) {
            Instant instant = Instant.ofEpochMilli(record.getMillis());
            OffsetDateTime dt = instant.atOffset(ZoneOffset.ofHours(7));
            String ts = dt.format(FMT); // e.g. 2026-03-20 23:42:08.123 +07:00
            return ts + " " + record.getMessage() + System.lineSeparator();
        }
    }

    private static class RootHandler implements HttpHandler {
        private final String firstName;
        private final String lastName;
        private final String nickName;
        private final String languageValue;

        RootHandler(String firstName, String lastName, String nickName, String languageValue) {
            this.firstName = firstName;
            this.lastName = lastName;
            this.nickName = nickName;
            this.languageValue = languageValue;
        }

        @Override
        public void handle(HttpExchange exchange) throws IOException {
            if (!"GET".equals(exchange.getRequestMethod())) {
                exchange.sendResponseHeaders(405, -1);
                return;
            }

            String json = "{"
                    + "\"first_name\":\"" + jsonEscape(firstName) + "\","
                    + "\"last_name\":\"" + jsonEscape(lastName) + "\","
                    + "\"nick_name\":\"" + jsonEscape(nickName) + "\","
                    + "\"language\":\"" + jsonEscape(languageValue) + "\""
                    + "}";

            logger.info("GET / -> " + json);

            byte[] bytes = json.getBytes(StandardCharsets.UTF_8);
            exchange.getResponseHeaders().set("Content-Type", "application/json; charset=utf-8");
            exchange.sendResponseHeaders(200, bytes.length);
            try (OutputStream os = exchange.getResponseBody()) {
                os.write(bytes);
            }
        }
    }

    public static void main(String[] args) throws Exception {
        String firstName = env("FIRST_NAME", "นิฤมล");
        String lastName = env("LAST_NAME", "ทดสอบ");
        String nickName = env("NICK_NAME", "Test");
        String languageValue = env("LANGUAGE_VALUE", "java");
        String logFile = env("LOG_FILE", "/logs/java.log");

        setupLogger(logFile);

        HttpServer server = HttpServer.create(new InetSocketAddress(8080), 0);
        server.createContext("/", new RootHandler(firstName, lastName, nickName, languageValue));
        server.setExecutor(null); // default executor
        server.start();

        logger.info("Java server started on http://0.0.0.0:8080");
    }
}

