import 'package:tekartik_midi/src/buffer/midi_buffer.dart';

/// Signed value for a byte
int byteToSignedValue(int value) {
  if (value > 127) {
    return value - 256;
  }
  return value;
}

/// Convert a signed value to a byte
int signedValueToByte(int value) {
  if (value < 0) {
    return value + 256;
  }
  return value;
}

/// Read a 3 bytes integer
int read3BytesBEInteger(List<int> data, [int offset = 0]) {
  if (data.length - offset < 3) {
    throw const FormatException('not enought data');
  }
  return (((data[offset] & 0xFF) << 16) |
      ((data[offset + 1] & 0xFF) << 8) |
      (data[offset + 2] & 0xFF));
}

/// Create a 3 bytes integer buffer
List<int> create3BytesBEIntegerBuffer(int value) {
  final data = <int>[];
  data.add((value & 0xFF0000) >> 16);
  data.add((value & 0xFF00) >> 8);
  data.add(value & 0xFF);
  return data;
}

/// Binary parser
abstract class BinaryParser {
  InBuffer? _buffer;

  /// size
  int get length => _buffer!.length;

  /// The buffer
  InBuffer? get inBuffer => _buffer;

  /// Constructor
  BinaryParser(List<int> data) {
    _buffer = InBuffer(data);
  }

  void _checkContains(int size) {
    if (!_buffer!.contains(size)) {
      throw const FormatException('not enought data');
    }
  }

  void _checkHasAvailable(OutBuffer buffer, int size) {
    if (!buffer.hasAvailable(size)) {
      throw const FormatException('not enought space');
    }
  }

  /// Read data
  void read(OutBuffer buffer, int size) {
    _checkContains(size);
    _checkHasAvailable(buffer, size);
    buffer.restart();
    while (size-- > 0) {
      buffer.add(_buffer!.next());
    }
  }

  /// Go back
  void back(int size) {
    skip(0 - size);
  }

  /// Skip data
  void skip(int size) {
    _checkContains(size);
    _buffer!.skip(size);
  }

  int _read1ByteInteger() {
    return _buffer!.next();
  }

  /// Read a 1 byte integer
  int read1ByteInteger() {
    _checkContains(1);
    return _read1ByteInteger();
  }

  /// Read a 1 byte unsigned integer
  int readUint8() {
    return read1ByteInteger();
  }

  int _read2BytesBEInteger() {
    final byte1 = _read1ByteInteger();
    final byte2 = _read1ByteInteger();
    return byte1 << 8 | byte2;
  }

  /// Read a 2 bytes big endian integer
  int read2BytesBEInteger() {
    _checkContains(2);
    return _read2BytesBEInteger();
  }

  int _read4BytesBEInteger() {
    final short1 = _read2BytesBEInteger();
    final short2 = _read2BytesBEInteger();
    return short1 << 16 | short2;
  }

  /// Read a 4 bytes big endian integer
  int read4BytesBEInteger() {
    _checkContains(4);
    return _read4BytesBEInteger();
  }
}

/// Big endian binary parser
class BinaryBEParser extends BinaryParser {
  /// Constructor
  BinaryBEParser(super.data);

  /// Read a 2 bytes big endian integer
  int readUint16() {
    return read2BytesBEInteger();
  }

  /// Read a 4 bytes big endian integer
  int readUint32() {
    return read4BytesBEInteger();
  }
}
