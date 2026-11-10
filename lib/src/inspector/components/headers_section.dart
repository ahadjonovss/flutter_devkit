part of '../inspector_detail_page.dart';

class _HeadersSection extends StatelessWidget {
  const _HeadersSection({required this.headers});

  final RecordHeaders headers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mono = devKitMono(theme.textTheme.bodySmall);

    return DevKitSection(
      title: 'Headers (${headers.length})',
      trailing: headers.isEmpty
          ? null
          : _CopyButton(text: [for (final h in headers) '${h.key}: ${h.value}'].join('\n'), message: 'Headers copied'),
      child: headers.isEmpty
          ? Text('No headers', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline))
          // One selectable text, so a drag can select several headers at once.
          : SelectableText.rich(
              TextSpan(
                children: [
                  for (final (index, header) in headers.indexed) ...[
                    if (index > 0) const TextSpan(text: '\n'),
                    TextSpan(
                      text: '${header.key}: ',
                      style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                    ),
                    TextSpan(text: header.value),
                  ],
                ],
              ),
              style: mono?.copyWith(height: 1.6),
            ),
    );
  }
}
