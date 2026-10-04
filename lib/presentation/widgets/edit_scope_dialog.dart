import 'package:flutter/material.dart';
import 'package:timeflow/services/task_service.dart';

/// Asks which occurrences of a repeating task a change applies to.
/// Returns null if the user cancels.
///
/// [verb] completes "Which tasks do you want to …?" (e.g. 'change', 'delete').
/// [allowAll] offers "All tasks in the series" as well.
Future<EditScope?> showEditScopeDialog(
  BuildContext context, {
  required String verb,
  bool allowAll = true,
}) {
  return showDialog<EditScope>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text('This is a repeating task'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Text('Which tasks do you want to $verb?'),
        ),
        _option(context, EditScope.thisOnly, 'Only this one'),
        _option(context, EditScope.thisAndFuture, 'This and all later ones'),
        if (allowAll)
          _option(context, EditScope.all, 'Every task in the series'),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _option(BuildContext context, EditScope scope, String label) =>
    SimpleDialogOption(
      onPressed: () => Navigator.pop(context, scope),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
    );
