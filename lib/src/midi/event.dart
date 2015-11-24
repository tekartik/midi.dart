part of tekartik_midi;

class TrackEvent {
  int deltaTime;
  MidiEvent midiEvent;

  TrackEvent(this.deltaTime, this.midiEvent);

  @override
  String toString() {
    return '${formatTimestampMs(deltaTime)} ${midiEvent.toString()}';
  }

  @override
  int get hashCode => deltaTime + midiEvent.hashCode;

  @override
  bool operator ==(other) {
    if (other is TrackEvent) {
      return other.midiEvent == midiEvent && other.deltaTime == deltaTime;
    }
    return false;
  }
}

abstract class MidiEvent {
  List<MidiEvent> events = new List<MidiEvent>();

  /** 
   * Delta-Times
   *
   * The event delta time is defined by a variable-length value. It determines 
   * when an event should be played relative to the track's last event. A delta
   * time of 0 means that it should play simultaneously with the last event.
   * A track's first event delta time defines the amount of time to wait before
   * playing this first event. Events unaffected by time are still preceded 
   * by a delta time, but should always use a value of 0 and come first in the
   * stream of track events. Examples of this type of event include track 
   * titles and copyright information. The most important thing to remember 
   * about delta times is that they are relative values, not absolute times. 
   * The actual time they represent is determined by a couple factors.
   * The time division (defined in the MIDI header chunk) and the tempo 
   * (defined with a track event). If no tempo is define, 120 beats 
   * per minute is assumed.
   */
  int command;

  static const int CHANNEL_COUNT = 16;
  static const int NOTE_COUNT = 128;

  // Control commannd
  static const int NOTE_OFF = 8;
  static const int NOTE_ON = 9;
  static const int KEY_AFTER_TOUCH = 0xA;
  static const int CONTROL_CHANGE = 0xB;
  static const int PROGRAM_CHANGE = 0xC;
  static const int CHANNEL_AFTER_TOUCH = 0xD;
  static const int PITCH_WHEEL_CHANGE = 0xE;
  static const int META_EVENT = 0xF;

  static const int CMD_META_EVENT = 0xFF;

  MidiEvent();

  MidiEvent.withParam(this.command);

  static int commandChannel(int command, int channel) {
    return ((command << 4) | (channel & 0xF));
  }

  static int commandGetCommand(int command) {
    // ((command & 0xF) >> 4)
    return ((command & 0xF0) >> 4);
  }

  static int commandGetChannel(int command) {
    // (command & 0xF)
    return (command & 0xF);
  }

  int get codeCommand => commandGetCommand(command);

  factory MidiEvent.base(int command) {
    MidiEvent event;

    int codeCommand = commandGetCommand(command);
    switch (codeCommand) {
      case NOTE_OFF:
        event = new NoteOffEvent._();
        break;
      case NOTE_ON:
        event = new NoteOnEvent._();
        break;
      case KEY_AFTER_TOUCH:
        event = new KeyAfterTouchEvent._();
        break;
      case CONTROL_CHANGE:
        event = new ControlChangeEvent._();
        break;
      case PROGRAM_CHANGE:
        event = new ProgramChangeEvent._();
        break;
      case CHANNEL_AFTER_TOUCH:
        event = new ChannelAfterTouchEvent._();
        break;
      case PITCH_WHEEL_CHANGE:
        event = new PitchWheelChangeEvent._();
        break;
      default:
        // Meta!
        // not handled here
        // event = new MetaEvent();
        return null;
    }
    event.command = command;
    return event;
  }

  void readData(MidiParser parser);

  void writeData(MidiWriter writer);

  @override
  int get hashCode => command;

  @override
  bool operator ==(other) {
    if (other is MidiEvent) {
      return other.command == command;
    }
    return false;
  }

  @override
  String toString() {
    return "${hexUint8(command)}";
  }
}

