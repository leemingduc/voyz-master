// tool/verify_image_urls.dart
//
// Quét mọi URL ảnh Wikimedia trong supabase/migrations/*.sql và kiểm chứng
// từng URL theo đúng điều kiện browser cần:
//   1. Trả 200 TRỰC TIẾP, không qua redirect. Browser kiểm CORS trên TỪNG
//      hop; Special:FilePath redirect từ commons.wikimedia.org (không có
//      ACAO header) nên chết trên web dù curl -L thấy 200.
//   2. Content-type phải là image/*.
//   3. Response phải có Access-Control-Allow-Origin (Flutter web CanvasKit
//      tải ảnh bằng fetch, không có ACAO là chặn).
// Chạy: dart run tool/verify_image_urls.dart
import 'dart:io';

import 'package:http/http.dart' as http;

final RegExp _urlPattern = RegExp(
  r'''https://(?:upload\.wikimedia\.org|commons\.wikimedia\.org)[^\s"'\\)]+''',
);

Future<void> main() async {
  final migrationDir = Directory('supabase/migrations');
  if (!migrationDir.existsSync()) {
    stderr.writeln('Run from repo root: supabase/migrations not found.');
    exitCode = 2;
    return;
  }

  final urls = <String>{};
  for (final entity in migrationDir.listSync()) {
    if (entity is File && entity.path.endsWith('.sql')) {
      final content = entity.readAsStringSync();
      for (final match in _urlPattern.allMatches(content)) {
        urls.add(match.group(0)!);
      }
    }
  }

  if (urls.isEmpty) {
    stdout.writeln('No Wikimedia image URLs found in migrations.');
    return;
  }

  var failures = 0;
  final client = http.Client();
  for (final url in urls) {
    // Wikimedia rate-limit burst request không có User-Agent (trả 429),
    // nên cần UA mô tả rõ + nghỉ ngắn giữa các request.
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    try {
      final request = http.Request('GET', Uri.parse(url))
        ..headers['User-Agent'] =
            'VoyzSeedImageVerifier/1.0 (student project; verify seed URLs)'
        ..headers['Origin'] = 'http://localhost:8080'
        ..followRedirects = false;
      final response =
          await client.send(request).timeout(const Duration(seconds: 20));
      final contentType = response.headers['content-type'] ?? '';
      final acao = response.headers['access-control-allow-origin'] ?? '';
      final problems = <String>[
        if (response.statusCode >= 300 && response.statusCode < 400)
          'redirect (browser CORS breaks on redirect hops)',
        if (response.statusCode == 200 && !contentType.startsWith('image/'))
          'not an image',
        if (response.statusCode == 200 && acao.isEmpty)
          'no Access-Control-Allow-Origin header',
      ];
      final ok = response.statusCode == 200 &&
          contentType.startsWith('image/') &&
          acao.isNotEmpty;
      stdout.writeln(
        '${ok ? 'OK  ' : 'FAIL'} ${response.statusCode} $contentType ACAO=$acao'
        '${problems.isEmpty ? '' : ' [${problems.join('; ')}]'}  $url',
      );
      if (!ok) failures++;
      await response.stream.drain<void>();
    } catch (error) {
      stdout.writeln('FAIL error  $url  ($error)');
      failures++;
    }
  }
  client.close();

  if (failures > 0) {
    stderr.writeln('\n$failures broken image URL(s). Fix before merging.');
    exitCode = 1;
  } else {
    stdout.writeln('\nAll ${urls.length} image URLs verified.');
  }
}
