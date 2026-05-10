import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../audio_manager.dart';
import '../models.dart';

/// Pack/unpack the user's library (mp3 + artwork + metadata) into a single
/// zip file. Used for manual backup before deleting / reinstalling the app.
class BackupService {
  static const _manifestName = 'manifest.json';
  static const _musicDir = 'music';
  static const _artDir = 'artwork';

  /// Builds a zip with all user tracks and writes it into the temp directory.
  /// Returns the path of the resulting file (caller can share it).
  static Future<File> exportZip(AudioManager audio) async {
    final encoder = ZipEncoder();
    final archive = Archive();

    final entries = <Map<String, dynamic>>[];
    for (final t in audio.tracks.where((t) => !t.isAsset)) {
      final srcFile = File(t.src);
      if (!srcFile.existsSync()) continue;

      final musicName = _basename(t.src);
      archive.addFile(ArchiveFile(
        '$_musicDir/$musicName',
        srcFile.lengthSync(),
        srcFile.readAsBytesSync(),
      ));

      String? artName;
      if (t.artworkPath != null && t.artworkPath!.isNotEmpty) {
        final artFile = File(t.artworkPath!);
        if (artFile.existsSync()) {
          artName = _basename(t.artworkPath!);
          archive.addFile(ArchiveFile(
            '$_artDir/$artName',
            artFile.lengthSync(),
            artFile.readAsBytesSync(),
          ));
        }
      }

      entries.add({
        'title': t.title,
        'artist': t.artist,
        'music': musicName,
        'artwork': artName,
      });
    }

    final manifest = jsonEncode({
      'version': 1,
      'created': DateTime.now().toIso8601String(),
      'tracks': entries,
    });
    final manifestBytes = utf8.encode(manifest);
    archive.addFile(
        ArchiveFile(_manifestName, manifestBytes.length, manifestBytes));

    final temp = await getTemporaryDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final outPath = '${temp.path}/DeePM_backup_$stamp.zip';
    final out = OutputFileStream(outPath);
    encoder.encode(archive, output: out);
    await out.close();
    return File(outPath);
  }

  /// Imports tracks from a zip created by [exportZip]. Existing duplicates
  /// (same title + artist) are skipped. Returns number of imported tracks.
  static Future<int> importZip(AudioManager audio, String zipPath) async {
    final bytes = await File(zipPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final manifestFile =
        archive.files.where((f) => f.name == _manifestName).firstOrNull;
    if (manifestFile == null) {
      throw Exception('Файл повреждён: нет manifest.json');
    }
    final manifest =
        jsonDecode(utf8.decode(manifestFile.content as List<int>))
            as Map<String, dynamic>;
    final list = (manifest['tracks'] as List?) ?? const [];

    final docs = await getApplicationDocumentsDirectory();
    final musicDir = Directory('${docs.path}/user_music');
    if (!musicDir.existsSync()) musicDir.createSync(recursive: true);
    final artDir = Directory('${docs.path}/user_artwork');
    if (!artDir.existsSync()) artDir.createSync(recursive: true);

    final existing = audio.tracks
        .map((t) => '${t.title.toLowerCase()}|${t.artist.toLowerCase()}')
        .toSet();

    int imported = 0;
    for (final raw in list) {
      if (raw is! Map) continue;
      final title = raw['title']?.toString() ?? '';
      final artist = raw['artist']?.toString() ?? '';
      final musicName = raw['music']?.toString();
      final artName = raw['artwork']?.toString();
      if (title.isEmpty || musicName == null) continue;

      final key = '${title.toLowerCase()}|${artist.toLowerCase()}';
      if (existing.contains(key)) continue;

      final musicEntry = archive.files
          .where((f) => f.name == '$_musicDir/$musicName')
          .firstOrNull;
      if (musicEntry == null) continue;

      final stamp = DateTime.now().millisecondsSinceEpoch + imported;
      final destMusic = '${musicDir.path}/${stamp}_$musicName';
      await File(destMusic).writeAsBytes(musicEntry.content as List<int>);

      String? destArt;
      if (artName != null && artName.isNotEmpty) {
        final artEntry = archive.files
            .where((f) => f.name == '$_artDir/$artName')
            .firstOrNull;
        if (artEntry != null) {
          destArt = '${artDir.path}/${stamp}_$artName';
          await File(destArt).writeAsBytes(artEntry.content as List<int>);
        }
      }

      await audio.addImportedTrack(Track(
        title: title,
        artist: artist,
        src: destMusic,
        isAsset: false,
        artworkPath: destArt,
      ));
      existing.add(key);
      imported++;
    }
    return imported;
  }

  static String _basename(String path) {
    final norm = path.replaceAll('\\', '/');
    final i = norm.lastIndexOf('/');
    return i >= 0 ? norm.substring(i + 1) : norm;
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}
