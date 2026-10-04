/// Wall-clock arithmetic on local [DateTime]s.
///
/// TimeFlow treats task times as wall-clock times ("9:00 on Tuesday"), not
/// instants. `DateTime.difference` and `DateTime.add` work in absolute time,
/// which is off by an hour whenever a DST change falls in between; these
/// helpers compare and shift the clock readings instead.
library;

/// Minutes from [a] to [b] as read off a wall clock, ignoring DST shifts.
int wallMinutesBetween(DateTime a, DateTime b) =>
    _asUtc(b).difference(_asUtc(a)).inMinutes;

/// [t] moved by [minutes] of wall-clock time.
DateTime addWallMinutes(DateTime t, int minutes) =>
    DateTime(t.year, t.month, t.day, t.hour, t.minute + minutes, t.second);

/// Minutes since local midnight (0..1439).
int minuteOfDay(DateTime t) => t.hour * 60 + t.minute;

/// `yyyy-MM-ddTHH:mm:ss` with no offset, the storage format for task times.
/// Fixed-width, so string order is chronological order.
String formatWallClock(DateTime t) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${t.year.toString().padLeft(4, '0')}-${two(t.month)}-${two(t.day)}'
      'T${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
}

/// Parses [formatWallClock] output as local wall-clock time. A string with a
/// UTC offset denotes an instant and is converted to local time.
DateTime parseWallClock(String s) {
  final t = DateTime.parse(s);
  return t.isUtc ? t.toLocal() : t;
}

DateTime _asUtc(DateTime t) =>
    DateTime.utc(t.year, t.month, t.day, t.hour, t.minute, t.second);
