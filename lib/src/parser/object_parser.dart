import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_midi/midi_parser.dart';
import 'package:tekartik_midi/src/buffer/midi_buffer.dart';

/// Generic object parser
class ObjectParser {
  /// The midi parser
  MidiParser get midiParser => _midiParser;
  final MidiParser _midiParser;

  /// Constructor
  ObjectParser(this._midiParser);

  /// Read data to the buffer
  void readBuffer(int size) {
    _midiParser.read(buffer, size);
  }

  /// Buffer used to read data to
  @protected
  // ignore: invalid_use_of_protected_member
  OutBuffer get buffer => _midiParser.outBuffer;

  /// Read a 2 bytes unsigned integer
  int readUint16() {
    return _midiParser.readUint16();
  }

  /// Read a 4 bytes unsigned integer
  int readUint32() {
    return _midiParser.readUint32();
  }

  /// Read a 1 byte unsigned integer
  int readUint8() {
    return _midiParser.readUint8();
  }

  /// Skip some bytes
  void skip(int size) {
    _midiParser.skip(size);
  }
}
