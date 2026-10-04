import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/widgets.dart';

/// Shares image bytes by triggering a browser download.
Future<void> shareImageBytes(
  Uint8List bytes,
  String fileName,
  String subject,
  BuildContext context,
) async {
  final blob = html.Blob([bytes], 'image/png');
  final url = html.Url.createObjectUrlFromBlob(blob);

  final anchor = html.AnchorElement()
    ..href = url
    ..download = fileName
    ..style.display = 'none';

  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();

  html.Url.revokeObjectUrl(url);
}
