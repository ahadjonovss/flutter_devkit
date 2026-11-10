import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_devkit/src/devkit.dart';
import 'package:flutter_devkit/src/inspector/http_record.dart';
import 'package:flutter_devkit/src/panel/devkit_theme.dart';

part 'components/body_view.dart';
part 'components/headers_section.dart';
part 'components/overview_section.dart';

class InspectorDetailPage extends StatelessWidget {
  const InspectorDetailPage({super.key, required this.id});

  final int id;

  static Future<void> open(BuildContext context, int id) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Theme(data: devKitTheme, child: InspectorDetailPage(id: id)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = DevKit.inspector;
    // Records are replaced, never mutated, so identity tells whether this one
    // changed; traffic to other requests does not rebuild the page.
    return StreamBuilder<HttpRecord?>(
      initialData: store.byId(id),
      stream: store.stream.map((_) => store.byId(id)).distinct(identical),
      builder: (context, snapshot) {
        final record = snapshot.data;
        if (record == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Request was removed')),
          );
        }
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: Text('${record.method} ${record.path}', maxLines: 1, overflow: TextOverflow.ellipsis),
              actions: [
                IconButton(
                  tooltip: 'Copy as cURL',
                  icon: const Icon(Icons.terminal_rounded),
                  onPressed: () => _copy(context, record.toCurl(), 'cURL copied'),
                ),
                IconButton(
                  tooltip: 'Copy all',
                  icon: const Icon(Icons.copy_all_rounded),
                  onPressed: () => _copy(context, record.toText(), 'Request copied'),
                ),
              ],
              bottom: const TabBar(tabs: [Tab(text: 'Request'), Tab(text: 'Response')]),
            ),
            body: TabBarView(
              children: [
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _OverviewSection(record: record),
                    _HeadersSection(headers: record.requestHeaders),
                    _BodyView(body: record.requestBody),
                  ],
                ),
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (record.error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: SelectableText(
                          record.error!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                    _HeadersSection(headers: record.responseHeaders),
                    _BodyView(body: record.responseBody),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _copy(BuildContext context, String text, String message) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
