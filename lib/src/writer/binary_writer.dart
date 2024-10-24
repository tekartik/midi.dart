/// A class to write binary data
abstract class BinaryWriter {
  final _data = <int>[];

  /// The current position
  int position = 0;

  /// The data
  List<int> get data => _data;

  /// Write a 1 byte integer
  void write1ByteInteger(int value) {
    _data.add(value);
    position++;
  }

  /// Write a byte
  void writeUint8(int value) {
    write1ByteInteger(value);
  }

  /// Write a 2 bytes integer
  void write2BytesBEInteger(int value) {
    write1ByteInteger((value >> 8) & 0xFF);
    write1ByteInteger(value & 0xFF);
  }

  /// Write a 4 bytes integer
  void write4BytesBEInteger(int value) {
    write2BytesBEInteger((value >> 16) & 0xFFFF);
    write2BytesBEInteger(value & 0xFFFF);
  }

  /// Write a buffer
  void write(List<int> data) {
    _data.addAll(data);
    position += data.length;
  }
}

/// A class to write binary data in big endian
class BinaryBEWriter extends BinaryWriter {
  /// Write a 16 bits unsigned integer
  void writeUint16(int value) {
    write2BytesBEInteger(value);
  }

  /// Write a 32 bits unsigned integer
  void writeUint32(int value) {
    write4BytesBEInteger(value);
  }
}
