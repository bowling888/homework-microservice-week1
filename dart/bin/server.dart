import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

String env(String key, String defaultValue) {
  return Platform.environment[key] ?? defaultValue;
}

String utc7Timestamp() {
  final dt = DateTime.now().toUtc().add(const Duration(hours: 7));
  String pad(int n) => n.toString().padLeft(2, '0');
  final ms = dt.millisecond.toString().padLeft(3, '0');
  return '${dt.year}-${pad(dt.month)}-${pad(dt.day)} ${pad(dt.hour)}:${pad(dt.minute)}:${pad(dt.second)}.$ms +07:00';
}

Future<void> logLine(String logFile, String line) async {
  final file = File(logFile);
  // Ensure parent folder exists (e.g. /logs mounted via docker volume).
  await file.parent.create(recursive: true);
  final ts = utc7Timestamp();
  await file.writeAsString('$ts $line\n', mode: FileMode.append, encoding: utf8);
}

void main(List<String> args) async {
  final firstName = env('FIRST_NAME', 'นิฤมล');
  final lastName = env('LAST_NAME', 'ทดสอบ');
  final nickName = env('NICK_NAME', 'Test');
  final languageValue = env('LANGUAGE_VALUE', 'dart');
  final logFile = env('LOG_FILE', '/logs/dart.log');

  final router = Router()
    ..get('/', (Request request) async {
      final payload = <String, String>{
        'first_name': firstName,
        'last_name': lastName,
        'nick_name': nickName,
        'language': languageValue,
      };

      final jsonBody = jsonEncode(payload);

      await logLine(logFile, '[dart] GET / -> $jsonBody');

      return Response.ok(
        jsonBody,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
      );
    });

  final handler = const Pipeline().addMiddleware(logRequests()).addHandler(router);

  final port = 8080;
  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
  // Best-effort startup log to stdout.
  stdout.writeln('Dart server started on http://0.0.0.0:$port');
  await server;
}

Middleware logRequests() {
  return (innerHandler) {
    return (Request request) async {
      final response = await innerHandler(request);
      return response;
    };
  };
}

