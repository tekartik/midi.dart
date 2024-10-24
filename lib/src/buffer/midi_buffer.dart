abstract class _Buffer {
  late List<int> _data;
  int _position = 0;

  int get length;

  int get remaining => length - _position;

  bool contains(int size) {
    return remaining >= size;
  }

  List<int> get data => _data;

  int get position => _position;

  List<int> buildRemainingData() {
    return data.sublist(position);
  }
}

/// Input buffer
class InBuffer extends _Buffer {
  /// Constructor
  InBuffer(List<int> data) {
    _data = data;
  }

  @override
  int get length => _data.length;

  //int operator [](int index) => _data[index];

  /// Get the next byte and advance the position
  int next() {
    return _data[_position++];
  }

  /// Skip [count] bytes
  void skip(int count) {
    _position += count;
  }
}

/// Output buffer
class OutBuffer extends _Buffer {
  @override
  int get length => _position;

  /// Constructor
  OutBuffer(int size) {
    _data = List<int>.filled(size, 0);
  }

  /// Restart the buffer
  void restart() {
    _position = 0;
  }

  /// Add a byte
  void add(int value) {
    _data[_position++] = value;
  }

  /// get the remaining count
  int get remainingAvailable => _data.length - _position;

  /// Check if there is enough space
  bool hasAvailable(int size) {
    return remainingAvailable >= size;
  }

  /// Check if the data is equal to the list
  bool equalsList(List<int> data) {
    if (length == data.length) {
      for (var i = 0; i < length; i++) {
        if (data[i] != _data[i]) {
          return false;
        }
      }
      return true;
    }
    return false;
  }
}
