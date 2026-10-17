// The web build has no notification background isolate and no dart:io, so the
// breadcrumb is nothing at all there. It exists so the one import in
// background_breadcrumb.dart resolves on every platform.

Future<void> write(String line) async {}

Future<String?> read() async => null;

Future<void> clear() async {}
