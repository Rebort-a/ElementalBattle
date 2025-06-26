import 'package:flutter/foundation.dart';

class AlwaysNotifier<T> extends ChangeNotifier implements ValueListenable<T> {
  AlwaysNotifier(this._value) {
    if (kFlutterMemoryAllocationsEnabled) {
      ChangeNotifier.maybeDispatchObjectCreation(this);
    }
  }

  @override
  T get value => _value;
  T _value;
  set value(T newValue) {
    _value = newValue;
    notifyListeners();
  }
}

class ListNotifier<T> extends ValueNotifier<List<T>> {
  final List<VoidCallback> _callBacks = [];

  void addCallBack(VoidCallback callBack) {
    _callBacks.add(callBack);
  }

  void removeCallBack(VoidCallback callBack) {
    _callBacks.remove(callBack);
  }

  void notifyAll() {
    for (VoidCallback callBack in _callBacks) {
      callBack();
    }
  }

  ListNotifier(super.value);

  @override
  List<T> get value => List.unmodifiable(super.value);

  int get length => value.length;

  void add(T value) {
    super.value.add(value);
    super.notifyListeners();
    notifyAll();
  }

  void remove(T value) {
    super.value.remove(value);
    super.notifyListeners();
    notifyAll();
  }

  void removeAt(int index) {
    super.value.removeAt(index);
    super.notifyListeners();
    notifyAll();
  }

  void removeWhere(bool Function(T) check) {
    super.value.removeWhere(check);
    super.notifyListeners();
    notifyAll();
  }

  void clear() {
    super.value.clear();
    super.notifyListeners();
    notifyAll();
  }
}
