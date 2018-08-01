import 'package:tekartik_midi/midi_buffer.dart';
import 'package:tekartik_midi/midi_parser.dart';

class ObjectParser {
  MidiParser get midiParser => _midiParser;
  MidiParser _midiParser;
  ObjectParser(this._midiParser);

  void readBuffer(int size) {
    _midiParser.read(buffer, size);
  }

  OutBuffer get buffer => _midiParser.outBuffer;

  int readUint16() {
    return _midiParser.readUint16();
  }

  int readUint32() {
    return _midiParser.readUint32();
  }

  int readUint8() {
    return _midiParser.readUint8();
  }

  void skip(int size) {
    _midiParser.skip(size);
  }
}
