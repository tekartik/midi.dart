abstract class BinaryWriter {
  List<int> _data = [];
  int position = 0;

  List<int> get data => _data;

  void write1ByteInteger(int value) {
    _data.add(value);
    position++;
  }

  void writeUint8(int value) {
    write1ByteInteger(value);
  }

  void write2BytesBEInteger(int value) {
    write1ByteInteger((value >> 8) & 0xFF);
    write1ByteInteger(value & 0xFF);
  }

  void write4BytesBEInteger(int value) {
    write2BytesBEInteger((value >> 16) & 0xFFFF);
    write2BytesBEInteger(value & 0xFFFF);
  }

  void write(List<int> data) {
    _data.addAll(data);
    position += data.length;
  }
}

class BinaryBEWriter extends BinaryWriter {
  void writeUint16(int value) {
    write2BytesBEInteger(value);
  }

  void writeUint32(int value) {
    write4BytesBEInteger(value);
  }
}
