import 'package:flutter/material.dart';

/// One selectable option in a [showChoiceDialog].
class ChoiceOption<T> {
  final T value;
  final String label;
  final String? subtitle;

  /// Optional extra widget at the end of the row (e.g. a sound preview button).
  final Widget? trailing;

  const ChoiceOption(this.value, this.label, {this.subtitle, this.trailing});
}

/// Shows a single-choice radio dialog and returns the picked value, or null
/// if the dialog was dismissed. Long option lists scroll.
Future<T?> showChoiceDialog<T>({
  required BuildContext context,
  required String title,
  required T current,
  required List<ChoiceOption<T>> options,
  String? description,
}) {
  return showDialog<T>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      contentPadding: const EdgeInsets.only(top: 12, bottom: 8),
      content: SizedBox(
        width: double.maxFinite,
        child: RadioGroup<T>(
          groupValue: current,
          onChanged: (value) => Navigator.pop(context, value),
          child: ListView(
            shrinkWrap: true,
            children: [
              if (description != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                  child: Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              for (final option in options)
                RadioListTile<T>(
                  value: option.value,
                  title: Text(option.label),
                  subtitle: option.subtitle == null
                      ? null
                      : Text(option.subtitle!),
                  secondary: option.trailing,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
}
