import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_devkit/src/devkit.dart';
import 'package:flutter_devkit/src/inspector/http_record.dart';
import 'package:flutter_devkit/src/panel/devkit_theme.dart';

part 'components/body_view.dart';
part 'components/headers_section.dart';
part 'components/overview_section.dart';

/// Request and response details of one record, with copy actions.
class InspectorDetailPage extends StatefulWidget {
  /// Shows the record with [id].
  const InspectorDetailPage({super.key, required this.id});

  /// Id of the record to show.
  final int id;

  /// Pushes the page for the record with [id].
  static Future<void> open(BuildContext context, int id) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DevKitTheme(child: InspectorDetailPage(id: id)),
      ),
    );
  }

  @override
  State<InspectorDetailPage> createState() => _InspectorDetailPageState();
}

class _InspectorDetailPageState extends State<InspectorDetailPage> {
  late HttpRecord? _record = DevKit.inspector.byId(widget.id);
  late final StreamSubscription<List<HttpRecord>> _subscription;

  @override
  void initState() {
    super.initState();
    // Records are replaced, never mutated, so identity tells whether this one
    // changed; traffic to other requests does not rebuild the page.
    _subscription = DevKit.inspector.stream.listen((_) {
      final record = DevKit.inspector.byId(widget.id);
      if (!identical(record, _record)) setState(() => _record = record);
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final record = _record;
    if (record == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const DevKitEmpty(icon: Icons.delete_outline_rounded, message: 'Request was removed'),
      );
    }
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: Row(
            children: [
              DevKitBadge(label: record.method, color: devKitMethodColor(record.method)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  record.path,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: devKitMono(theme.textTheme.titleSmall),
                ),
              ),
            ],
          ),
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
            const SizedBox(width: 4),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Request'),
              Tab(text: 'Response'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _Tab(children: [_OverviewSection(record: record)]),
            _Tab(
              children: [
                _HeadersSection(headers: record.requestHeaders),
                _BodyView(body: record.requestBody),
              ],
            ),
            _Tab(
              children: [
                if (record.error != null) _ErrorCard(error: record.error!),
                if (record.isPending)
                  const DevKitEmpty(icon: Icons.hourglass_top_rounded, message: 'Waiting for the response…')
                else ...[
                  _HeadersSection(headers: record.responseHeaders),
                  _BodyView(body: record.responseBody),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), children: children);
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(14)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, color: scheme.onErrorContainer, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: SelectableText(error, style: TextStyle(color: scheme.onErrorContainer)),
            ),
          ],
        ),
      ),
    );
  }
}

/// A copy button for a section header.
class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.text, required this.message});

  final String text;
  final String message;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Copy',
      visualDensity: VisualDensity.compact,
      iconSize: 18,
      icon: const Icon(Icons.copy_rounded),
      onPressed: () => _copy(context, text, message),
    );
  }
}

/// Copies [text] to the clipboard and confirms with a short [message].
Future<void> _copy(BuildContext context, String text, String message) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), duration: const Duration(milliseconds: 1500)));
}