abstract class ChannelEvent extends MidiEvent {
  int get channel => MidiEvent.commandGetChannel(command);
  ChannelEvent();

  ChannelEvent.withParam(int comand, int channel)
      : super.withParam(MidiEvent.commandChannel(comand, channel));
}

abstract class Param1ByteEvent extends ChannelEvent {
  int _param1;

  Param1ByteEvent();
  Param1ByteEvent.withParam(int command, int channel, this._param1)
      : super.withParam(command, channel);

  void readData(MidiParser parser) {
    _param1 = parser.readUint8();
  }

  void writeData(MidiWriter writer) {
    writer.writeUint8(_param1);
  }

  @override
  int get hashCode => super.hashCode * 17 + _param1;

  @override
  bool operator ==(other) {
    if (super == (other)) {
      return other._param1 == _param1;
    }
    return false;
  }

  @override
  String toString() {
    return "${super.toString()} p1 ${_param1}";
  }
}

class ProgramChangeEvent extends Param1ByteEvent {
  int get program => _param1;
  void set program(int _program) {
    _param1 = _program;
  }

  ProgramChangeEvent._();
  ProgramChangeEvent(int channel, int program) //
      : super.withParam(MidiEvent.PROGRAM_CHANGE, channel, program);

  @override
  String toString() {
    return "${super.toString()} program change";
  }
}

abstract class Param2BytesEvent extends Param1ByteEvent {
  int _param2;

  Param2BytesEvent();
  Param2BytesEvent.withParam(
      int command, int channel, int _param1, this._param2) //
      : super.withParam(command, channel, _param1);

  void readData(MidiParser parser) {
    super.readData(parser);
    _param2 = parser.readUint8();
  }

  void writeData(MidiWriter writer) {
    super.writeData(writer);
    writer.writeUint8(_param2);
  }

  @override
  bool operator ==(other) {
    if (super == (other)) {
      return other._param2 == _param2;
    }
    return false;
  }

  @override
  int get hashCode => super.hashCode * 31 + _param2;

  @override
  String toString() {
    return "${super.toString()} p2 ${_param2}";
  }
}

class ChannelAfterTouchEvent extends Param1ByteEvent {
  int get amount => _param1;

  ChannelAfterTouchEvent._();
  ChannelAfterTouchEvent(int command, int channel, int amount) //
      : super.withParam(MidiEvent.CHANNEL_AFTER_TOUCH, channel, amount);

  void set amount(int _channel) {
    _param1 = _channel;
  }

  @override
  String toString() {
    return "${super.toString()} channel after touch";
  }
}

/**
 * Note On: 9x nn vv
 * <ol>
 * <li>nn note number</li>
 * <li>vv velocity</li>
 * </ol>
 * 
 * @author Alex
 * 
 */
abstract class NoteEvent extends Param2BytesEvent {
  int get note => _param1;
  void set note(int _note) {
    _param1 = _note;
  }

  int get velocity => _param2;
  void set velocity(int _velocity) {
    _param2 = _velocity;
  }

  NoteEvent();

  NoteEvent.withParam(int command, int channel, int noteNumber, int velocity)
      : super.withParam(command, channel, noteNumber, velocity);
}

class NoteOnEvent extends NoteEvent {
  NoteOnEvent._();
  NoteOnEvent(int channel, int noteNumber, int velocity) //
      : super.withParam(MidiEvent.NOTE_ON, channel, noteNumber, velocity);

  @override
  String toString() {
    return "${super.toString()} note on";
  }
}

class NoteOffEvent extends NoteEvent {
  NoteOffEvent._();
  NoteOffEvent(int channel, int noteNumber, int velocity) //
      : super.withParam(MidiEvent.NOTE_OFF, channel, noteNumber, velocity);

  @override
  String toString() {
    return "${super.toString()} note off";
  }
}

