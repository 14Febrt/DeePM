import 'package:flutter/material.dart';
import '../audio_manager.dart';
import '../services/soundcloud.dart';
import '../theme.dart';

class BrowseView extends StatefulWidget {
  final AudioManager audio;
  const BrowseView({super.key, required this.audio});

  @override
  State<BrowseView> createState() => _BrowseViewState();
}

class _BrowseViewState extends State<BrowseView> {
  final TextEditingController _ctrl = TextEditingController();
  List<ScTrack> _results = [];
  bool _loading = false;
  String? _error;
  final Set<int> _downloading = {};

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _doSearch() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await SoundcloudService.search(q);
      if (!mounted) return;
      setState(() => _results = r);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _preview(ScTrack t) async {
    final url = await SoundcloudService.getStreamUrl(t);
    if (url == null) {
      _snack('Не удалось получить ссылку на стрим');
      return;
    }
    await widget.audio.playStreamUrl(url, title: t.title, artist: t.user);
  }

  Future<void> _download(ScTrack t) async {
    setState(() => _downloading.add(t.id));
    try {
      final url = await SoundcloudService.getStreamUrl(t);
      if (url == null) {
        _snack('Не удалось получить ссылку');
        return;
      }
      final ok = await widget.audio.downloadAndAdd(
        url: url,
        title: t.title,
        artist: t.user,
      );
      _snack(ok ? 'Добавлено в коллекцию' : 'Ошибка скачивания');
    } finally {
      if (mounted) setState(() => _downloading.remove(t.id));
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF1a1a1a),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: TextField(
              controller: _ctrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _doSearch(),
              decoration: InputDecoration(
                hintText: 'Поиск SoundCloud...',
                hintStyle: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(Icons.search,
                    color: AppColors.textSecondary, size: 20),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward,
                      color: AppColors.textSecondary, size: 20),
                  onPressed: _doSearch,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Ошибка: $_error',
            style: const TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_results.isEmpty) {
      return Center(
        child: Text(
          'Найдите треки на SoundCloud',
          style: TextStyle(
            color: AppColors.textSecondary.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 140),
      itemCount: _results.length,
      itemBuilder: (ctx, i) {
        final t = _results[i];
        final isDl = _downloading.contains(t.id);
        return _ScItem(
          track: t,
          isDownloading: isDl,
          onPlay: () => _preview(t),
          onDownload: () => _download(t),
        );
      },
    );
  }
}

class _ScItem extends StatelessWidget {
  final ScTrack track;
  final bool isDownloading;
  final VoidCallback onPlay;
  final VoidCallback onDownload;

  const _ScItem({
    required this.track,
    required this.isDownloading,
    required this.onPlay,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final art = track.artworkLarge;
    return GestureDetector(
      onTap: onPlay,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
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
                image: art.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(art),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: art.isEmpty
                  ? const Center(
                      child: Icon(Icons.music_note,
                          color: Color(0xFF666666), size: 24),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    track.user,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: isDownloading ? null : onDownload,
              icon: isDownloading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.download_rounded,
                      color: Colors.white, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}
