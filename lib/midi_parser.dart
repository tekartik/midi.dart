library;

import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_midi/src/buffer/midi_buffer.dart';
import 'package:tekartik_midi/src/parser/binary_parser.dart';

export 'package:tekartik_midi/src/parser/binary_parser.dart';
export 'package:tekartik_midi/src/parser/event_parser.dart';
export 'package:tekartik_midi/src/parser/file_parser.dart';
export 'package:tekartik_midi/src/parser/track_parser.dart';

/// Midi file parser.
class MidiParser extends BinaryBEParser {
  /// Constructor
  MidiParser(super.data);

  /// The output buffer to read data to.
  @protected
  OutBuffer get outBuffer => _outBuffer;
  final _outBuffer = OutBuffer(256);

  /// Read a buffer
  void readBuffer(int size) {
    read(_outBuffer, size);
  }

  /// Some numbers in MTrk blocks are represented in a form called a variable-
  /// length quantity. These numbers are represented 7 bits per byte, most
  /// significant bits first. All bytes except the last have bit 7 set, and the
  /// last byte has bit 7 clear. If the number is between 0 and 127, it is thus
  /// represented exactly as one byte. Since this explanation might not be too
  /// clear, some examples :
  ///
  /// <pre>
  /// 00000000 00
  /// 00000040 40
  /// 0000007F 7F
  /// 00000080 81 00
  /// 00002000 C0 00
  /// 00003FFF FF 7F
  /// 001FFFFF FF FF 7F
  /// 08000000 C0 80 80 00
  /// 0FFFFFFF FF FF FF 7F
  /// </pre>
  ///
  /// @return
  /// @throws MidiException
  int readVariableLengthData() {
    var value = readUint8();
    if ((value & 0x80) != 0) {
      value = (value & 0x7F) << 7;
      var next = readUint8();
      if ((next & 0x80) != 0) {
        value = (value + (next & 0x7F)) << 7;
        next = readUint8();
        if ((next & 0x80) != 0) {
          value = (value + (next & 0x7F)) << 7;
          // We're at the end!
          next = readUint8();
        }
        value += next;
      } else {
        value += next;
      }
    }
    return value;
  }
}
