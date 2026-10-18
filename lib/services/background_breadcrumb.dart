import 'package:timeflow/domain/time/wall_clock.dart';

import 'background_breadcrumb_stub.dart'
    if (dart.library.io) 'background_breadcrumb_io.dart'
    as store;

/// What the notification background isolate last managed to do.
///
/// A tester's *Done* on a lock-screen reminder cleared the notification and
/// left the task unfinished, on a release build on a real iPhone — and passed
/// on every simulator, where builds are debug and a cable is beside the point
/// (TimeFlow#68). Nobody can attach a debugger to a tester's phone, so the
/// isolate writes down how far it got instead, and Settings → About shows it on
/// beta builds. One tap then says where it stops.
///
/// Each step is a line, newest last, with the time it happened.
class BackgroundBreadcrumb {
  const BackgroundBreadcrumb._();

  static const received = 'received';
  static const plugins = 'plugins registered';
  static const database = 'database opened';
  static const found = 'task found';
  static const written = 'written';

  /// Another connection had the database; the wait before trying again.
  static const locked = 'database locked, waiting';

  /// Notes a step. Never throws: the one thing worse than no breadcrumb is a
  /// breadcrumb that takes the handler down with it.
  static Future<void> note(String step, {DateTime? at}) =>
      store.write('${formatWallClock(at ?? DateTime.now())}  $step');

  /// Notes a failure, with the exception's own words.
  static Future<void> failed(Object error, {DateTime? at}) =>
      note('failed: $error', at: at);

  /// The whole breadcrumb, or null if the isolate has never run here.
  static Future<String?> read() => store.read();

  static Future<void> clear() => store.clear();
}
