import 'dart:js_interop';

@JS('Intl.DateTimeFormat')
external _DateTimeFormat _dateTimeFormat();

extension type _DateTimeFormat._(JSObject _) implements JSObject {
  external _ResolvedOptions resolvedOptions();
}

extension type _ResolvedOptions._(JSObject _) implements JSObject {
  external String get timeZone;
}

/// The browser's time zone from the Intl API.
String? browserTimeZone() => _dateTimeFormat().resolvedOptions().timeZone;
