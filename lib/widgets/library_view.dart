import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../audio_manager.dart';
import '../models.dart';
import '../theme.dart';

class LibraryView extends StatefulWidget {
  final AudioManager audio;

  const LibraryView({super.key, required this.audio});

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<LibraryView> {
  String _filter = '';
  bool _adding = false;

  List<MapEntry<int, Track>> get _filtered {
    final list = <MapEntry<int, Track>>[];
    final tracks = widget.audio.tracks;
    for (int i = 0; i < tracks.length; i++) {
      final t = tracks[i];
      if (_filter.isEmpty ||
          t.title.toLowerCase().contains(_filter) ||
          t.artist.toLowerCase().contains(_filter)) {
        list.add(MapEntry(i, t));
      }
    }
    return list;
  }

  Future<void> _pickAndAdd() async {
    if (_adding) return;
    setState(() => _adding = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
      );
      if (result == null) return;

      for (final file in result.files) {
        if (file.path == null) continue;
        // strip extension for default title
        final name = file.name;
        final dot = name.lastIndexOf('.');
        final title = dot > 0 ? name.substring(0, dot) : name;
        await widget.audio.addUserTrack(
          filePath: file.path!,
          title: title,
          artist: 'Моя музыка',
        );
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _confirmDelete(int idx, Track t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        title: const Text('Удалить трек?',
            style: TextStyle(color: Colors.white)),
        content: Text(
          '"${t.title}" будет удалён из коллекции.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child:
                const Text('Удалить', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await widget.audio.removeTrack(idx);
    }
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
            decoration: const InputDecoration(
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
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            onChanged: (v) => setState(() => _filter = v.toLowerCase()),
          ),
        ),
        // Title row with add button
        Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Моя Коллекция',
                  style: AppColors.syne(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _pickAndAdd,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.12),
                    ),
                  ),
                  child: _adding
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add,
                          color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
        // Track list
        ...filtered.map((entry) => _TrackItem(
              track: entry.value,
              isPlaying: entry.key == widget.audio.currentIdx,
              onTap: () => widget.audio.playTrack(entry.key),
              onLongPress: entry.value.isAsset
                  ? null
                  : () => _confirmDelete(entry.key, entry.value),
            )),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 32),
            child: Center(
              child: Text(
                'Ничего не найдено',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TrackItem extends StatelessWidget {
  final Track track;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _TrackItem({
    required this.track,
    required this.isPlaying,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              isPlaying ? Colors.white.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF1a1a1a),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  track.isAsset ? Icons.music_note : Icons.library_music,
                  color: const Color(0xFF666666),
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color:
                          isPlaying ? Colors.white : AppColors.textPrimary,
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