class KeyAfterTouchEvent extends NoteEvent {
  KeyAfterTouchEvent._();
  KeyAfterTouchEvent(int channel, int noteNumber, int velocity) //
      : super.withParam(
            MidiEvent.KEY_AFTER_TOUCH, channel, noteNumber, velocity);

  @override
  String toString() {
    return "${super.toString()} after touch";
  }
}

class PitchWheelChangeEvent extends Param2BytesEvent {
  int get bottom => _param1;
  void set bottom(int _bottom) {
    _param1 = _bottom;
  }

  int get top => _param2;
  void set top(int _top) {
    _param2 = _top;
  }

  PitchWheelChangeEvent._();
  PitchWheelChangeEvent(int channel, int noteNumber, int velocity) //
      : super.withParam(
            MidiEvent.PITCH_WHEEL_CHANGE, channel, noteNumber, velocity);

  @override
  String toString() {
    return "${super.toString()} pitch wheel change";
  }
}

/**
 * cc control number vv new value
 */
class ControlChangeEvent extends Param2BytesEvent {
  ControlChangeEvent._();
  ControlChangeEvent.withParam(
      int channel, int controllerType, int controllerValue)
      : super.withParam(
            MidiEvent.CONTROL_CHANGE, channel, controllerType, controllerValue);

  static int ALL_NOTES_OFF = 123; // <= note off
  static int ALL_RESET = 121; // <= reset
  static int ALL_SOUND_OFF = 120; // <= quick mute
  int get controller => _param1;
  void set controller(int _controller) {
    _param1 = _controller;
  }

  int get value => _param2;
  void set value(int _value) {
    _param2 = _value;
  }

  @override
  String toString() {
    return "${super.toString()} control change";
  }

  static ControlChangeEvent newAllSoundOffEvent(int channel) =>
      new ControlChangeEvent.withParam(channel, ALL_SOUND_OFF, 0);
  static ControlChangeEvent newAllNotesOffEvent(int channel) =>
      new ControlChangeEvent.withParam(channel, ALL_NOTES_OFF, 0);
  static ControlChangeEvent newAllResetEvent(int channel) =>
      new ControlChangeEvent.withParam(channel, ALL_RESET, 0);
  //null;

}

// Normal SysEx Events
// These are the most common type of SysEx event and are used to hold a single
// block of manufacturer specific data. The first byte is always 0xF0 and the
// second is a variable-length value that specifies the length of the following
// SysEx data in bytes. The SysEx data bytes must always end with a 0xF7 byte
// to signal the end of the message.
// SysEx Event Length  Data
// 240 (0xF0)  variable-length data bytes, 0xF7
// Normal SysEx Event Values
class SysExEvent extends MidiEvent {
  List<int> data;

  SysExEvent.withParam(int command, [this.data])
      : super.withParam(
            command); // properly use the full command here (i.e. 0xFF)

  void readData(MidiParser parser) {
    int dataSize = parser.readVariableLengthData();
    if (dataSize > 0) {
      OutBuffer buffer = new OutBuffer(dataSize);
      parser.read(buffer, dataSize);
      data = buffer.data;
    }
  }

  void writeData(MidiWriter writer) {
    int dataSize = data == null ? 0 : data.length;
    writer.writeVariableLengthData(dataSize);
    if (dataSize > 0) {
      writer.write(data);
    }
  }

  @override
  int get hashCode => super.hashCode * 17 + data.length;

  @override
  bool operator ==(other) {
    if (super == (other)) {
      return (const ListEquality().equals(other.data, data));
    }
    return false;
  }

  @override
  String toString() {
    return "${super.toString()} sysex data ${hexQuickView(data)}";
  }
}

abstract class MetaEvent extends MidiEvent {
  int metaCommand;
  List<int> data;

  static const int META_TIME_SIG = 0x58;
  static const int META_TEMPO = 0x51;
  static const int META_END_OF_TRACK = 0x2F;

  MetaEvent._();

  MetaEvent._withParam(this.metaCommand, this.data)
      : super.withParam(
            MidiEvent.CMD_META_EVENT); // properly use the full command here (i.e. 0xFF)

