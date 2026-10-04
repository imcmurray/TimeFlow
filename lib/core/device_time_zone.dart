import 'package:flutter_timezone/flutter_timezone.dart';

import 'device_time_zone_stub.dart'
    if (dart.library.js_interop) 'device_time_zone_web.dart'
    as web;

/// The device's IANA time zone name (e.g. 'America/Denver'), or null.
Future<String?> deviceTimeZone() async {
  try {
    return web.browserTimeZone() ??
        (await FlutterTimezone.getLocalTimezone()).identifier;
  } catch (_) {
    return null;
  }
}
