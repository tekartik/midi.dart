part of midi_parser;

int read3BytesBEInteger(List<int> data, [int offset = 0]) {
  if (data.length - offset < 3) {
    throw new FormatException("not enought data");
  }
  return (((data[offset] & 0xFF) << 16) |
      ((data[offset + 1] & 0xFF) << 8) |
      (data[offset + 2] & 0xFF));
}

List<int> create3BytesBEIntegerBuffer(int value) {
  List<int> data = new List();
  data.add((value & 0xFF0000) >> 16);
  data.add((value & 0xFF00) >> 8);
  data.add(value & 0xFF);
  return data;
}

abstract class BinaryParser {
  InBuffer _buffer;
  int get length => _buffer.length;

  InBuffer get inBuffer => _buffer;

  BinaryParser(List<int> data) {
    _buffer = new InBuffer(data);
  }

  void _checkContains(int size) {
    if (!_buffer.contains(size)) {
      throw new FormatException("not enought data");
    }
  }

  void _checkHasAvailable(OutBuffer buffer, int size) {
    if (!buffer.hasAvailable(size)) {
      throw new FormatException("not enought space");
    }
  }

  void read(OutBuffer buffer, int size) {
    _checkContains(size);
    _checkHasAvailable(buffer, size);
    buffer.restart();
    while (size-- > 0) {
      buffer.add(_buffer.next());
    }
  }

  void back(int size) {
    skip(0 - size);
  }

  void skip(int size) {
    _checkContains(size);
    _buffer.skip(size);
  }

  int _read1ByteInteger() {
    return _buffer.next();
  }

  int read1ByteInteger() {
    _checkContains(1);
    return _read1ByteInteger();
  }

  int readUint8() {
    return read1ByteInteger();
  }

  int _read2BytesBEInteger() {
    int byte1 = _read1ByteInteger();
    int byte2 = _read1ByteInteger();
    return byte1 << 8 | byte2;
  }

  int read2BytesBEInteger() {
    _checkContains(2);
    return _read2BytesBEInteger();
  }

  int _read4BytesBEInteger() {
    int short1 = _read2BytesBEInteger();
    int short2 = _read2BytesBEInteger();
    return short1 << 16 | short2;
  }

  int read4BytesBEInteger() {
    _checkContains(4);
    return _read4BytesBEInteger();
  }
}

class BinaryBEParser extends BinaryParser {
  BinaryBEParser(List<int> data) : super(data);

  int readUint16() {
    return read2BytesBEInteger();
  }

  int readUint32() {
    return read4BytesBEInteger();
  }
}
