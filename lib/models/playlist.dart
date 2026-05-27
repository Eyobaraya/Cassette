class Playlist {
  const Playlist({
    required this.id,
    required this.name,
    required this.songIds,
  });

  final String id;
  final String name;
  final List<String> songIds;

  Playlist copyWith({
    String? name,
    List<String>? songIds,
  }) {
    return Playlist(
      id: id,
      name: name ?? this.name,
      songIds: songIds ?? this.songIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'songIds': songIds,
    };
  }

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as String,
      name: json['name'] as String,
      songIds: List<String>.from(json['songIds'] as List),
    );
  }
}
