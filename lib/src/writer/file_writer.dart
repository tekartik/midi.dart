import 'package:tekartik_midi/midi.dart';
import 'package:tekartik_midi/midi_writer.dart';

/// Write a midi file
class FileWriter extends ObjectWriter {
  /// Constructor
  FileWriter(super.midiWriter);

  /// The midi file
  late MidiFile file;

  /// File heeader
  static final List<int> fileHeader = [
    'M'.codeUnitAt(0),
    'T'.codeUnitAt(0),
    'h'.codeUnitAt(0),
    'd'.codeUnitAt(0)
  ];

  /// Write the header
  void writeHeader() {
    writeBuffer(fileHeader);
    writeUint32(6);

    writeUint16(file.fileFormat);
    writeUint16(file.trackCount);
    writeUint16(file.timeDivision);
  }

  /// Write the file
  void writeFile([MidiFile? midiFile]) {
    if (midiFile != null) {
      file = midiFile;
    }
    writeHeader();
    for (var track in file.tracks) {
      final trackWriter = TrackWriter(midiWriter);
      trackWriter.writeTrack(track);
    }
  }

  /// Get the data
  static List<int> fileData(MidiFile? file) {
    final midiWriter = MidiWriter();
    final writer = FileWriter(midiWriter);
    writer.writeFile(file);
    return midiWriter.data;
  }
}
