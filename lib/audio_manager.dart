import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'models.dart';

class AudioManager extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  late final ConcatenatingAudioSource _playlist;
  int currentIdx = -1;
  bool isPlaying = false;
  bool isShuffle = false;
  bool isRepeat = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  bool _initialized = false;

  Track? get currentTrack =>
      currentIdx >= 0 && currentIdx < myTracks.length
          ? myTracks[currentIdx]
          : null;

  AudioManager() {
    _init();
  }

  Future<void> _init() async {
    _playlist = ConcatenatingAudioSource(
      children: [
        for (var i = 0; i < myTracks.length; i++)
          AudioSource.asset(
            'assets/${myTracks[i].src}',
            tag: MediaItem(
              id: '$i',
              album: 'DeePM',
              title: myTracks[i].title,
              artist: myTracks[i].artist,
            ),
          ),
      ],
    );

    await _player.setAudioSource(_playlist, preload: false);
    await _player.setLoopMode(LoopMode.all);
    _initialized = true;

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
      if (idx != null) {
        currentIdx = idx;
        notifyListeners();
      }
    });
  }

  Future<void> playTrack(int idx) async {
    if (!_initialized) return;
    currentIdx = idx;
    await _player.seek(Duration.zero, index: idx);
    await _player.play();
    notifyListeners();
  }

  void togglePlay() {
    if (!_initialized) return;
    if (currentIdx < 0 && myTracks.isNotEmpty) {
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
      await _player.seek(Duration.zero, index: myTracks.length - 1);
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
    // isRepeat = повтор одного трека; иначе циклический плейлист
    _player.setLoopMode(isRepeat ? LoopMode.one : LoopMode.all);
    notifyListeners();
  }

  void seekTo(double percent) {
    if (duration.inMilliseconds > 0) {
      final ms = (percent * duration.inMilliseconds).toInt();
      _player.seek(Duration(milliseconds: ms));
    }
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
