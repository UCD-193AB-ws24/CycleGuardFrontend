import 'dart:async';

import 'package:cycle_guard_app/data/navigation_accessor.dart';
import 'package:flutter/material.dart';

class RoutesAutofill extends StatefulWidget {
  const RoutesAutofill();

  @override
  State<RoutesAutofill> createState() => _RoutesAutofillState();
}


class _RoutesAutofillState extends State<RoutesAutofill> {
  // The query currently being searched for. If null, there is no pending
  // request.
  String? _currentQuery;

  // The most recent options received from the API.
  late Iterable<AutofillLocation> _lastOptions = <AutofillLocation>[];

  late final _Debounceable<Iterable<AutofillLocation>?, String> _debouncedSearch;

  // Calls the "remote" API to search with the given query. Returns null when
  // the call has been made obsolete.
  Future<Iterable<AutofillLocation>?> _search(String query) async {
    _currentQuery = query;

    // In a real application, there should be some error handling here.
    final Iterable<AutofillLocation> options = await _FakeAPI.search(_currentQuery!);

    // If another search happened after this one, throw away these options.
    if (_currentQuery != query) {
      return null;
    }
    _currentQuery = null;

    return options;
  }

  @override
  void initState() {
    super.initState();
    _debouncedSearch = _debounce<Iterable<AutofillLocation>?, String>(_search);
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<AutofillLocation>(
      // boxDecoration: BoxDecoration(
      //   color: Colors.white,
      //   borderRadius: BorderRadius.circular(12),
      //   boxShadow: [
      //     BoxShadow(
      //       color: Colors.black.withOpacity(0.1),
      //       blurRadius: 8.0,
      //       spreadRadius: 2.0,
      //       offset: Offset(0, 4),
      //     ),
      //   ],
      // ),
      displayStringForOption: (result) => result.name,
      optionsBuilder: (TextEditingValue textEditingValue) async {
        final Iterable<AutofillLocation>? options = await _debouncedSearch(textEditingValue.text);
        if (options == null) {
          return _lastOptions;
        }
        _lastOptions = options;
        return options;
      },
      onSelected: (AutofillLocation selection) {
        debugPrint('You just selected $selection');
      },
    );
  }
}

// Mimics a remote API.
class _FakeAPI {
  // Searches the options, but injects a fake "network" delay.
  static Future<List<AutofillLocation>> search(String query) async {
    if (query == '') {
      return const [];
    }
    final res = await NavigationAccessor.getAutofill(query);
    return res.results;
  }
}

typedef _Debounceable<S, T> = Future<S?> Function(T parameter);

/// Returns a new function that is a debounced version of the given function.
///
/// This means that the original function will be called only after no calls
/// have been made for the given Duration.
_Debounceable<S, T> _debounce<S, T>(_Debounceable<S?, T> function) {
  _DebounceTimer? debounceTimer;

  return (T parameter) async {
    if (debounceTimer != null && !debounceTimer!.isCompleted) {
      debounceTimer!.cancel();
    }
    debounceTimer = _DebounceTimer();
    try {
      await debounceTimer!.future;
    } on _CancelException {
      return null;
    }
    return function(parameter);
  };
}

final debounceDuration = Duration(milliseconds: 500);
// A wrapper around Timer used for debouncing.
class _DebounceTimer {
  _DebounceTimer() {
    _timer = Timer(debounceDuration, _onComplete);
  }

  late final Timer _timer;
  final Completer<void> _completer = Completer<void>();

  void _onComplete() {
    _completer.complete();
  }

  Future<void> get future => _completer.future;

  bool get isCompleted => _completer.isCompleted;

  void cancel() {
    _timer.cancel();
    _completer.completeError(const _CancelException());
  }
}

// An exception indicating that the timer was canceled.
class _CancelException implements Exception {
  const _CancelException();
}