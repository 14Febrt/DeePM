import 'package:flutter/material.dart';
import '../audio_manager.dart';
import '../theme.dart';

class PlayerView extends StatelessWidget {
  final AudioManager audio;

  const PlayerView({super.key, required this.audio});

  @override
  Widget build(BuildContext context) {
    final track = audio.currentTrack;
    final progress = audio.duration.inMilliseconds > 0
        ? audio.position.inMilliseconds / audio.duration.inMilliseconds
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Album art
          _buildAlbumArt(),
          SizedBox(height: MediaQuery.of(context).size.height * 0.03),
          // Track info
          Text(
            track?.title ?? 'Не выбрано',
            style: AppColors.syne(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            track?.artist ?? 'Выберите трек',
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.03),
          // Progress bar
          _buildProgressBar(progress),
          const SizedBox(height: 8),
          // Time row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                audio.formatDuration(audio.position),
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
          SizedBox(height: MediaQuery.of(context).size.height * 0.03),
          // Controls
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildAlbumArt() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = MediaQuery.of(context).size.width * 0.55;
        return GlassContainer(
          borderRadius: BorderRadius.circular(28),
          child: SizedBox(
            width: size.clamp(200.0, 300.0),
            height: size.clamp(200.0, 300.0),
            child: const Center(
              child: Icon(
                Icons.music_note,
                size: 64,
                color: Color(0x4DFFFFFF),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressBar(double progress) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = constraints.maxWidth;
        final fillWidth = barWidth * progress.clamp(0.0, 1.0);
        return GestureDetector(
          onTapUp: (details) {
            audio.seekTo(
                (details.localPosition.dx / barWidth).clamp(0.0, 1.0));
          },
          onHorizontalDragUpdate: (details) {
            audio.seekTo(
                (details.localPosition.dx / barWidth).clamp(0.0, 1.0));
          },
          child: Container(
            width: double.infinity,
            height: 20,
            color: Colors.transparent,
            alignment: Alignment.center,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Container(
                  width: fillWidth,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Shuffle
        IconButton(
          onPressed: audio.toggleShuffle,
          icon: Icon(
            Icons.shuffle,
            color: audio.isShuffle
                ? Colors.white
                : AppColors.silverDim,
            size: 24,
          ),
        ),
        // Previous
        IconButton(
          onPressed: audio.prevTrack,
          icon: const Icon(
            Icons.skip_previous,
            color: AppColors.silverDim,
            size: 24,
          ),
        ),
        // Play/Pause
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
        // Next
        IconButton(
          onPressed: audio.nextTrack,
          icon: const Icon(
            Icons.skip_next,
            color: AppColors.silverDim,
            size: 24,
          ),
        ),
        // Repeat
        IconButton(
          onPressed: audio.toggleRepeat,
          icon: Icon(
            Icons.repeat,
            color: audio.isRepeat
                ? Colors.white
                : AppColors.silverDim,
            size: 24,
          ),
        ),
      ],
    );
  }
}
