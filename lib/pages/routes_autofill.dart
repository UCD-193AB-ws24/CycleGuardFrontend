import 'dart:async';

import 'package:cycle_guard_app/data/navigation_accessor.dart';
import 'package:flutter/material.dart';
import 'package:cycle_guard_app/main.dart';
import 'package:provider/provider.dart';

// Thanks, Flutter guides!
// https://api.flutter.dev/flutter/material/Autocomplete-class.html

// Duration to wait before doing autofill.
// Higher duration = slower results
// Lower duration = more expensive
final debounceDuration = Duration(milliseconds: 250);

Function(String) _callback = (str) {};
void setCallback(Function(String) callback) {
  _callback = callback;
}

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
  late Iterable<String> _lastOptions = <String>[];

  late final _Debounceable<Iterable<String>?, String> _debouncedSearch;

  // Calls the "remote" API to search with the given query. Returns null when
  // the call has been made obsolete.
  Future<Iterable<String>?> _search(String query) async {
    _currentQuery = query;

    // In a real application, there should be some error handling here.
    final Iterable<String> options = await _NavigationAPI.search(_currentQuery!);

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
    _debouncedSearch = _debounce<Iterable<String>?, String>(_search);
  }

  @override
  Widget build(BuildContext context) {
    Color selectedColor = Provider.of<MyAppState>(context).selectedColor;
    return Autocomplete<String>(
      fieldViewBuilder: (
        BuildContext context,
        TextEditingController textEditingController,
        FocusNode focusNode,
        VoidCallback onFieldSubmitted,
      ) {
        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.search, color: selectedColor),
            hintText: 'Search...',
            hintStyle: TextStyle(color: Colors.grey[500]),
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Colors.grey, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: selectedColor, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        );
      },
      optionsBuilder: (TextEditingValue textEditingValue) async {
        final Iterable<String>? options =
            await _debouncedSearch(textEditingValue.text);
        if (options == null) return _lastOptions;
        _lastOptions = options;
        return options;
      },
      onSelected: (String selection) {
        _callback(selection);
      },
    );
  }

}

class _NavigationAPI {
  // Searches the options, but injects a fake "network" delay.
  static Future<List<String>> search(String query) async {
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