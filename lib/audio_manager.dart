import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'models.dart';

class AudioManager extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  int currentIdx = -1;
  bool isPlaying = false;
  bool isShuffle = false;
  bool isRepeat = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;

  Track? get currentTrack =>
      currentIdx >= 0 && currentIdx < myTracks.length
          ? myTracks[currentIdx]
          : null;

  AudioManager() {
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
      if (state.processingState == ProcessingState.completed) {
        if (isRepeat) {
          playTrack(currentIdx);
        } else {
          nextTrack();
        }
      }
    });
  }

  Future<void> playTrack(int idx) async {
    currentIdx = idx;
    final t = myTracks[idx];
    await _player.stop();
    await _player.setAudioSource(
      AudioSource.asset(
        'assets/${t.src}',
        tag: MediaItem(
          id: '$idx',
          album: 'DeePM',
          title: t.title,
          artist: t.artist,
        ),
      ),
    );
    await _player.play();
    notifyListeners();
  }

  void togglePlay() {
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

  void nextTrack() {
    if (myTracks.isEmpty) return;
    int next;
    if (isShuffle && myTracks.length > 1) {
      do {
        next = Random().nextInt(myTracks.length);
      } while (next == currentIdx);
    } else {
      next = (currentIdx + 1) % myTracks.length;
    }
    playTrack(next);
  }

  void prevTrack() {
    if (myTracks.isEmpty) return;
    int prev = currentIdx - 1;
    if (prev < 0) prev = myTracks.length - 1;
    playTrack(prev);
  }

  void toggleShuffle() {
    isShuffle = !isShuffle;
    notifyListeners();
  }

  void toggleRepeat() {
    isRepeat = !isRepeat;
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
