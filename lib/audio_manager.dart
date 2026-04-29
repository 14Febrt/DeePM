import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class AudioManager extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final List<Track> tracks = [];
  int currentIdx = -1;
  bool isPlaying = false;
  bool isShuffle = false;
  bool isRepeat = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  bool _initialized = false;
  bool get initialized => _initialized;

  static const _prefsKey = 'user_tracks_v1';

  String? _docsPath;
  Track? _previewTrack;
  bool _inPreview = false;

  String _toRel(String abs) {
    final norm = abs.replaceAll('\\', '/');
    final docs = _docsPath?.replaceAll('\\', '/');
    if (docs != null && norm.startsWith(docs)) {
      return norm.substring(docs.length).replaceFirst(RegExp(r'^/'), '');
    }
    // Strip up to "Documents/" marker for legacy absolute paths.
    const marker = '/Documents/';
    final i = norm.indexOf(marker);
    if (i >= 0) return norm.substring(i + marker.length);
    return norm;
  }

  String _toAbs(String rel) {
    if (rel.startsWith('/') || RegExp(r'^[A-Za-z]:').hasMatch(rel)) {
      return rel;
    }
    final docs = _docsPath;
    if (docs == null) return rel;
    return '$docs/${rel.replaceAll('\\', '/')}';
  }

  Track? get currentTrack {
    if (_previewTrack != null) return _previewTrack;
    return currentIdx >= 0 && currentIdx < tracks.length
        ? tracks[currentIdx]
        : null;
  }

  AudioManager() {
    _init();
  }

  Future<void> _init() async {
    tracks.clear();
    _docsPath = (await getApplicationDocumentsDirectory()).path;
    await _loadUserTracks();
    await _rebuildPlaylist();

    _player.positionStream.listen((p) {
      position = p;
      notifyListeners();
    });
    _player.durationStream.listen((d) {
      duration = d ?? Duration.zero;
      notifyListeners();
    });
    _player.playerStateStream.listen((state) {
      isPlaying = state.playing;
      notifyListeners();
    });
    _player.currentIndexStream.listen((idx) {
      if (idx != null && !_inPreview) {
        currentIdx = idx;
        notifyListeners();
      }
    });

    _initialized = true;
    notifyListeners();
  }

  Future<void> _loadUserTracks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    try {
      final List<dynamic> arr = jsonDecode(raw);
      for (final j in arr) {
        final stored = Track.fromJson(j as Map<String, dynamic>);
        // Resolve potentially-relative paths to absolute (current sandbox).
        final absSrc = stored.isAsset ? stored.src : _toAbs(stored.src);
        String? absArt;
        if (stored.artworkPath != null && stored.artworkPath!.isNotEmpty) {
          absArt = _toAbs(stored.artworkPath!);
          if (!File(absArt).existsSync()) absArt = null;
        }
        // skip if media file no longer exists
        if (!stored.isAsset && !File(absSrc).existsSync()) continue;
        tracks.add(Track(
          title: stored.title,
          artist: stored.artist,
          src: absSrc,
          isAsset: stored.isAsset,
          artworkPath: absArt,
        ));
      }
    } catch (_) {}
  }

  Future<void> _saveUserTracks() async {
    final prefs = await SharedPreferences.getInstance();
    final user = tracks.where((t) => !t.isAsset).map((t) {
      return {
        'title': t.title,
        'artist': t.artist,
        'src': _toRel(t.src),
        'isAsset': t.isAsset,
        'artworkPath':
            (t.artworkPath != null && t.artworkPath!.isNotEmpty)
                ? _toRel(t.artworkPath!)
                : null,
      };
    }).toList();
    await prefs.setString(_prefsKey, jsonEncode(user));
  }

  Future<void> _rebuildPlaylist() async {
    final wasPlaying = _player.playing;
    final savedIdx = currentIdx;
    final savedPos = position;

    if (tracks.isEmpty) {
      await _player.stop();
      currentIdx = -1;
      return;
    }

    final source = ConcatenatingAudioSource(
      children: [
        for (var i = 0; i < tracks.length; i++)
          tracks[i].isAsset
              ? AudioSource.asset(
                  'assets/${tracks[i].src}',
                  tag: _mediaItem(i, tracks[i]),
                )
              : AudioSource.uri(
                  Uri.file(tracks[i].src),
                  tag: _mediaItem(i, tracks[i]),
                ),
      ],
    );

    await _player.setAudioSource(
      source,
      preload: false,
      initialIndex: savedIdx >= 0 && savedIdx < tracks.length ? savedIdx : 0,
      initialPosition: savedPos,
    );
    await _player.setLoopMode(LoopMode.all);
    if (wasPlaying) {
      await _player.play();
    }
  }

  MediaItem _mediaItem(int i, Track t) => MediaItem(
        id: '$i-${t.src}',
        album: 'DeePM',
        title: t.title,
        artist: t.artist,
        artUri: (t.artworkPath != null && t.artworkPath!.isNotEmpty)
            ? Uri.file(t.artworkPath!)
            : null,
      );

  Future<bool> addUserTrack({
    required String filePath,
    required String title,
    String artist = 'Неизвестно',
  }) async {
    try {
      // copy to app docs
      final docs = await getApplicationDocumentsDirectory();
      final musicDir = Directory('${docs.path}/user_music');
      if (!musicDir.existsSync()) musicDir.createSync(recursive: true);
      final fileName = filePath.split(Platform.pathSeparator).last;
      final destPath = '${musicDir.path}/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      await File(filePath).copy(destPath);

      tracks.add(Track(
        title: title,
        artist: artist,
        src: destPath,
        isAsset: false,
      ));
      await _saveUserTracks();
      await _rebuildPlaylist();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('addUserTrack error: $e');
      return false;
    }
  }

  /// Stream a remote URL ad-hoc (for preview before adding).
  Future<void> playStreamUrl(String url,
      {required String title,
      required String artist,
      String? artworkUrl}) async {
    if (!_initialized) return;
    _inPreview = true;
    _previewTrack = Track(
      title: title,
      artist: artist,
      src: url,
      isAsset: false,
    );
    notifyListeners();
    final temp = ConcatenatingAudioSource(children: [
      AudioSource.uri(
        Uri.parse(url),
        tag: MediaItem(
          id: 'preview-$url',
          album: 'DeePM',
          title: title,
          artist: artist,
          artUri: (artworkUrl != null && artworkUrl.isNotEmpty)
              ? Uri.parse(artworkUrl)
              : null,
        ),
      ),
    ]);
    await _player.setAudioSource(temp);
    await _player.play();
  }

  /// Restore the user's library playlist after a preview.
  Future<void> restoreLibrary() async {
    _inPreview = false;
    _previewTrack = null;
    await _rebuildPlaylist();
    notifyListeners();
  }

  /// Download a remote URL into the user library and add as a Track.
  Future<bool> downloadAndAdd({
    required String url,
    required String title,
    required String artist,
    String? artworkUrl,
  }) async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final musicDir = Directory('${docs.path}/user_music');
      if (!musicDir.existsSync()) musicDir.createSync(recursive: true);
      final artDir = Directory('${docs.path}/user_artwork');
      if (!artDir.existsSync()) artDir.createSync(recursive: true);
      final safeName =
          title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final destPath = '${musicDir.path}/${stamp}_$safeName.mp3';

      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) return false;
      await File(destPath).writeAsBytes(res.bodyBytes);

      String? artPath;
      if (artworkUrl != null && artworkUrl.isNotEmpty) {
        try {
          final ar = await http.get(Uri.parse(artworkUrl));
          if (ar.statusCode == 200) {
            artPath = '${artDir.path}/${stamp}_$safeName.jpg';
            await File(artPath).writeAsBytes(ar.bodyBytes);
          }
        } catch (e) {
          debugPrint('artwork download error: $e');
        }
      }

      tracks.add(Track(
        title: title,
        artist: artist,
        src: destPath,
        isAsset: false,
        artworkPath: artPath,
      ));
      await _saveUserTracks();
      await _rebuildPlaylist();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('downloadAndAdd error: $e');
      return false;
    }
  }

  Future<void> removeTrack(int idx) async {
    if (idx < 0 || idx >= tracks.length) return;
    final t = tracks[idx];
    if (t.isAsset) return; // can't remove bundled
    try {
      final f = File(t.src);
      if (f.existsSync()) await f.delete();
    } catch (_) {}
    if (t.artworkPath != null && t.artworkPath!.isNotEmpty) {
      try {
        final af = File(t.artworkPath!);
        if (af.existsSync()) await af.delete();
      } catch (_) {}
    }
    tracks.removeAt(idx);
    await _saveUserTracks();
    if (currentIdx == idx) {
      currentIdx = -1;
      await _player.stop();
    } else if (currentIdx > idx) {
      currentIdx -= 1;
    }
    await _rebuildPlaylist();
    notifyListeners();
  }

  Future<void> playTrack(int idx) async {
    if (!_initialized) return;
    if (_inPreview) {
      _inPreview = false;
      _previewTrack = null;
      await _rebuildPlaylist();
    }
    currentIdx = idx;
    await _player.seek(Duration.zero, index: idx);
    await _player.play();
    notifyListeners();
  }

  void togglePlay() {
    if (!_initialized) return;
    if (currentIdx < 0 && tracks.isNotEmpty) {
      playTrack(0);
      return;
    }
    if (_player.playing) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  Future<void> nextTrack() async {
    if (!_initialized) return;
    if (_player.hasNext) {
      await _player.seekToNext();
    } else {
      await _player.seek(Duration.zero, index: 0);
    }
    await _player.play();
  }

  Future<void> prevTrack() async {
    if (!_initialized) return;
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
    } else {
      await _player.seek(Duration.zero, index: tracks.length - 1);
    }
    await _player.play();
  }

  void toggleShuffle() {
    if (!_initialized) return;
    isShuffle = !isShuffle;
    _player.setShuffleModeEnabled(isShuffle);
    notifyListeners();
  }

  void toggleRepeat() {
    if (!_initialized) return;
    isRepeat = !isRepeat;
    _player.setLoopMode(isRepeat ? LoopMode.one : LoopMode.all);
    notifyListeners();
  }

  void seekTo(double percent) {
    if (duration.inMilliseconds > 0) {
      final ms = (percent * duration.inMilliseconds).toInt();
      _player.seek(Duration(milliseconds: ms));
    }
  }

  void seekToDuration(Duration d) {
    _player.seek(d);
  }

  String formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
