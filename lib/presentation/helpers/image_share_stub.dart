import 'dart:typed_data';

import 'package:flutter/widgets.dart';

/// Stub implementation — should never be used at runtime.
/// Conditional imports will select the correct platform implementation.

/// Shares image bytes using the platform share sheet or saves to disk.
Future<void> shareImageBytes(
  Uint8List bytes,
  String fileName,
  String subject,
  BuildContext context,
) {
  throw UnsupportedError(
      'Cannot share images without a platform implementation');
}
