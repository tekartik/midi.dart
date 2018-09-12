import 'package:collection/collection.dart';
import 'package:tekartik_midi/src/midi/track.dart';

class MidiFile {
  /** 0 single track, 1, multi track synchronous, 2, multitrack async */
  static final int FORMAT_MULTI_TRACK = 1;

  int fileFormat = FORMAT_MULTI_TRACK;
  int trackCount = 0;

  /**
   * Pulses per quarter note (PPQ)
   * When the top bit of the time division bytes is 0, the time division is in ticks per beat.
   * The remaining 15 bits are the number of MIDI ticks per beat (per quarter note).
   * If, for example, these 15 bits compute to the number 60, then the time division is 60 ticks
   * per beat and the length of one tick is
   * 
   * 1 tick = microseconds per beat / 60
   * The variable "microseconds per beat" is specified by a MIDI event carrying the set tempo meta message.
   * If it is not specified then it is 500,000 microseconds by default, which is equivalent to 120 beats per minute.
   * In the example above, if the MIDI time division is 60 ticks per beat and if the microseconds per beat is 500,000,
   * then 1 tick = 500,000 / 60 = 8333.33 microseconds.
   */
  int _ppq = 120; // default value
  int get ppq => _ppq;
  void set ppq(int ppq) {
    if ((ppq & 0x8000) != 0) {
      throw new FormatException("invalid pulses per quarter note");
    }
    timeDivision = ppq;
  }

  /**
   * Frames per second
   *
   * When the top bit of the time division bytes is 1, the remaining 15 bits 
   * have to be broken in two pieces. The top remaining 7 bits (the rest of the
   * top byte) represent the number of frames per second and could be 24, 25, 
   * 29.97 (represented by 29), or 30. The low byte (the low 8 bits) describes
   * the number of ticks per frame. Thus, if, for example, there are 24 frames 
   * per second and there are 100 ticks per frame, since there are 1,000,000 
   * microseconds in a second, one tick is equal to
   *
   * 1 tick = 1,000,000 / (24 * 100) = 416.66 microseconds
   * 
   * Thus, when the time division top bit is 1, the length of a tick is 
   * strictly defined by the two time division bytes. The first byte is the 
   * frames per second and the second byte is the number of ticks per frame,
   * which is enough to specify the tick length exactly. This is not so when 
   * the top bit of the time division bytes is 0 and the time division is in
   * pulses per quarter note. The time division in this case defines the ticks
   * per beat, but nothing in the time division specifies the number of beats 
   * per second. A MIDI event should be used to specify the number of beats 
   * per second (or the length of a beat), or it should be left up to the MIDI 
   * device to set the tempo (120 beats per minute by default, as mentioned above).
   * 
   * The highest 8-bits of the divisions field specifies the (negative) SMPTE frame count per second,
   * and the lower 8-bits of the divisions field specifies the divisions per frame. Note that the numbers
   * in MIDI files are stored in big-endian format, so the first byte in the file for the divisions field is the
   * SMPTE frame count per second, and the second byte is the subdivision count for each frame.
   * 
   * So suppose, that you want to specify 25 frames per second, with 40 subdivisions per frame. In this case
   * the first byte is set to the number -25 (in hexadecimal: 0xE7). The subdivisions are store without negation,
   * so in hex the second byte is 0x28 (decimal 40). And the combined 2-byte hex code is 0xE728. This format
   * of the divisions value in the MIDI header cannot be interpreted as ticks per quarter note because the value
   * is larger than 0x7FFF, so interpreting 0xE728 as the decimal number 59176 is invalid. Instead it must be
   * interpreted as two separate 1-byte numbers, with the first number negated to indicate that SMPTE code
   * is being specified rather than regular ticks-per-quarter note.
   */
  // int get framePerSecond;

  int _timeDivision;

  void set timeDivision(int timeDivision) {
    _timeDivision = timeDivision;
    // ppq?
    if ((timeDivision & 0x8000) == 0) {
      _ppq = timeDivision;
      _frameCoundPerSecond = null;
      _divisionCountPerFrame = null;
    } else {
      _ppq = null;
      int framesPerSecondEncoded = 256 - (timeDivision >> 8) & 0xFF;

      switch (framesPerSecondEncoded) {
        case 24:
          _frameCoundPerSecond = 24;
          break;
        case 25:
          _frameCoundPerSecond = 25;
          break;
        case 30:
          _frameCoundPerSecond = 30;
          break;
        case 29:
          _frameCoundPerSecond = 29.97;
          break;
        default:
          throw new FormatException("invalid frames per second");
      }
      _divisionCountPerFrame = (timeDivision & 0xFF);
    }
  }

  num _frameCoundPerSecond;
  int _divisionCountPerFrame;
  num get frameCountPerSecond => _frameCoundPerSecond;

  int get divisionCountPerFrame => _divisionCountPerFrame;
  /**
   * @param: frameCountPerSecondEncoded in (24, 25, 29 - meaning 29.97 -, 30)
   */
  void setFrameDivision(
      int frameCountPerSecondEncoded, int divisionCountPerFrame) {
    timeDivision =
        ((256 - frameCountPerSecondEncoded) << 8) | divisionCountPerFrame;
  }

  int get timeDivision => _timeDivision;

  List<MidiTrack> tracks = new List();

  /**
   * convert a delay in an event to a delay in ms
   */
  num delayToMillis(int delay) {
    return delay / ppq;
  }

  int get hashCode {
    int hash = (fileFormat * 17 + trackCount) * 31;
    if (tracks.length > 0) {
      hash += tracks.hashCode;
    }
    return hash;
  }

  @override
  bool operator ==(var other) {
    if (other is MidiFile) {
      return (fileFormat == other.fileFormat) &&
          (trackCount == other.trackCount) &&
          (_timeDivision == other._timeDivision) &&
          (const ListEquality().equals(tracks, other.tracks));
    }
    return false;
  }

  toString() {
    StringBuffer out = new StringBuffer();
    out.write('format $fileFormat $trackCount tracks ppq $ppq');
    if (tracks.length > 0) {
      out.write(' ${tracks[0].toString()}');
    }
    return out.toString();
  }

  void addTrack(MidiTrack track) {
    trackCount++;
    tracks.add(track);
  }

  void dump() {
    print('format: $fileFormat');
    if (ppq != null) {
      print('ppq: $ppq');
    } else {
      print('framesPerSecond: $frameCountPerSecond');
      print('divisionsPerFrame: $divisionCountPerFrame');
    }
    int index = 0;
    tracks.forEach((MidiTrack track) {
      print('Track ${++index}');
      track.dump();
    });
  }
}
