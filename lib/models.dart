class Track {
  final String title;
  final String artist;
  final String src;
  final bool isAsset;
  final String? artworkPath;

  const Track({
    required this.title,
    required this.artist,
    required this.src,
    this.isAsset = false,
    this.artworkPath,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'artist': artist,
        'src': src,
        'isAsset': isAsset,
        'artworkPath': artworkPath,
      };

  factory Track.fromJson(Map<String, dynamic> j) => Track(
        title: j['title'] as String,
        artist: j['artist'] as String,
        src: j['src'] as String,
        isAsset: j['isAsset'] as bool? ?? false,
        artworkPath: j['artworkPath'] as String?,
      );
}
