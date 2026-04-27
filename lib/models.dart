class Track {
  final String title;
  final String artist;
  final String src;
  final bool isAsset;

  const Track({
    required this.title,
    required this.artist,
    required this.src,
    this.isAsset = true,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'artist': artist,
        'src': src,
        'isAsset': isAsset,
      };

  factory Track.fromJson(Map<String, dynamic> j) => Track(
        title: j['title'] as String,
        artist: j['artist'] as String,
        src: j['src'] as String,
        isAsset: j['isAsset'] as bool? ?? true,
      );
}

const List<Track> bundledTracks = [
  Track(title: "Любовь в ресторане", artist: "Riso", src: "music/LOVE.mp3"),
  Track(title: "Roaming", artist: "Big Baby Tape & LOVV66", src: "music/Roaming.mp3"),
  Track(title: "Бойсбэнд", artist: "PhARAOH", src: "music/Boybend.mp3"),
  Track(title: "Гикаю", artist: "Платина", src: "music/Гикаю.mp3"),
  Track(title: "Санта Клаус", artist: "Платина", src: "music/Санта Клаус.mp3"),
  Track(title: "Бай Бай", artist: "LOVV66", src: "music/Бай Бай.mp3"),
  Track(title: "На посту", artist: "Платина & LIL VAN", src: "music/На посту.mp3"),
  Track(title: "Улыбаюсь", artist: "SixthSennse", src: "music/Улыбаюсь.mp3"),
];
