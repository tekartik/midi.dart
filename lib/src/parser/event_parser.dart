import 'package:tekartik_midi/midi.dart';
import 'package:tekartik_midi/midi_parser.dart';
import 'package:tekartik_midi/src/parser/object_parser.dart';

/// Event parser
class EventParser extends ObjectParser {
  /// Delta time
  late int deltaTime;

  /// The event parsed
  late MidiEvent event;

  /// The track event
  TrackEvent get trackEvent => TrackEvent(deltaTime, event);

  /// Use the last command when command is ommited
  /// i.e. the command part has it 8th bits cleared
  int lastCommand = 0;

  /// Constructor
  EventParser(super.parser);

  /// Parse the event
  MidiEvent parseEvent() {
    deltaTime = midiParser.readVariableLengthData();
    var command = midiParser.readUint8();
    if ((command & 0x80) == 0) {
      if ((lastCommand & 0x80) == 0) {
        throw const FormatException('invalid last command');
      }
      command = lastCommand;
      // We go back 1
      midiParser.back(1);
    } else {
      // save for later use
      lastCommand = command;
    }

    if (MidiEvent.commandGetEventType(command) == MidiEvent.metaEvent) {
      // Handle sysex?
      if (command != MidiEvent.cmdMetaEvent) {
        // sysex?
        event = SysExEvent.withParam(command);
      } else {
        final metaCommand = midiParser.readUint8();
        event = MetaEvent.base(command, metaCommand);
      }
    } else {
      event = MidiEvent.base(command);
    }
    event.readData(midiParser);
    return event;
  }

  /// for testing only
  static MidiEvent? dataParseEvent(List<int> data) {
    final midiParser = MidiParser(data);
    final parser = EventParser(midiParser);
    return parser.parseEvent();
  }
}
