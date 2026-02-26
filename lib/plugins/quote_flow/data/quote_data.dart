import 'package:flutter/material.dart';
import 'package:cron_timeflow/core/plugins/plugin_interface.dart';

/// A quote with its intended time-of-day slot.
class QuoteEntry {
  final String quote;
  final String author;
  final int hour;

  const QuoteEntry(this.quote, this.author, this.hour);
}

/// Hardcoded quotes with time-of-day slots.
const _quotes = <QuoteEntry>[
  // Morning (7-9)
  QuoteEntry(
      'The secret of getting ahead is getting started.', 'Mark Twain', 7),
  QuoteEntry('Every morning brings new potential.', 'Unknown', 7),
  QuoteEntry(
      'An early-morning walk is a blessing for the whole day.', 'Thoreau', 8),
  QuoteEntry('The way to get started is to quit talking and begin doing.',
      'Walt Disney', 8),
  QuoteEntry(
      'Today is a new day. Don\'t let your history interfere with your destiny.',
      'Steve Maraboli',
      9),
  QuoteEntry('With the new day comes new strength and new thoughts.',
      'Eleanor Roosevelt', 9),
  QuoteEntry(
      'The only way to do great work is to love what you do.', 'Steve Jobs', 7),

  // Midday (12-13)
  QuoteEntry('It is never too late to be what you might have been.',
      'George Eliot', 12),
  QuoteEntry(
      'Believe you can and you\'re halfway there.', 'Theodore Roosevelt', 12),
  QuoteEntry(
      'In the middle of difficulty lies opportunity.', 'Albert Einstein', 13),
  QuoteEntry(
      'The best time to plant a tree was 20 years ago. The second best time is now.',
      'Chinese Proverb',
      13),
  QuoteEntry(
      'Success is not final, failure is not fatal: it is the courage to continue that counts.',
      'Winston Churchill',
      12),
  QuoteEntry('What we think, we become.', 'Buddha', 13),

  // Evening (18-20)
  QuoteEntry(
      'Rest is not idleness. It is the fuel for tomorrow.', 'Unknown', 18),
  QuoteEntry('Finish each day and be done with it.', 'Ralph Waldo Emerson', 18),
  QuoteEntry(
      'The only limit to our realization of tomorrow is our doubts of today.',
      'FDR',
      19),
  QuoteEntry('Happiness depends upon ourselves.', 'Aristotle', 19),
  QuoteEntry('Let the beauty of what you love be what you do.', 'Rumi', 20),
  QuoteEntry('Life is 10% what happens to us and 90% how we react to it.',
      'Charles R. Swindoll', 20),
  QuoteEntry('Well done is better than well said.', 'Benjamin Franklin', 18),
];

/// Generates quote timeline events for a date range.
class QuoteData {
  /// For each day in the range, produces one quote per time slot (morning, midday, evening).
  List<TimelineEvent> generate(DateTime from, DateTime until) {
    final events = <TimelineEvent>[];
    var current = DateTime(from.year, from.month, from.day);
    var quoteIndex = 0;

    while (current.isBefore(until)) {
      // Pick 3 quotes per day: morning, midday, evening
      for (final slotHour in [7, 12, 18]) {
        final eventTime = DateTime(
          current.year,
          current.month,
          current.day,
          slotHour,
        );
        if (eventTime.isBefore(from) || eventTime.isAfter(until)) continue;

        // Find a quote for this slot
        final candidates =
            _quotes.where((q) => (q.hour - slotHour).abs() <= 2).toList();
        if (candidates.isEmpty) continue;

        final entry = candidates[quoteIndex % candidates.length];
        quoteIndex++;

        final truncated = entry.quote.length > 40
            ? '${entry.quote.substring(0, 37)}...'
            : entry.quote;

        events.add(TimelineEvent(
          id: 'quote_${eventTime.toIso8601String()}',
          pluginId: 'quote_flow',
          title: truncated,
          subtitle: '— ${entry.author}',
          startTime: eventTime,
          color: Colors.teal,
          metadata: {
            'quote': entry.quote,
            'author': entry.author,
          },
        ));
      }
      current = current.add(const Duration(days: 1));
    }

    return events;
  }
}
