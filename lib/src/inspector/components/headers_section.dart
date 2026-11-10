part of '../inspector_detail_page.dart';

class _HeadersSection extends StatelessWidget {
  const _HeadersSection({required this.headers});

  final RecordHeaders headers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mono = theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace');

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Headers', style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          if (headers.isEmpty)
            Text('—', style: mono)
          else
            SelectableText.rich(
              TextSpan(
                children: [
                  for (final (index, header) in headers.indexed) ...[
                    if (index > 0) const TextSpan(text: '\n'),
                    TextSpan(text: '${header.key}: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: header.value),
                  ],
                ],
              ),
              style: mono,
            ),
        ],
      ),
    );
  }
}
