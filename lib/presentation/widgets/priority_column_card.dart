import 'package:flutter/material.dart';

/// A card content wrapper that clips overflow instead of causing RenderFlex errors.
///
/// Content is laid out in priority order (top to bottom). When the card is too
/// short to show everything, lower-priority content is simply clipped away.
class PriorityColumnCard extends StatelessWidget {
  final EdgeInsets padding;
  final List<Widget> children;

  const PriorityColumnCard({
    super.key,
    required this.padding,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Padding(
        padding: padding,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
      ),
    );
  }
}
