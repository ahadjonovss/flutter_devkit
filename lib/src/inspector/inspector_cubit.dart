import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_devkit/src/inspector/http_record.dart';
import 'package:flutter_devkit/src/inspector/inspector_store.dart';

/// Which records the inspector list shows by outcome.
enum StatusFilter {
  /// Every record.
  all,

  /// Failed requests and 4xx/5xx responses.
  errors,

  /// Requests that got no response at all.
  failed,
}

/// What the inspector list shows: all records plus the active filters.
class InspectorState {
  /// Creates a state with the given records and filters.
  const InspectorState({this.records = const [], this.status = StatusFilter.all, this.method, this.query = ''});

  /// All recorded requests, newest first.
  final List<HttpRecord> records;

  /// Active status filter.
  final StatusFilter status;

  /// Method to show, or null for every method.
  final String? method;

  /// Case-insensitive URL search text.
  final String query;

  /// Methods present in [records], sorted, for the method chips.
  List<String> get methods => {for (final r in records) r.method}.toList()..sort();

  /// The [records] that pass every active filter.
  List<HttpRecord> get visible {
    final needle = query.toLowerCase();
    return [
      for (final r in records)
        if (_matchesStatus(r) &&
            (method == null || r.method == method) &&
            (needle.isEmpty || r.url.toLowerCase().contains(needle)))
          r,
    ];
  }

  bool _matchesStatus(HttpRecord r) => switch (status) {
    StatusFilter.all => true,
    StatusFilter.errors => r.isError,
    StatusFilter.failed => r.isFailed,
  };

  /// Returns a copy with the given fields replaced. [method] is a function so
  /// that it can be reset to null.
  InspectorState copyWith({
    List<HttpRecord>? records,
    StatusFilter? status,
    String? Function()? method,
    String? query,
  }) {
    return InspectorState(
      records: records ?? this.records,
      status: status ?? this.status,
      method: method == null ? this.method : method(),
      query: query ?? this.query,
    );
  }
}

/// Keeps the inspector list in sync with an [InspectorStore] and holds its
/// filters.
class InspectorCubit extends Cubit<InspectorState> {
  /// Starts from the store's current records and follows its stream.
  InspectorCubit(this._store) : super(InspectorState(records: _store.records)) {
    _subscription = _store.stream.listen((_) => _refresh());
  }

  /// Shortest gap between two list updates while requests keep arriving.
  static const Duration _throttle = Duration(milliseconds: 100);

  final InspectorStore _store;
  late final StreamSubscription<List<HttpRecord>> _subscription;
  Timer? _timer;
  bool _pending = false;

  // Every request changes the store twice, so a burst of traffic would rebuild
  // the list for each one. The first change shows at once; changes arriving
  // within [_throttle] of it are folded into a single update.
  void _refresh() {
    if (_timer != null) {
      _pending = true;
      return;
    }
    emit(state.copyWith(records: _store.records));
    _timer = Timer(_throttle, () {
      _timer = null;
      if (_pending && !isClosed) {
        _pending = false;
        _refresh();
      }
    });
  }

  /// Shows only the records that match [status].
  void setStatus(StatusFilter status) => emit(state.copyWith(status: status));

  /// Shows only [method], or every method when null.
  void setMethod(String? method) => emit(state.copyWith(method: () => method));

  /// Shows only the records whose URL contains [query].
  void setQuery(String query) => emit(state.copyWith(query: query));

  /// Removes every record from the store.
  void clear() => _store.clear();

  @override
  Future<void> close() async {
    _timer?.cancel();
    await _subscription.cancel();
    return super.close();
  }
}
