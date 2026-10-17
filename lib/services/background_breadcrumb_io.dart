import 'dart:io';

/// Where the breadcrumb goes, and **why it is `Directory.systemTemp` rather
/// than `path_provider`**: the thing it is meant to diagnose is a background
/// isolate in which plugins may not be registered at all. A breadcrumb that
/// needs a platform channel to record "the platform channels didn't work" is no
/// breadcrumb. `systemTemp` comes from dart:io, inside the app's own container
/// on iOS and Android, and needs nothing to be initialised first.
File _file() => File('${Directory.systemTemp.path}/timeflow-background.log');

/// Keeps the last few lines only. This is a diagnostic for one tap, not a log.
const _keep = 12;

Future<void> write(String line) async {
  try {
    final file = _file();
    final before = await file.exists() ? await file.readAsLines() : <String>[];
    final kept = [...before, line];
    await file.writeAsString(
      kept.sublist(kept.length > _keep ? kept.length - _keep : 0).join('\n'),
    );
  } catch (_) {
    // A breadcrumb that throws would hide the failure it exists to describe.
  }
}

Future<String?> read() async {
  try {
    final file = _file();
    if (!await file.exists()) return null;
    final text = await file.readAsString();
    return text.trim().isEmpty ? null : text.trim();
  } catch (_) {
    return null;
  }
}

Future<void> clear() async {
  try {
    final file = _file();
    if (await file.exists()) await file.delete();
  } catch (_) {}
}
