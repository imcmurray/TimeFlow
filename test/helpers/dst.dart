/// DST-dependent tests only mean something in a zone with DST. CI runs the
/// suite with TZ=America/Denver; elsewhere these tests skip themselves.
///
/// US DST 2026: spring forward Sun 2026-03-08, fall back Sun 2026-11-01.
bool get hasUsDst2026 =>
    DateTime(2026, 3, 7, 12).timeZoneOffset !=
        DateTime(2026, 3, 9, 12).timeZoneOffset &&
    DateTime(2026, 10, 31, 12).timeZoneOffset !=
        DateTime(2026, 11, 2, 12).timeZoneOffset;

const dstSkipReason = 'needs a US DST time zone, e.g. TZ=America/Denver';

Object? get skipWithoutDst => hasUsDst2026 ? null : dstSkipReason;
