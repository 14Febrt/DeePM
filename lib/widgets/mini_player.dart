import 'package:flutter/material.dart';
import '../audio_manager.dart';
import '../theme.dart';

class MiniPlayer extends StatelessWidget {
  final AudioManager audio;
  final VoidCallback onTap;

  const MiniPlayer({
    super.key,
    required this.audio,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final track = audio.currentTrack;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
        child: GlassContainer(
          borderRadius: BorderRadius.circular(24),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          child: Row(
            children: [
              // Mini art
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(
                    Icons.music_note,
                    color: Color(0xFF444444),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track?.title ?? 'Не выбрано',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      track?.artist ?? 'DeePM',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Play button
              GestureDetector(
                onTap: () {
                  audio.togglePlay();
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Center(
                    child: Icon(
                      audio.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: Colors.black,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
