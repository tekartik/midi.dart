import 'package:tekartik_midi/midi.dart';
import 'package:tekartik_midi/midi_writer.dart';

class FileWriter extends ObjectWriter {
  FileWriter(MidiWriter midiWriter) : super(midiWriter);

  late MidiFile file;

  static final List<int> fileHeader = [
    'M'.codeUnitAt(0),
    'T'.codeUnitAt(0),
    'h'.codeUnitAt(0),
    'd'.codeUnitAt(0)
  ];

  void writeHeader() {
    writeBuffer(fileHeader);
    writeUint32(6);

    writeUint16(file.fileFormat);
    writeUint16(file.trackCount);
    writeUint16(file.timeDivision);
  }

  void writeFile([MidiFile? _file]) {
    if (_file != null) {
      file = _file;
    }
    writeHeader();
    file.tracks.forEach((MidiTrack? track) {
      final trackWriter = TrackWriter(midiWriter);
      trackWriter.writeTrack(track);
    });
  }

  static List<int> fileData(MidiFile? file) {
    final midiWriter = MidiWriter();
    final writer = FileWriter(midiWriter);
    writer.writeFile(file);
    return midiWriter.data;
  }
}
