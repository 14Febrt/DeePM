import 'package:flutter/material.dart';
import '../audio_manager.dart';
import '../theme.dart';

class PlayerScreen extends StatefulWidget {
  final AudioManager audio;
  const PlayerScreen({super.key, required this.audio});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  double? _dragValue;

  @override
  void initState() {
    super.initState();
    widget.audio.addListener(_onChange);
  }

  @override
  void dispose() {
    widget.audio.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final audio = widget.audio;
    final track = audio.currentTrack;
    final idx = audio.currentIdx < 0 ? 0 : audio.currentIdx;
    final hueShift = (idx * 37) % 360;
    final tint =
        HSLColor.fromAHSL(0.04, hueShift.toDouble(), 0.3, 0.5).toColor();

    final totalMs = audio.duration.inMilliseconds.toDouble();
    final positionMs = audio.position.inMilliseconds
        .toDouble()
        .clamp(0.0, totalMs <= 0 ? 1.0 : totalMs);
    final sliderValue = _dragValue ?? positionMs;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: const Alignment(-0.5, -1),
            end: const Alignment(0.5, 1),
            colors: [
              Color.lerp(const Color(0xFF1a1a1a), tint, 0.6)!,
              const Color(0xFF0d0d0d),
              const Color(0xFF050505),
              Color.lerp(const Color(0xFF111111), tint, 0.4)!,
            ],
            stops: const [0.0, 0.4, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar with close
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.keyboard_arrow_down,
                          color: Colors.white, size: 32),
                    ),
                    Text(
                      'Сейчас играет',
                      style: AppColors.dmSans(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildAlbumArt(context),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.04),
                      Text(
                        track?.title ?? 'Не выбрано',
                        style: AppColors.syne(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        track?.artist ?? 'Выберите трек',
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.04),
                      _buildSlider(audio, sliderValue, totalMs),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              audio.formatDuration(
                                Duration(milliseconds: sliderValue.toInt()),
                              ),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              audio.formatDuration(audio.duration),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                      _buildControls(audio),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumArt(BuildContext context) {
    final size =
        (MediaQuery.of(context).size.width * 0.65).clamp(220.0, 320.0);
    return GlassContainer(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        width: size,
        height: size,
        child: const Center(
          child: Icon(
            Icons.music_note,
            size: 72,
            color: Color(0x4DFFFFFF),
          ),
        ),
      ),
    );
  }

  Widget _buildSlider(AudioManager audio, double value, double max) {
    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 4,
        activeTrackColor: Colors.white,
        inactiveTrackColor: Colors.white.withOpacity(0.12),
        thumbColor: Colors.white,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
        overlayColor: Colors.white.withOpacity(0.15),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
      ),
      child: Slider(
        min: 0,
        max: max <= 0 ? 1 : max,
        value: value.clamp(0, max <= 0 ? 1 : max),
        onChanged: max <= 0
            ? null
            : (v) => setState(() => _dragValue = v),
        onChangeEnd: max <= 0
            ? null
            : (v) {
                audio.seekToDuration(Duration(milliseconds: v.toInt()));
                _dragValue = null;
              },
      ),
    );
  }

  Widget _buildControls(AudioManager audio) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: audio.toggleShuffle,
          icon: Icon(
            Icons.shuffle,
            color: audio.isShuffle ? Colors.white : AppColors.silverDim,
            size: 24,
          ),
        ),
        IconButton(
          onPressed: audio.prevTrack,
          icon: const Icon(
            Icons.skip_previous,
            color: AppColors.silverDim,
            size: 30,
          ),
        ),
        GestureDetector(
          onTap: audio.togglePlay,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.15),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                audio.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.black,
                size: 28,
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: audio.nextTrack,
          icon: const Icon(
            Icons.skip_next,
            color: AppColors.silverDim,
            size: 30,
          ),
        ),
        IconButton(
          onPressed: audio.toggleRepeat,
          icon: Icon(
            Icons.repeat,
            color: audio.isRepeat ? Colors.white : AppColors.silverDim,
            size: 24,
          ),
        ),
      ],
    );
  }
}
