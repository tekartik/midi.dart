import 'package:tekartik_midi/midi_writer.dart';

/// Object writer
class ObjectWriter {
  final MidiWriter _midiWriter;

  /// Constructor
  ObjectWriter(this._midiWriter);

  /// The midi writer
  MidiWriter get midiWriter => _midiWriter;

  /// Write a 16 bits unsigned integer
  void writeUint16(int value) {
    _midiWriter.writeUint16(value);
  }

  /// Write a 32 bits unsigned integer
  void writeUint32(int value) {
    _midiWriter.writeUint32(value);
  }

  /// Write a 8 bits unsigned integer
  void writeUint8(int value) {
    _midiWriter.writeUint8(value);
  }

  /// The data
  List<int> get data => _midiWriter.data;

  /// Write a buffer
  void writeBuffer(List<int> data) {
    _midiWriter.write(data);
  }

  /// Write a buffer filled with 0
  void write0(int size) {
    writeBuffer(List<int>.filled(size, 0));
  }

  /// Write a variable length data
  void writeVariableLengthData(int value) {
    _midiWriter.writeVariableLengthData(value);
  }
}
