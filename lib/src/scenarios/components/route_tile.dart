part of '../scenario_page.dart';

class _RouteTile extends StatelessWidget {
  const _RouteTile({
    required this.route,
    required this.selectedCaseId,
    required this.onChanged,
    required this.custom,
    required this.onDeleteCase,
    required this.onDeleteRoute,
  });

  final ScenarioRoute route;
  final String? selectedCaseId;
  final ValueChanged<String?> onChanged;

  /// Whether QA added the route at runtime, so it can be deleted.
  final bool custom;
  final ValueChanged<String> onDeleteCase;
  final VoidCallback onDeleteRoute;

  static final RegExp _methodPrefix = RegExp(r'^(GET|POST|PUT|PATCH|DELETE|HEAD|OPTIONS)\s+', caseSensitive: false);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = selectedCaseId == null ? null : route.caseById(selectedCaseId!);
    final overridden = selected != null;

    // A label like `POST /auth/login` shows its method as a badge.
    final prefix = _methodPrefix.firstMatch(route.label);
    final method = prefix?.group(1)?.toUpperCase() ?? route.match.method;
    final path = prefix == null ? route.label : route.label.substring(prefix.end);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: overridden ? devKitWarningColor.withValues(alpha: 0.06) : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: overridden ? devKitWarningColor : theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
          width: overridden ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (method != null) ...[
                DevKitBadge(label: method, color: devKitMethodColor(method)),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  path,
                  style: devKitMono(theme.textTheme.titleSmall),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (overridden)
                IconButton(
                  tooltip: 'Back to real backend',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.restart_alt_rounded, size: 20),
                  onPressed: () => onChanged(null),
                ),
              if (custom)
                PopupMenuButton<void Function()>(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.more_vert_rounded, size: 20),
                  onSelected: (action) => action(),
                  itemBuilder: (_) => [
                    for (final scenario in route.cases)
                      PopupMenuItem(value: () => onDeleteCase(scenario.id), child: Text('Delete "${scenario.label}"')),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: onDeleteRoute,
                      child: Text('Delete route', style: TextStyle(color: theme.colorScheme.error)),
                    ),
                  ],
                ),
            ],
          ),
          // Custom ids are generated and mean nothing to QA.
          if (custom)
            DevKitBadge(label: 'CUSTOM', color: theme.colorScheme.tertiary)
          else
            Text(route.id, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _CaseChip(label: 'Real backend', selected: !overridden, onSelected: () => onChanged(null)),
              for (final scenario in route.cases)
                _CaseChip(
                  label: scenario.mock == null ? scenario.label : '${scenario.label} · ${scenario.mock!.statusCode}',
                  icon: scenario.mock == null ? null : Icons.inventory_2_outlined,
                  selected: selected?.id == scenario.id,
                  warning: true,
                  onSelected: () => onChanged(scenario.id),
                ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topLeft,
            child: selected?.description == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, size: 16, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            selected!.description!,
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CaseChip extends StatelessWidget {
  const _CaseChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.warning = false,
    this.icon,
  });

  final String label;

  /// Marks a case answered by a local mock.
  final IconData? icon;
  final bool selected;
  final bool warning;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = warning ? devKitWarningColor : scheme.primary;
    return ChoiceChip(
      avatar: icon == null ? null : Icon(icon, size: 16, color: selected ? color : scheme.onSurfaceVariant),
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: color.withValues(alpha: 0.16),
      side: BorderSide(color: selected ? color : scheme.outlineVariant),
      labelStyle: TextStyle(color: selected ? color : null, fontWeight: selected ? FontWeight.w600 : null),
    );
  }
}
