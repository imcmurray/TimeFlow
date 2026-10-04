import 'package:flutter/material.dart';
import 'package:timeflow/domain/entities/recurrence_rule.dart';
import 'package:timeflow/domain/time/local_date.dart';
import 'package:timeflow/presentation/utils/recurrence_format.dart';

/// The "Repeat" field of the task editor: a list of common patterns, a
/// custom option, and an optional end date.
class RecurrencePicker extends StatelessWidget {
  final RecurrenceRule? value;

  /// Date of the (first) occurrence; patterns are described relative to it.
  final LocalDate start;
  final ValueChanged<RecurrenceRule?> onChanged;
  final bool enabled;

  const RecurrencePicker({
    super.key,
    required this.value,
    required this.start,
    required this.onChanged,
    this.enabled = true,
  });

  List<RecurrenceRule> get _presets => [
    RecurrenceRule.daily,
    RecurrenceRule.weekdaysOnly,
    RecurrenceRule.weekly,
    RecurrenceRule.fortnightly,
    RecurrenceRule.monthly,
    RecurrenceRule.yearly,
  ];

  Future<void> _pick(BuildContext context) async {
    final current = value;
    final result = await showModalBottomSheet<_Pick>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _tile(context, null, 'Does not repeat', current == null),
              for (final p in _presets)
                _tile(
                  context,
                  p,
                  describeRecurrence(p, start),
                  current != null && current.samePatternAs(p),
                ),
              ListTile(
                leading: const Icon(Icons.tune),
                title: const Text('Custom…'),
                onTap: () => Navigator.pop(context, const _Pick.custom()),
              ),
            ],
          ),
        ),
      ),
    );
    if (result == null || !context.mounted) return;
    if (result.custom) {
      final custom = await showDialog<RecurrenceRule>(
        context: context,
        builder: (_) => _CustomRuleDialog(
          initial: current ?? RecurrenceRule.weekly,
          start: start,
        ),
      );
      if (custom != null) onChanged(custom.copyWith(until: current?.until));
      return;
    }
    // Keep the end date when switching between patterns.
    onChanged(result.rule?.copyWith(until: current?.until));
  }

  Widget _tile(
    BuildContext context,
    RecurrenceRule? rule,
    String label,
    bool selected,
  ) => ListTile(
    leading: Icon(
      selected ? Icons.radio_button_checked : Icons.radio_button_off,
    ),
    title: Text(label),
    selected: selected,
    onTap: () => Navigator.pop(context, _Pick(rule)),
  );

  Future<void> _pickEnd(BuildContext context) async {
    final rule = value!;
    final picked = await showDatePicker(
      context: context,
      helpText: 'Repeat until',
      initialDate: (rule.until ?? start.addDays(30)).startOfDay,
      firstDate: start.startOfDay,
      lastDate: start.addDays(365 * 20).startOfDay,
    );
    if (picked != null) onChanged(rule.endingOn(LocalDate.of(picked)));
  }

  @override
  Widget build(BuildContext context) {
    final rule = value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InputDecorator(
          decoration: InputDecoration(
            labelText: 'Repeat',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.repeat),
            enabled: enabled,
            helperText: enabled
                ? null
                : 'Choose "this and later" to change the pattern',
          ),
          child: InkWell(
            onTap: enabled ? () => _pick(context) : null,
            child: Text(
              rule == null
                  ? 'Does not repeat'
                  : describeRecurrence(rule.copyWith(clearUntil: true), start),
            ),
          ),
        ),
        if (rule != null && enabled)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Text('Ends', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('Never'),
                  selected: rule.until == null,
                  onSelected: (_) => onChanged(rule.copyWith(clearUntil: true)),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(
                    rule.until == null
                        ? 'On a date'
                        : MaterialLocalizations.of(
                            context,
                          ).formatMediumDate(rule.until!.startOfDay),
                  ),
                  selected: rule.until != null,
                  onSelected: (_) => _pickEnd(context),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Pick {
  final RecurrenceRule? rule;
  final bool custom;
  const _Pick(this.rule) : custom = false;
  const _Pick.custom() : rule = null, custom = true;
}

class _CustomRuleDialog extends StatefulWidget {
  final RecurrenceRule initial;
  final LocalDate start;

  const _CustomRuleDialog({required this.initial, required this.start});

  @override
  State<_CustomRuleDialog> createState() => _CustomRuleDialogState();
}

class _CustomRuleDialogState extends State<_CustomRuleDialog> {
  late Frequency _frequency = widget.initial.frequency;
  late int _interval = widget.initial.interval;
  late Set<int> _weekdays = widget.initial.weekdays.isEmpty
      ? {widget.start.weekday}
      : {...widget.initial.weekdays};

  String _unit(Frequency f) => switch (f) {
    Frequency.daily => _interval == 1 ? 'day' : 'days',
    Frequency.weekly => _interval == 1 ? 'week' : 'weeks',
    Frequency.monthly => _interval == 1 ? 'month' : 'months',
    Frequency.yearly => _interval == 1 ? 'year' : 'years',
  };

  RecurrenceRule get _rule => RecurrenceRule(
    frequency: _frequency,
    interval: _interval,
    weekdays: _frequency == Frequency.weekly ? _weekdays : const {},
  );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Custom repeat'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Every'),
              IconButton(
                icon: const Icon(Icons.remove),
                tooltip: 'Fewer',
                onPressed: _interval > 1
                    ? () => setState(() => _interval--)
                    : null,
              ),
              Text(
                '$_interval',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'More',
                onPressed: _interval < 99
                    ? () => setState(() => _interval++)
                    : null,
              ),
              DropdownButton<Frequency>(
                value: _frequency,
                onChanged: (f) => setState(() => _frequency = f!),
                items: [
                  for (final f in Frequency.values)
                    DropdownMenuItem(value: f, child: Text(_unit(f))),
                ],
              ),
            ],
          ),
          if (_frequency == Frequency.weekly) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (var d = DateTime.monday; d <= DateTime.sunday; d++)
                  FilterChip(
                    label: Text(weekdayShort(d)),
                    selected: _weekdays.contains(d),
                    onSelected: (on) => setState(() {
                      final next = {..._weekdays};
                      on ? next.add(d) : next.remove(d);
                      if (next.isNotEmpty) _weekdays = next;
                    }),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Text(
            describeRecurrence(_rule, widget.start),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _rule),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
