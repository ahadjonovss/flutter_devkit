part of '../inspector_page.dart';

class _RecordTile extends StatelessWidget {
  const _RecordTile({super.key, required this.record, required this.onTap});

  final HttpRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final status = record.isPending ? '···' : record.statusCode?.toString() ?? 'ERR';
    final uri = Uri.tryParse(record.url);
    final responseLength = record.responseBody?.length;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
          children: [
            DevKitBadge(label: status, color: devKitStatusColor(record), minWidth: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        record.method,
                        style: devKitMono(
                          theme.textTheme.labelMedium,
                        )?.copyWith(color: devKitMethodColor(record.method), fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          record.path,
                          style: devKitMono(theme.textTheme.bodyMedium),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          [
                            if (uri != null && uri.host.isNotEmpty) uri.host,
                            devKitTime(record.startedAt),
                            if (record.duration != null) devKitDuration(record.duration!),
                            if (responseLength != null && responseLength > 0) devKitSize(responseLength),
                          ].join(' · '),
                          style: muted,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (record.scenario != null) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.alt_route_rounded, size: 14, color: devKitWarningColor),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, size: 20, color: theme.colorScheme.outline),
          ],
        ),
      ),
    );
  }
}
