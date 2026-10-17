import 'package:flutter/material.dart';

/// The chosen value inside a field the user taps rather than types into, like
/// **Category** or **Repeat** in the task editor.
///
/// Both of those are an [InputDecorator] wrapping a tappable child instead of a
/// real input, and a bare [Text] in that position inherits the ambient
/// `bodyMedium` — which this app defines as secondary grey. The value then reads
/// as an empty placeholder: #43 reported it for Category, and the same shape had
/// quietly done it to Repeat as well. `titleMedium` is what the Reminder
/// dropdown next to them draws its value in, so the three pickers match.
class FieldValueText extends StatelessWidget {
  const FieldValueText(this.value, {super.key});

  final String value;

  @override
  Widget build(BuildContext context) => Text(
    value,
    overflow: TextOverflow.ellipsis,
    style: Theme.of(context).textTheme.titleMedium,
  );
}