  factory MetaEvent(int metaCommand, [List<int> data]) {
    MetaEvent event = new MetaEvent.base(MidiEvent.CMD_META_EVENT, metaCommand);
    event.data = data;
    return event;
  }

  factory MetaEvent.base(int command, int metaCommand) {
    MetaEvent event;
    switch (metaCommand) {
      case META_TIME_SIG:
        event = new TimeSigEvent._();
        break;
      case META_TEMPO:
        event = new TempoEvent._();
        break;
      case META_END_OF_TRACK:
        event = new EndOfTrackEvent._();
        break;
      default:
        event = new _MetaEvent();
        break;
    }
    event.command = command;
    event.metaCommand = metaCommand;
    return event;
  }

  void readData(MidiParser parser) {
    // Don't re-read meta command
    if (metaCommand == null) {
      metaCommand = parser.readUint8();
    }
    int dataSize = parser.readVariableLengthData();
    if (dataSize > 0) {
      OutBuffer buffer = new OutBuffer(dataSize);
      parser.read(buffer, dataSize);
      data = buffer.data;
    }
  }

  void writeData(MidiWriter writer) {
    writer.writeUint8(metaCommand);
    int dataSize = data == null ? 0 : data.length;
    writer.writeVariableLengthData(dataSize);
    if (dataSize > 0) {
      writer.write(data);
    }
  }

  @override
  int get hashCode => super.hashCode * 17 + metaCommand;

  @override
  bool operator ==(other) {
    if (super == (other)) {
      if (other.metaCommand != metaCommand) {
        return false;
      }
      return (const ListEquality().equals(other.data, data));
    }
    return false;
  }

  @override
  String toString() {
    return "${super.toString()} meta ${metaCommand} data ${hexQuickView(data)}";
  }
}

/**
   * Time Signature This meta event is used to set a sequences time signature.
   * 
   * The time signature defined with 4 bytes, a numerator, a denominator, a
   * metronome pulse and number of 32nd notes per MIDI quarter-note. The
   * numerator is specified as a literal value, but the denominator is
   * specified as (get ready) the value to which the power of 2 must be raised
   * to equal the number of subdivisions per whole note. For example, a value
   * of 0 means a whole note because 2 to the power of 0 is 1 (whole note), a
   * value of 1 means a half-note because 2 to the power of 1 is 2
   * (half-note), and so on. The metronome pulse specifies how often the
   * metronome should click in terms of the number of clock signals per click,
   * which come at a rate of 24 per quarter-note. For example, a value of 24
   * would mean to click once every quarter-note (beat) and a value of 48
   * would mean to click once every half-note (2 beats). And finally, the
   * fourth byte specifies the number of 32nd notes per 24 MIDI clock signals.
   * This value is usually 8 because there are usually 8 32nd notes in a
   * quarter-note. At least one Time Signature Event should appear in the
   * first track chunk (or all track chunks in a Type 2 file) before any
   * non-zero delta time events. If one is not specified 4/4, 24, 8 should be
   * assumed.
   * 
   * Meta Event Type Length Numer Denom Metro 32nds<br>
   * 255 (0xFF) 88 (0x58) 4 0-255 0-255 0-255 1-255 Time Signature Meta Event
   * Values
   * 
   * <li>04 nn dd ccbb
   * <ul>
   * <li>nn numerator time sig<
   * <li>denominator time sig (2 quarter, 3 eighth) etc...
   * <li>cc number of ticks in metronome click
   * <li>bb number of 32nd notes to the quarter notes
   * </ul>
   * 
   * @author Alex
   * 
   */
class TimeSigEvent extends MetaEvent {
  TimeSigEvent._() : super._();

  static List<int> createData(
      int num, int denom, int tickCount, int num32ndToQuarter) {
    return [num, denom, tickCount, num32ndToQuarter];
  }

