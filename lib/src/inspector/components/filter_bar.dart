part of '../inspector_page.dart';

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.state, required this.cubit});

  final InspectorState state;
  final InspectorCubit cubit;

  static const Map<StatusFilter, String> _labels = {
    StatusFilter.all: 'All',
    StatusFilter.errors: 'Errors',
    StatusFilter.failed: 'Failed',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          TextField(
            onChanged: cubit.setQuery,
            decoration: const InputDecoration(
              isDense: true,
              hintText: 'Filter by URL',
              prefixIcon: Icon(Icons.search_rounded),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final entry in _labels.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(entry.value),
                      selected: state.status == entry.key,
                      onSelected: (_) => cubit.setStatus(entry.key),
                    ),
                  ),
                if (state.methods.isNotEmpty) const SizedBox(height: 24, child: VerticalDivider(width: 16)),
                for (final method in state.methods)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(method),
                      selected: state.method == method,
                      onSelected: (selected) => cubit.setMethod(selected ? method : null),
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
