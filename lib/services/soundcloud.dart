import 'dart:convert';
import 'package:http/http.dart' as http;

class ScTrack {
  final int id;
  final String title;
  final String user;
  final String? artworkUrl;
  final int durationMs;
  final List<ScTranscoding> transcodings;
  final String permalinkUrl;

  ScTrack({
    required this.id,
    required this.title,
    required this.user,
    required this.artworkUrl,
    required this.durationMs,
    required this.transcodings,
    required this.permalinkUrl,
  });

  factory ScTrack.fromJson(Map<String, dynamic> j) {
    final transList = <ScTranscoding>[];
    final media = j['media'];
    if (media is Map && media['transcodings'] is List) {
      for (final t in media['transcodings']) {
        if (t is Map) {
          final fmt = t['format'];
          transList.add(ScTranscoding(
            url: t['url']?.toString() ?? '',
            protocol: (fmt is Map ? fmt['protocol'] : '')?.toString() ?? '',
            mimeType: (fmt is Map ? fmt['mime_type'] : '')?.toString() ?? '',
          ));
        }
      }
    }
    return ScTrack(
      id: (j['id'] is int) ? j['id'] : int.tryParse('${j['id']}') ?? 0,
      title: j['title']?.toString() ?? 'Без названия',
      user: (j['user'] is Map ? j['user']['username'] : '')?.toString() ?? '',
      artworkUrl: j['artwork_url']?.toString(),
      durationMs: (j['duration'] is int)
          ? j['duration']
          : int.tryParse('${j['duration']}') ?? 0,
      transcodings: transList,
      permalinkUrl: j['permalink_url']?.toString() ?? '',
    );
  }

  String get artworkLarge {
    final a = artworkUrl;
    if (a == null || a.isEmpty) return '';
    return a.replaceAll('-large', '-t300x300');
  }
}

class ScTranscoding {
  final String url;
  final String protocol;
  final String mimeType;
  ScTranscoding({
    required this.url,
    required this.protocol,
    required this.mimeType,
  });
}

class SoundcloudService {
  static String? _clientId;

  static Future<String?> _resolveClientId() async {
    if (_clientId != null) return _clientId;
    try {
      final res = await http.get(Uri.parse('https://soundcloud.com/discover'));
      if (res.statusCode != 200) return null;
      final body = res.body;
      final scripts = RegExp(r'<script[^>]+src="(https?://[^"]+sndcdn\.com[^"]+\.js)"')
          .allMatches(body)
          .map((m) => m.group(1)!)
          .toList();
      for (final url in scripts.reversed) {
        try {
          final s = await http.get(Uri.parse(url));
          if (s.statusCode != 200) continue;
          final m = RegExp(r'client_id\s*[:=]\s*"([a-zA-Z0-9]{20,40})"')
              .firstMatch(s.body);
          if (m != null) {
            _clientId = m.group(1);
            return _clientId;
          }
        } catch (_) {}
      }
    } catch (_) {}
    return null;
  }

  static Future<List<ScTrack>> search(String query) async {
    if (query.trim().isEmpty) return [];
    final cid = await _resolveClientId();
    if (cid == null) {
      throw Exception('Не удалось получить client_id SoundCloud');
    }
    final uri = Uri.parse(
        'https://api-v2.soundcloud.com/search/tracks?q=${Uri.encodeQueryComponent(query)}&client_id=$cid&limit=25');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Search failed: ${res.statusCode}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (data['collection'] as List?) ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .where((j) => j['kind'] == 'track')
        .map(ScTrack.fromJson)
        .toList();
  }

  /// Returns a direct mp3/HLS URL for the track. Prefers progressive mp3.
  static Future<String?> getStreamUrl(ScTrack track) async {
    final cid = await _resolveClientId();
    if (cid == null) return null;
    // Prefer progressive mp3 over HLS
    ScTranscoding? best;
    for (final t in track.transcodings) {
      if (t.protocol == 'progressive' && t.mimeType.contains('mpeg')) {
        best = t;
        break;
      }
    }
    best ??= track.transcodings.isNotEmpty ? track.transcodings.first : null;
    if (best == null || best.url.isEmpty) return null;
    final url = best.url.contains('?')
        ? '${best.url}&client_id=$cid'
        : '${best.url}?client_id=$cid';
    final res = await http.get(Uri.parse(url));
    if (res.statusCode != 200) return null;
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    return j['url']?.toString();
  }
}
