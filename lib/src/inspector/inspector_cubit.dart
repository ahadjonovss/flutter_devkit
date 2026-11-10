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
    _subscription = _store.stream.listen((records) => emit(state.copyWith(records: records)));
  }

  final InspectorStore _store;
  late final StreamSubscription<List<HttpRecord>> _subscription;

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
    await _subscription.cancel();
    return super.close();
  }
}
