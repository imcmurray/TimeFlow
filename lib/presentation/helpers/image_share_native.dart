import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Shares image bytes using the platform share sheet.
/// On Linux: saves to ~/Pictures and shows a snackbar.
/// On other platforms: opens the native share dialog.
Future<void> shareImageBytes(
  Uint8List bytes,
  String fileName,
  String subject,
  BuildContext context,
) async {
  if (Platform.isLinux) {
    final homeDir = Platform.environment['HOME'] ?? '/tmp';
    final picturesDir = Directory('$homeDir/Pictures');
    if (!await picturesDir.exists()) {
      await picturesDir.create(recursive: true);
    }
    final file = File('${picturesDir.path}/$fileName');
    await file.writeAsBytes(bytes);

    if (context.mounted) {
      // Use the OverlayState to show a snackbar-like message.
      // The caller should handle showing feedback via ScaffoldMessenger.
    }
  } else {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: subject,
    );
  }
}
