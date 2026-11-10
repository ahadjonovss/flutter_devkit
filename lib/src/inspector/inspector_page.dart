import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_devkit/src/devkit.dart';
import 'package:flutter_devkit/src/inspector/http_record.dart';
import 'package:flutter_devkit/src/inspector/inspector_cubit.dart';
import 'package:flutter_devkit/src/inspector/inspector_detail_page.dart';
import 'package:flutter_devkit/src/panel/devkit_theme.dart';

part 'components/filter_bar.dart';
part 'components/record_tile.dart';

class InspectorPage extends StatelessWidget {
  const InspectorPage({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => Theme(
          data: devKitTheme,
          child: BlocProvider(
            create: (_) => InspectorCubit(DevKit.inspector),
            child: const InspectorPage(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InspectorCubit, InspectorState>(
      builder: (context, state) {
        final cubit = context.read<InspectorCubit>();
        final visible = state.visible;
        return Scaffold(
          appBar: AppBar(
            title: const Text('HTTP inspector'),
            actions: [
              TextButton(
                onPressed: state.records.isEmpty ? null : cubit.clear,
                child: const Text('Clear'),
              ),
            ],
          ),
          body: Column(
            children: [
              _FilterBar(state: state, cubit: cubit),
              const Divider(height: 1),
              Expanded(
                child: visible.isEmpty
                    ? const Center(child: Text('No requests'))
                    : ListView.separated(
                        itemCount: visible.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) => _RecordTile(
                          record: visible[index],
                          onTap: () => InspectorDetailPage.open(context, visible[index].id),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
