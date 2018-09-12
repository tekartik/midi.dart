import 'package:tekartik_midi/midi_writer.dart';

class ObjectWriter {
  MidiWriter _midiWriter;
  ObjectWriter(this._midiWriter);

  MidiWriter get midiWriter => _midiWriter;

  void writeUint16(int value) {
    _midiWriter.writeUint16(value);
  }

  void writeUint32(int value) {
    _midiWriter.writeUint32(value);
  }

  void writeUint8(int value) {
    _midiWriter.writeUint8(value);
  }

  List<int> get data => _midiWriter.data;

  void writeBuffer(List<int> data) {
    _midiWriter.write(data);
  }

  void write0(int size) {
    writeBuffer(new List<int>.filled(size, 0));
  }

  void writeVariableLengthData(int value) {
    _midiWriter.writeVariableLengthData(value);
  }
}
