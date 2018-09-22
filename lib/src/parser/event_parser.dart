import 'package:tekartik_midi/midi.dart';
import 'package:tekartik_midi/midi_parser.dart';
import 'package:tekartik_midi/src/parser/object_parser.dart';

class EventParser extends ObjectParser {
  int deltaTime;
  MidiEvent event;

  TrackEvent get trackEvent => new TrackEvent(deltaTime, event);

  // Use the last command when command is ommited
  // i.e. the command part has it 8th bits cleared
  int lastCommand = 0;

  EventParser(MidiParser parser) : super(parser);

  MidiEvent parseEvent() {
    deltaTime = midiParser.readVariableLengthData();
    int command = midiParser.readUint8();
    if ((command & 0x80) == 0) {
      if ((lastCommand & 0x80) == 0) {
        throw new FormatException("invalid last command");
      }
      command = lastCommand;
      // We go back 1
      midiParser.back(1);
    } else {
      // save for later use
      lastCommand = command;
    }

    if (MidiEvent.commandGetCommand(command) == MidiEvent.metaEvent) {
      // Handle sysex?
      if (command != MidiEvent.cmdMetaEvent) {
        // sysex?
        event = new SysExEvent.withParam(command);
      } else {
        int metaCommand = midiParser.readUint8();
        event = new MetaEvent.base(command, metaCommand);
      }
    } else {
      event = new MidiEvent.base(command);
    }
    event.readData(midiParser);
    return event;
  }

  /**
   * for testing only
   */
  static MidiEvent dataParseEvent(List<int> data) {
    MidiParser midiParser = new MidiParser(data);
    EventParser parser = new EventParser(midiParser);
    return parser.parseEvent();
  }
}
