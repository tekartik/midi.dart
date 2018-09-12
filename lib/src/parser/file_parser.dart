import 'package:tekartik_midi/midi.dart';
import 'package:tekartik_midi/midi_parser.dart';
import 'package:tekartik_midi/src/parser/object_parser.dart';
import 'package:tekartik_midi/src/parser/track_parser.dart';

class FileParser extends ObjectParser {
  FileParser(MidiParser midiParser) : super(midiParser);

  MidiFile file;

  static final List<int> fileHeader = [
    'M'.codeUnitAt(0),
    'T'.codeUnitAt(0),
    'h'.codeUnitAt(0),
    'd'.codeUnitAt(0)
  ];

  void parseTracks() {
    TrackParser trackParser = new TrackParser(midiParser);

    // Clear track count
    int trackCount = file.trackCount;
    file.trackCount = 0;
    for (int i = 0; i < trackCount; i++) {
      //print(hexPretty(_midiParser.inBuffer.buildRemainingData().sublist(0, 20)));
      trackParser.parseTrack();
      file.addTrack(trackParser.track);
    }
  }

  void parseFile() {
    parseHeader();
    parseTracks();
  }

  void parseHeader() {
    readBuffer(4);
    if (!buffer.equalsList(fileHeader)) {
      throw new FormatException("Bad file header");
    }
    int dataHeaderLen = midiParser.readUint32();
    if (dataHeaderLen < 6) {
      throw new FormatException("Bad data header len");
    }
    file = new MidiFile();

    file.fileFormat = readUint16();
    file.trackCount = readUint16();
    file.timeDivision = readUint16();
    if (dataHeaderLen > 6) {
      skip(dataHeaderLen - 6);
    }
  }

  /**
   * Parser helper
   */
  static MidiFile dataFile(List<int> data) {
    FileParser parser = new FileParser(new MidiParser(data));
    parser.parseFile();
    return parser.file;
  }
}
