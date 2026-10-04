import 'package:flutter/material.dart';
import 'package:timeflow/presentation/timeline/timeline_view.dart';

/// Shown at the edge of the timeline on NOW's side while NOW is off screen:
/// which way it is, how far the view has drifted, and a tap to go back.
class NowChip extends StatelessWidget {
  final OffscreenNow now;
  final VoidCallback onTap;

  const NowChip({super.key, required this.now, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = 'Back to NOW · ${now.distance}';
    return Semantics(
      button: true,
      label: '$label. Now is ${now.above ? 'above' : 'below'}.',
      excludeSemantics: true,
      child: Material(
        color: scheme.primary,
        elevation: 4,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  now.above ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 18,
                  color: scheme.onPrimary,
                ),
                const SizedBox(width: 6),
                Text(
                  'NOW',
                  style: TextStyle(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  '  ·  ${now.distance}',
                  style: TextStyle(color: scheme.onPrimary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
