library tekartik_midi_writer;

import 'package:tekartik_midi/src/writer/binary_writer.dart';

export 'package:tekartik_midi/src/writer/binary_writer.dart';
export 'package:tekartik_midi/src/writer/object_writer.dart';
export 'package:tekartik_midi/src/writer/file_writer.dart';
export 'package:tekartik_midi/src/writer/track_writer.dart';
export 'package:tekartik_midi/src/writer/event_writer.dart';

class MidiWriter extends BinaryBEWriter {
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
  void writeVariableLengthData(int value) {
    if (value >= 0x80) {
      int byte2 = value >> 7;
      if (byte2 >= 0x80) {
        int byte3 = byte2 >> 7;
        if (byte3 >= 0x80) {
          int byte4 = byte3 >> 7;
          writeUint8((byte4 & 0x7F) | 0x80);
        }
        writeUint8((byte3 & 0x7F) | 0x80);
      }
      writeUint8((byte2 & 0x7F) | 0x80);
    }
    writeUint8(value & 0x7F);
  }
}
