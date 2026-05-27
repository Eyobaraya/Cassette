class Song {
  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.duration,
    required this.url,
  });

  final String id;
  final String title;
  final String artist;
  final Duration duration;
  final String url;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'duration': duration.inMilliseconds,
      'url': url,
    };
  }

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      duration: Duration(milliseconds: json['duration'] as int),
      url: json['url'] as String,
    );
  }
}
