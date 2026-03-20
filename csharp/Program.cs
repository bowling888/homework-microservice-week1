using System.Net;
using System.Net.Sockets;
using System.IO;
using System.Globalization;
using System.Text;
using System.Text.Json;

static void LogLine(string logFile, string line)
{
    try
    {
        // Ensure the log directory exists (e.g. mounted /logs volume).
        var dir = Path.GetDirectoryName(logFile);
        if (!string.IsNullOrWhiteSpace(dir))
            Directory.CreateDirectory(dir);

        // Write datetime in UTC+7 for consistent local debugging.
        var utcPlus7 = DateTimeOffset.UtcNow.ToOffset(TimeSpan.FromHours(7));
        var ts = utcPlus7.ToString("yyyy-MM-dd HH:mm:ss.fff zzz", CultureInfo.InvariantCulture);

        File.AppendAllText(logFile, $"{ts} {line}{Environment.NewLine}", Encoding.UTF8);
    }
    catch
    {
        // Best-effort logging: don't crash the server if logging fails.
        Console.Error.WriteLine($"[csharp] failed to write log file '{logFile}'");
    }

    // Always print to stdout so `docker compose logs csharp` can show startup/errors.
    Console.WriteLine(line);
}

static string Env(string key, string fallback) =>
    Environment.GetEnvironmentVariable(key) ?? fallback;

static async Task HandleClientAsync(
    TcpClient client,
    string firstName,
    string lastName,
    string nickName,
    string languageValue,
    string logFile)
{
    using (client)
    {
        client.ReceiveTimeout = 5000;
        using var stream = client.GetStream();

        // Read request headers until we reach an empty line.
        var buffer = new byte[4096];
        var headerBuilder = new StringBuilder();

        while (true)
        {
            int read;
            try
            {
                read = await stream.ReadAsync(buffer);
            }
            catch
            {
                return;
            }

            if (read <= 0) return;

            headerBuilder.Append(Encoding.UTF8.GetString(buffer, 0, read));

            var s = headerBuilder.ToString();
            if (s.Contains("\r\n\r\n") || s.Contains("\n\n")) break;

            // Avoid unlimited growth on malformed requests.
            if (headerBuilder.Length > 16_384) return;
        }

        var headers = headerBuilder.ToString();
        var firstLine = headers.Split(new[] { "\r\n", "\n" }, StringSplitOptions.None)[0];
        var parts = firstLine.Split(' ', StringSplitOptions.RemoveEmptyEntries);

        var httpMethod = parts.Length > 0 ? parts[0] : "";
        var path = parts.Length > 1 ? parts[1] : "";

        var payload = new
        {
            first_name = firstName,
            last_name = lastName,
            nick_name = nickName,
            language = languageValue
        };

        var bodyString = JsonSerializer.Serialize(payload);
        var bodyBytes = Encoding.UTF8.GetBytes(bodyString);

        if (string.Equals(httpMethod, "GET", StringComparison.OrdinalIgnoreCase) && path == "/")
        {
            LogLine(logFile, $"[csharp] GET / -> {bodyString}");

            var response =
                "HTTP/1.1 200 OK\r\n" +
                "Content-Type: application/json; charset=utf-8\r\n" +
                $"Content-Length: {bodyBytes.Length}\r\n" +
                "Connection: close\r\n" +
                "\r\n";

            var responseBytes = Encoding.UTF8.GetBytes(response);
            await stream.WriteAsync(responseBytes);
            await stream.WriteAsync(bodyBytes);
        }
        else
        {
            LogLine(logFile, $"[csharp] {httpMethod} {path} -> 405");

            var response =
                "HTTP/1.1 405 Method Not Allowed\r\n" +
                "Content-Length: 0\r\n" +
                "Connection: close\r\n" +
                "\r\n";

            var responseBytes = Encoding.UTF8.GetBytes(response);
            await stream.WriteAsync(responseBytes);
        }
    }
}

var firstName = Env("FIRST_NAME", "นิฤมล");
var lastName = Env("LAST_NAME", "ทดสอบ");
var nickName = Env("NICK_NAME", "Test");
var languageValue = Env("LANGUAGE_VALUE", "csharp");
var logFile = Env("LOG_FILE", "/logs/csharp.log");

var port = 8080;
var listener = new TcpListener(IPAddress.Any, port);
listener.Start();

LogLine(logFile, $"[csharp] startup. TcpListener listening on :{port}");

while (true)
{
    var client = await listener.AcceptTcpClientAsync();
    _ = Task.Run(() => HandleClientAsync(client, firstName, lastName, nickName, languageValue, logFile));
}

