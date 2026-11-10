part of '../inspector_page.dart';

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.record, required this.onTap});

  final HttpRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mono = theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace');
    final status = record.isPending
        ? '…'
        : record.statusCode?.toString() ?? 'ERR';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 40,
              child: Text(
                status,
                style: mono?.copyWith(
                  color: devKitStatusColor(record),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${record.method} ${record.path}',
                    style: mono,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        [
                          devKitTime(record.startedAt),
                          if (record.duration != null) '${record.duration!.inMilliseconds} ms',
                        ].join(' · '),
                        style: theme.textTheme.bodySmall,
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
          ],
        ),
      ),
    );
  }
}
