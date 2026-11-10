part of '../inspector_page.dart';

class _FilterBar extends StatefulWidget {
  const _FilterBar({required this.state, required this.cubit});

  final InspectorState state;
  final InspectorCubit cubit;

  @override
  State<_FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<_FilterBar> {
  late final TextEditingController _controller = TextEditingController(text: widget.state.query);

  static const Map<StatusFilter, String> _labels = {
    StatusFilter.all: 'All',
    StatusFilter.errors: 'Errors',
    StatusFilter.failed: 'Failed',
  };

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _count(StatusFilter filter) {
    final records = widget.state.records;
    return switch (filter) {
      StatusFilter.all => records.length,
      StatusFilter.errors => records.where((r) => r.isError).length,
      StatusFilter.failed => records.where((r) => r.isFailed).length,
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final cubit = widget.cubit;
    final methods = state.methods;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Column(
        children: [
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, _) => TextField(
              controller: _controller,
              onChanged: cubit.setQuery,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Filter by URL',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: value.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _controller.clear();
                          cubit.setQuery('');
                        },
                      ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final entry in _labels.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      visualDensity: VisualDensity.compact,
                      label: Text('${entry.value} ${_count(entry.key)}'),
                      selected: state.status == entry.key,
                      onSelected: (_) => cubit.setStatus(entry.key),
                    ),
                  ),
                if (methods.isNotEmpty) const VerticalDivider(width: 14, indent: 8, endIndent: 8),
                for (final method in methods)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      visualDensity: VisualDensity.compact,
                      label: Text(method),
                      labelStyle: TextStyle(color: devKitMethodColor(method), fontWeight: FontWeight.w600),
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
