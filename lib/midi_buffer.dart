library tekartik_midi_buffer;

abstract class Buffer {
  List<int> _data;
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

class InBuffer extends Buffer {
  InBuffer(List<int> data) {
    _data = data;
  }
  int get length => _data.length;

  //int operator [](int index) => _data[index];

  int next() {
    return _data[_position++];
  }

  void skip(int count) {
    _position += count;
  }
}

class OutBuffer extends Buffer {
  int get length => _position;

  OutBuffer(int size) {
    _data = new List<int>.filled(size, null);
  }

  void restart() {
    _position = 0;
  }

  void add(int value) {
    _data[_position++] = value;
  }

  int get remainingAvailable => _data.length - _position;

  bool hasAvailable(int size) {
    return remainingAvailable >= size;
  }

  bool equalsList(List<int> data) {
    if (length == data.length) {
      for (int i = 0; i < length; i++) {
        if (data[i] != _data[i]) {
          return false;
        }
      }
      return true;
    }
    return false;
  }
}