  static int bottomToDenom(int bottom) {
    int denominator = 0;
    int initialBottom = bottom;
    while (bottom > 1) {
      bottom >>= 1;
      denominator++;
    }
    if (1 << denominator != initialBottom) {
      throw new FormatException("bottom $bottom not supported");
    }
    return denominator;
  }

  TimeSigEvent.topBottom(int top, int bottom)
      : this(top, bottomToDenom(bottom));
  TimeSigEvent(int num, int denom, [int tickCount = 24, num32ndToQuarter = 8])
      : super._withParam(MetaEvent.META_TIME_SIG,
            createData(num, denom, tickCount, num32ndToQuarter));
//  public TimeSig(int num, int denom) {
//    super(META_TIME_SIG);
//      data = new byte[4];
//      data[0] = Util.intToByte(num);
//      int numerator = 0;
//      switch (num) {
//      case 1:
//        break;
//      case 2:
//        numerator = 1;
//        break;
//      case 4:
//        numerator = 2;
//        break;
//      }
//      data[1] = Util.intToByte(numerator);
//      data[2] = 24;
//      data[3] = 8;
//    }
//
//    private TimeSig() {
//    }
//
  int get bottom {
    return 1 << data[1];
  }

  int get top => data[0];

  @override
  String toString() {
    return "${super.toString()} ${top}/${bottom} ${data[2]} ${data[3]}";
  }
//
//    @Override
//    public String toString() {
//      return String.format("%s time_sig %d/%d %d %d", super.toString(),
//          (int) data[0], getDenominator(), (int) data[2],
//          (int) data[3]);
//    }
}

/**
   * Tempo
   * <p>
   * 51 03 tttttt tempo
   * </p>
   * 
   * <p>
   * This meta event sets the sequence tempo in terms of microseconds per
   * quarter-note which is encoded in three bytes. It usually is found in the
   * first track chunk, time-aligned to occur at the same time as a MIDI clock
   * message to promote more accurate synchronization. If no set tempo event
   * is present, 120 beats per minute is assumed. The following formula's can
   * be used to translate the tempo from microseconds per quarter-note to
   * beats per minute and back.
   * </p>
   * 
   * MICROSECONDS_PER_MINUTE = 60000000
   * 
   * <ul>
   * <li>BPM = MICROSECONDS_PER_MINUTE / MPQN</li>
   * <li>MPQN = * MICROSECONDS_PER_MINUTE / BPM</li>
   * </ul>
   */
class TempoEvent extends MetaEvent {
  TempoEvent._() : super._();

  TempoEvent.bpm(num bpm) : this(MICROSECONDS_PER_MINUTE ~/ bpm);

  TempoEvent(int tempo)
      : super._withParam(
            MetaEvent.META_TEMPO, create3BytesBEIntegerBuffer(tempo));

  static const int MICROSECONDS_PER_MINUTE = 60000000;

  num get beatPerMillis => 1000 / tempo;
  int get tempo => read3BytesBEInteger(data);
  num get tempoBpm => MICROSECONDS_PER_MINUTE / tempo;

  @override
  String toString() {
    return "${super.toString()} bpm $tempoBpm";
  }
}

/**
   * End Of Track
   * <p>
   * This meta event is used to signal the end of a track chunk and must
   * always appear as the last event in every track chunk.
   * <ul>
   * <li>Meta Event Type Length</li>
   * <li>255 (0xFF) 47 (0x2F) 0
   * <li>End Of Track Meta Event Values
   * </ul
   * 
   * @author Alex
   * 
   */
class EndOfTrackEvent extends MetaEvent {
  EndOfTrackEvent._() : super._() {}

  EndOfTrackEvent() : super._withParam(MetaEvent.META_END_OF_TRACK, null);

  @override
  String toString() {
    return "${super.toString()} eot";
  }
}

class _MetaEvent extends MetaEvent {
  _MetaEvent() : super._();
}
