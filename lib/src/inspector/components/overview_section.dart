part of '../inspector_detail_page.dart';

class _OverviewSection extends StatelessWidget {
  const _OverviewSection({required this.record});

  final HttpRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = devKitStatusColor(record);
    final code = record.statusCode ?? 0;
    final status = switch (record) {
      _ when record.isPending => 'Pending',
      _ when record.isFailed => 'No response',
      _ when code >= 500 => 'Server error',
      _ when code >= 400 => 'Client error',
      _ when code >= 300 => 'Redirect',
      _ => 'Success',
    };
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final rows = <(String, String, Color?)>[
      ('Method', record.method, devKitMethodColor(record.method)),
      ('Started', devKitTime(record.startedAt), null),
      if (record.duration != null) ('Duration', devKitDuration(record.duration!), null),
      if (record.requestBody != null) ('Request', devKitSize(record.requestBody!.length), null),
      if (record.responseBody != null) ('Response', devKitSize(record.responseBody!.length), null),
      if (record.scenario != null) ('Scenario', record.scenario!, devKitWarningColor),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: record.isPending
                        ? SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: statusColor),
                          )
                        : Text(
                            record.statusCode?.toString() ?? '!',
                            style: devKitMono(
                              theme.textTheme.titleMedium,
                            )?.copyWith(color: statusColor, fontWeight: FontWeight.w800),
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          status,
                          style: theme.textTheme.titleMedium?.copyWith(color: statusColor, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            devKitTime(record.startedAt),
                            if (record.duration != null) devKitDuration(record.duration!),
                          ].join(' · '),
                          style: muted,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (record.error != null) _ErrorCard(error: record.error!),
        DevKitSection(
          title: 'URL',
          trailing: _CopyButton(text: record.url, message: 'URL copied'),
          child: SelectableText(record.url, style: devKitMono(theme.textTheme.bodyMedium)),
        ),
        DevKitSection(
          title: 'Details',
          child: Column(
            children: [
              for (final (index, (label, value, color)) in rows.indexed)
                Padding(
                  padding: EdgeInsets.only(top: index == 0 ? 0 : 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 88, child: Text(label, style: muted)),
                      Expanded(
                        child: SelectableText(
                          value,
                          style: devKitMono(
                            theme.textTheme.bodyMedium,
                          )?.copyWith(color: color, fontWeight: color == null ? null : FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
