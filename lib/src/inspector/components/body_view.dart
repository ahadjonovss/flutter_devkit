part of '../inspector_detail_page.dart';

class _BodyView extends StatelessWidget {
  const _BodyView({required this.body});

  final String? body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = body;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Body', style: theme.textTheme.titleSmall),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SelectableText(
            text == null || text.isEmpty ? '—' : HttpRecord.prettyBody(text),
            style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }
}
