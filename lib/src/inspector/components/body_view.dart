part of '../inspector_detail_page.dart';

class _BodyView extends StatefulWidget {
  const _BodyView({required this.body});

  final String? body;

  @override
  State<_BodyView> createState() => _BodyViewState();
}

class _BodyViewState extends State<_BodyView> {
  /// Longest pretty body that gets syntax colours; past it colouring costs
  /// more than it helps and the text is shown plain.
  static const int _highlightLimit = 48 * 1024;

  // Pretty-printing and colouring run once per body, not on every build.
  String _text = '';
  bool _isJson = false;
  TextSpan? _highlighted;
  Brightness? _highlightedFor;

  @override
  void initState() {
    super.initState();
    _format();
  }

  @override
  void didUpdateWidget(_BodyView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.body != widget.body) _format();
  }

  void _format() {
    final body = widget.body;
    _highlighted = null;
    if (body == null || body.isEmpty) {
      _text = '';
      _isJson = false;
      return;
    }
    try {
      _text = const JsonEncoder.withIndent('  ').convert(jsonDecode(body));
      _isJson = true;
    } on FormatException {
      _text = body;
      _isJson = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mono = devKitMono(theme.textTheme.bodySmall)?.copyWith(height: 1.5);

    final Widget content;
    if (_text.isEmpty) {
      content = Text('No body', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline));
    } else if (_isJson && _text.length <= _highlightLimit) {
      if (_highlighted == null || _highlightedFor != theme.brightness) {
        _highlighted = _highlight(_text, theme);
        _highlightedFor = theme.brightness;
      }
      content = SelectableText.rich(_highlighted!, style: mono);
    } else {
      content = SelectableText(_text, style: mono);
    }

    return DevKitSection(
      title: _text.isEmpty ? 'Body' : 'Body · ${_isJson ? 'JSON' : 'text'} · ${devKitSize(widget.body!.length)}',
      trailing: _text.isEmpty ? null : _CopyButton(text: _text, message: 'Body copied'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: content,
      ),
    );
  }

  static final RegExp _token = RegExp(
    r'("(?:\\.|[^"\\])*")(\s*:)?|\b(true|false|null)\b|(-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)',
  );

  static TextSpan _highlight(String json, ThemeData theme) {
    final dark = theme.brightness == Brightness.dark;
    final keyStyle = TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600);
    final stringStyle = TextStyle(color: dark ? const Color(0xFF81C784) : const Color(0xFF2E7D32));
    final numberStyle = TextStyle(color: dark ? const Color(0xFFFFB74D) : const Color(0xFFE65100));
    final literalStyle = TextStyle(color: dark ? const Color(0xFFCE93D8) : const Color(0xFF8E24AA));

    final spans = <TextSpan>[];
    var last = 0;
    for (final match in _token.allMatches(json)) {
      if (match.start > last) spans.add(TextSpan(text: json.substring(last, match.start)));
      final string = match.group(1);
      if (string != null) {
        final isKey = match.group(2) != null;
        spans.add(TextSpan(text: string, style: isKey ? keyStyle : stringStyle));
        if (isKey) spans.add(TextSpan(text: match.group(2)));
      } else if (match.group(3) != null) {
        spans.add(TextSpan(text: match.group(3), style: literalStyle));
      } else {
        spans.add(TextSpan(text: match.group(4), style: numberStyle));
      }
      last = match.end;
    }
    if (last < json.length) spans.add(TextSpan(text: json.substring(last)));
    return TextSpan(children: spans);
  }
}
