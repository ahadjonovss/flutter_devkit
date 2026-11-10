import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_devkit/src/devkit.dart';
import 'package:flutter_devkit/src/inspector/http_record.dart';
import 'package:flutter_devkit/src/inspector/inspector_cubit.dart';
import 'package:flutter_devkit/src/inspector/inspector_detail_page.dart';
import 'package:flutter_devkit/src/panel/devkit_theme.dart';

part 'components/filter_bar.dart';
part 'components/record_tile.dart';

/// List of recorded requests with URL search and status and method filters.
class InspectorPage extends StatelessWidget {
  /// Creates the page; it expects an `InspectorCubit` above it, so prefer [open].
  const InspectorPage({super.key});

  /// Pushes the inspector on the root navigator.
  static Future<void> open(BuildContext context) {
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => DevKitTheme(
          child: BlocProvider(create: (_) => InspectorCubit(DevKit.inspector), child: const InspectorPage()),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<InspectorCubit>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('HTTP inspector'),
        actions: [
          BlocSelector<InspectorCubit, InspectorState, bool>(
            selector: (state) => state.records.isEmpty,
            builder: (context, empty) => IconButton(
              tooltip: 'Clear',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: empty ? null : cubit.clear,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: BlocBuilder<InspectorCubit, InspectorState>(
        builder: (context, state) {
          final visible = state.visible;
          return Column(
            children: [
              _FilterBar(state: state, cubit: cubit),
              const Divider(),
              Expanded(
                child: visible.isEmpty
                    ? DevKitEmpty(
                        icon: Icons.wifi_tethering_off_rounded,
                        message: state.records.isEmpty ? 'No requests yet' : 'No requests match the filters',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: visible.length,
                        separatorBuilder: (_, _) => const Divider(indent: 16, endIndent: 16),
                        itemBuilder: (context, index) {
                          final record = visible[index];
                          return _RecordTile(
                            key: ValueKey(record.id),
                            record: record,
                            onTap: () => InspectorDetailPage.open(context, record.id),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
