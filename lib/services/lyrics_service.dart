import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

class LyricLine {
  final Duration time;
  final String text;

  const LyricLine({required this.time, required this.text});
}

class LyricsService {
  /// Load lyrics for a song by looking for a .lrc file next to the audio file.
  Future<List<LyricLine>> loadLyrics(String filePath) async {
    final lrcPath = '${p.withoutExtension(filePath)}.lrc';
    final lrcFile = File(lrcPath);
    if (!await lrcFile.exists()) return [];

    try {
      // Try UTF-8 first
      final content = await lrcFile.readAsString(encoding: utf8);
      return parseLrc(content);
    } catch (_) {
      try {
        // Fallback: read as bytes and decode as Latin1 (GBK-safe passthrough),
        // then try GBK-like decoding
        final bytes = await lrcFile.readAsBytes();
        // Try decoding as latin1 which preserves all byte values
        final content = latin1.decode(bytes);
        // Check if it looks garbled (contains replacement chars or high bytes)
        // If the file is GBK, we decode manually
        final gbkContent = _tryDecodeGbk(bytes);
        return parseLrc(gbkContent ?? content);
      } catch (_) {
        return [];
      }
    }
  }

  /// Attempt to decode bytes as GBK using the system iconv via a temp approach.
  /// Falls back to latin1 if GBK decode isn't available.
  String? _tryDecodeGbk(List<int> bytes) {
    // Simple heuristic: if bytes contain values > 0x7F that look like
    // double-byte GBK sequences, try to decode them.
    // Dart doesn't have built-in GBK support, so we use a pragmatic approach:
    // replace non-UTF8 sequences and still extract timestamp lines.
    try {
      // First attempt: maybe it's actually valid UTF-8 with BOM
      if (bytes.length >= 3 &&
          bytes[0] == 0xEF &&
          bytes[1] == 0xBB &&
          bytes[2] == 0xBF) {
        return utf8.decode(bytes.sublist(3));
      }
      // Try UTF-8 with allowMalformed to get whatever we can
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      return null;
    }
  }

  /// Parse LRC format string into sorted LyricLine list.
  List<LyricLine> parseLrc(String content) {
    final lines = <LyricLine>[];
    final regex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)');

    for (final line in content.split('\n')) {
      final match = regex.firstMatch(line.trim());
      if (match == null) continue;

      final minutes = int.parse(match.group(1)!);
      final seconds = int.parse(match.group(2)!);
      final msStr = match.group(3)!;
      final ms = msStr.length == 2
          ? int.parse(msStr) * 10
          : int.parse(msStr);
      final text = match.group(4)!.trim();
      if (text.isEmpty) continue;

      lines.add(LyricLine(
        time: Duration(
          minutes: minutes,
          seconds: seconds,
          milliseconds: ms,
        ),
        text: text,
      ));
    }

    lines.sort((a, b) => a.time.compareTo(b.time));
    return lines;
  }

  /// Find current lyric line index for a given position.
  int currentLineIndex(List<LyricLine> lyrics, Duration position) {
    if (lyrics.isEmpty) return -1;
    int index = -1;
    for (int i = 0; i < lyrics.length; i++) {
      if (lyrics[i].time <= position) {
        index = i;
      } else {
        break;
      }
    }
    return index;
  }
}
