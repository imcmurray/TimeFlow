import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/presentation/providers/task_provider.dart';

/// The photo behind an attachment reference.
final attachmentProvider = FutureProvider.autoDispose
    .family<({Uint8List bytes, String mimeType})?, String>(
      (ref, reference) =>
          ref.watch(taskRepositoryProvider).attachment(reference),
    );

/// A task's photo as a rounded thumbnail; tap to view it full screen.
class TaskPhotoThumbnail extends ConsumerWidget {
  final String reference;
  final double height;
  final VoidCallback? onRemove;

  const TaskPhotoThumbnail({
    super.key,
    required this.reference,
    this.height = 160,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photo = ref.watch(attachmentProvider(reference));
    return SizedBox(
      height: height,
      child: photo.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Photo unavailable')),
        data: (p) => p == null
            ? const Center(child: Text('Photo unavailable'))
            : Stack(
                children: [
                  Positioned.fill(
                    child: Semantics(
                      image: true,
                      label: 'Task photo. Tap to view full screen.',
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            fullscreenDialog: true,
                            builder: (_) => _PhotoViewer(bytes: p.bytes),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(p.bytes, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  ),
                  if (onRemove != null)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton.filledTonal(
                        icon: const Icon(Icons.close),
                        tooltip: 'Remove photo',
                        onPressed: onRemove,
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _PhotoViewer extends StatelessWidget {
  final Uint8List bytes;

  const _PhotoViewer({required this.bytes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: InteractiveViewer(
        maxScale: 5,
        child: Center(child: Image.memory(bytes)),
      ),
    );
  }
}
