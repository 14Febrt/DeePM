import 'package:flutter/material.dart';
import '../models.dart';
import '../theme.dart';

class LibraryView extends StatefulWidget {
  final int currentIdx;
  final void Function(int) onPlay;

  const LibraryView({
    super.key,
    required this.currentIdx,
    required this.onPlay,
  });

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<LibraryView> {
  String _filter = '';

  List<MapEntry<int, Track>> get _filtered {
    final list = <MapEntry<int, Track>>[];
    for (int i = 0; i < myTracks.length; i++) {
      final t = myTracks[i];
      if (_filter.isEmpty ||
          t.title.toLowerCase().contains(_filter) ||
          t.artist.toLowerCase().contains(_filter)) {
        list.add(MapEntry(i, t));
      }
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 140),
      children: [
        const SizedBox(height: 8),
        // Search
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: TextField(
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Поиск по коллекции...',
              hintStyle: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: AppColors.textSecondary,
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            onChanged: (v) => setState(() => _filter = v.toLowerCase()),
          ),
        ),
        // Title
        Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: Text(
            'Моя Коллекция',
            style: AppColors.syne(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        // Track list
        ...filtered.map((entry) => _TrackItem(
              track: entry.value,
              isPlaying: entry.key == widget.currentIdx,
              onTap: () => widget.onPlay(entry.key),
            )),
      ],
    );
  }
}

class _TrackItem extends StatelessWidget {
  final Track track;
  final bool isPlaying;
  final VoidCallback onTap;

  const _TrackItem({
    required this.track,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isPlaying
              ? Colors.white.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF1a1a1a),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(
                  Icons.music_note,
                  color: Color(0xFF444444),
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isPlaying
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    track.artist,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
