part of '../inspector_detail_page.dart';

class _OverviewSection extends StatelessWidget {
  const _OverviewSection({required this.record});

  final HttpRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = <(String, String, Color?)>[
      ('URL', record.url, null),
      ('Method', record.method, null),
      (
        'Status',
        record.isPending ? 'pending' : record.statusCode?.toString() ?? 'failed',
        devKitStatusColor(record),
      ),
      ('Time', devKitTime(record.startedAt), null),
      if (record.duration != null) ('Duration', '${record.duration!.inMilliseconds} ms', null),
      if (record.scenario != null) ('Scenario', record.scenario!, devKitWarningColor),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (label, value, color) in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 72, child: Text(label, style: theme.textTheme.bodySmall)),
                  Expanded(
                    child: SelectableText(
                      value,
                      style: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace', color: color),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
