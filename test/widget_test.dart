import 'package:cassette/models/playlist.dart';
import 'package:cassette/models/song.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Song serializes round-trip', () {
    const song = Song(
      id: 'abc',
      title: 'Test',
      artist: 'Tester',
      duration: Duration(seconds: 90),
      url: '/tmp/x.mp3',
    );
    final json = song.toJson();
    final restored = Song.fromJson(json);
    expect(restored.id, song.id);
    expect(restored.title, song.title);
    expect(restored.duration, song.duration);
  });

  test('Playlist copyWith preserves id and replaces fields', () {
    const playlist = Playlist(id: '1', name: 'Old', songIds: ['a']);
    final updated = playlist.copyWith(name: 'New', songIds: ['a', 'b']);
    expect(updated.id, '1');
    expect(updated.name, 'New');
    expect(updated.songIds, ['a', 'b']);
  });
}
