import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_midi/midi_parser.dart';
import 'package:tekartik_midi/src/midi/file.dart';
import 'package:tekartik_midi/src/parser/object_parser.dart';

/// File parser
class FileParser extends ObjectParser {
  /// Constructor
  FileParser(super.midiParser);

  /// The midi file
  MidiFile? file;

  /// File heeader
  static final List<int> fileHeader = [
    'M'.codeUnitAt(0),
    'T'.codeUnitAt(0),
    'h'.codeUnitAt(0),
    'd'.codeUnitAt(0),
  ];

  /// Parse the tracks
  @protected
  void parseTracks() {
    final trackParser = TrackParser(midiParser);

    // Clear track count
    final trackCount = file!.headerTrackCount;

    for (var i = 0; i < trackCount; i++) {
      //print(hexPretty(_midiParser.inBuffer.buildRemainingData().sublist(0, 20)));
      _skipAlienChunks();
      var track = trackParser.parseTrack();
      file!.addTrack(track);
    }
  }

  /// Skips the chunks that are not tracks: the spec asks readers to "expect
  /// alien chunks and treat them as if they weren't there".
  void _skipAlienChunks() {
    while (true) {
      readBuffer(4);
      if (buffer.equalsList(TrackParser.trackHeader)) {
        midiParser.back(4);
        return;
      }
      final length = readUint32();
      // Negative on the web for a length of 2 GB or more: never go back.
      if (length < 0) {
        throw const FormatException('Bad chunk length');
      }
      skip(length);
    }
  }

  /// Throw FormatException if not valid
  MidiFile parseFile() {
    parseHeader();

    parseTracks();
    return file!;
  }

  /// Parse the header
  void parseHeader() {
    readBuffer(4);
    if (!buffer.equalsList(fileHeader)) {
      throw const FormatException('Bad file header');
    }
    final dataHeaderLen = midiParser.readUint32();
    if (dataHeaderLen < 6) {
      throw const FormatException('Bad data header len');
    }
    file = MidiFile();

    file!.fileFormat = readUint16();
    file!.setHeaderTrackCount(readUint16());
    final timeDivision = readUint16();
    // A tick of a zero time division (0 ppq, or 0 ticks per SMPTE frame)
    // would last forever: every time would be NaN.
    final ticks = (timeDivision & 0x8000) == 0
        ? timeDivision
        : timeDivision & 0xFF;
    if (ticks == 0) {
      throw const FormatException('invalid time division');
    }
    file!.timeDivision = timeDivision;
    if (dataHeaderLen > 6) {
      skip(dataHeaderLen - 6);
    }
  }

  /// Parser helper
  static MidiFile? dataFile(List<int> data) {
    final parser = FileParser(MidiParser(data));
    parser.parseFile();
    return parser.file;
  }
}
