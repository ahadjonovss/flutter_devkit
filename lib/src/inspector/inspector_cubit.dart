import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_devkit/src/inspector/http_record.dart';
import 'package:flutter_devkit/src/inspector/inspector_store.dart';

enum StatusFilter { all, errors, failed }

class InspectorState {
  const InspectorState({
    this.records = const [],
    this.status = StatusFilter.all,
    this.method,
    this.query = '',
  });

  final List<HttpRecord> records;
  final StatusFilter status;
  final String? method;
  final String query;

  List<String> get methods => {for (final r in records) r.method}.toList()..sort();

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

class InspectorCubit extends Cubit<InspectorState> {
  InspectorCubit(this._store) : super(InspectorState(records: _store.records)) {
    _subscription = _store.stream.listen((records) => emit(state.copyWith(records: records)));
  }

  final InspectorStore _store;
  late final StreamSubscription<List<HttpRecord>> _subscription;

  void setStatus(StatusFilter status) => emit(state.copyWith(status: status));

  void setMethod(String? method) => emit(state.copyWith(method: () => method));

  void setQuery(String query) => emit(state.copyWith(query: query));

  void clear() => _store.clear();

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
