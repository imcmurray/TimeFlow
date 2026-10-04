import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

/// Photos are stored at most this many pixels on their longer side.
const _maxSide = 1600;

typedef PickedPhoto = ({Uint8List bytes, String mimeType});

bool get _isMobile =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// Lets the user take or choose a photo, downscaled for storage. Returns
/// null if they cancel.
Future<PickedPhoto?> pickPhoto(BuildContext context) async {
  if (_isMobile || kIsWeb) {
    ImageSource source = ImageSource.gallery;
    if (_isMobile) {
      final chosen = await showModalBottomSheet<ImageSource>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
      if (chosen == null) return null;
      source = chosen;
    }
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: _maxSide.toDouble(),
      maxHeight: _maxSide.toDouble(),
      imageQuality: 85,
    );
    if (file == null) return null;
    return (
      bytes: await file.readAsBytes(),
      mimeType: file.mimeType ?? 'image/jpeg',
    );
  }

  // Desktop: pick a file and shrink it here.
  final file = await FilePicker.pickFile(
    type: FileType.image,
    dialogTitle: 'Choose a photo',
  );
  if (file == null) return null;
  final bytes = await file.xFile.readAsBytes();
  return compute(_shrink, bytes);
}

/// Re-encodes [bytes] as a JPEG no larger than [_maxSide] on either side.
PickedPhoto _shrink(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw const FormatException('Not an image');
  final oriented = img.bakeOrientation(decoded);
  final resized = oriented.width > _maxSide || oriented.height > _maxSide
      ? img.copyResize(
          oriented,
          width: oriented.width >= oriented.height ? _maxSide : null,
          height: oriented.height > oriented.width ? _maxSide : null,
        )
      : oriented;
  return (bytes: img.encodeJpg(resized, quality: 85), mimeType: 'image/jpeg');
}
