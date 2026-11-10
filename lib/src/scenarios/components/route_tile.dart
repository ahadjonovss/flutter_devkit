part of '../scenario_page.dart';

class _RouteTile extends StatelessWidget {
  const _RouteTile({required this.route, required this.selectedCaseId, required this.onChanged});

  final ScenarioRoute route;
  final String? selectedCaseId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = selectedCaseId == null ? null : route.caseById(selectedCaseId!);
    final overridden = selected != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(route.label, style: theme.textTheme.titleSmall?.copyWith(fontFamily: 'monospace')),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            key: ValueKey('${route.id}:${selected?.id}'),
            initialValue: selected?.id,
            isExpanded: true,
            decoration: InputDecoration(
              isDense: true,
              border: const OutlineInputBorder(),
              enabledBorder: overridden
                  ? const OutlineInputBorder(borderSide: BorderSide(color: devKitWarningColor, width: 1.5))
                  : null,
            ),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('Real backend')),
              for (final scenario in route.cases)
                DropdownMenuItem<String?>(value: scenario.id, child: Text(scenario.label)),
            ],
            onChanged: onChanged,
          ),
          if (selected?.description != null) ...[
            const SizedBox(height: 6),
            Text(selected!.description!, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
