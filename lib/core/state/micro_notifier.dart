import 'package:flutter/foundation.dart';

/// Near-zero-overhead state container built strictly on Flutter SDK primitives.
/// Avoids heavy Provider/Riverpod/BLoC wrapper widgets and context lookups.
class MicroState<T> extends ValueNotifier<T> {
  MicroState(super.value);

  /// Sets state only if the value has changed, avoiding duplicate rebuild notifications.
  void update(T newValue) {
    if (value != newValue) {
      value = newValue;
    }
  }

  /// Forces notification without object reallocation.
  void notify() {
    notifyListeners();
  }
}
