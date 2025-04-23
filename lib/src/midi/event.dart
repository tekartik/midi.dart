import 'package:collection/collection.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_common_utils/hex_utils.dart';
import 'package:tekartik_midi/midi_parser.dart';
import 'package:tekartik_midi/midi_writer.dart';
import 'package:tekartik_midi/src/buffer/midi_buffer.dart';

/// Track event.
///
/// Midi event with its delta time information.
class TrackEvent {
  /// Delta-Times
  ///
  /// The event delta time is defined by a variable-length value. It determines
  /// when an event should be played relative to the track's last event. A delta
  /// time of 0 means that it should play simultaneously with the last event.
  /// A track's first event delta time defines the amount of time to wait before
  /// playing this first event. Events unaffected by time are still preceded
  /// by a delta time, but should always use a value of 0 and come first in the
  /// stream of track events. Examples of this type of event include track
  /// titles and copyright information. The most important thing to remember
  /// about delta times is that they are relative values, not absolute times.
  /// The actual time they represent is determined by a couple factors.
  /// The time division (defined in the MIDI header chunk) and the tempo
  /// (defined with a track event). If no tempo is define, 120 beats
  /// per minute is assumed.
  final int deltaTime;

  /// The midi event
  final MidiEvent midiEvent;

  /// Constructor
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

/// Base midi event.
abstract class MidiEvent {
  /// Event command combining channel and event type (called command too).
  int get command => _command;
  late int _command;
  @Deprecated('Removed some day')
  set command(int command) {
    _command = command;
  }

  /// Available channel count.
  static const int channelCount = 16;

  /// Available note count.
  static const int noteCount = 128;

  /// Note off event type.
  static const int noteOff = 8;

  /// Note on event type.
  static const int noteOn = 9;

  /// Key after touch event type.
  static const int keyAfterTouch = 0xA;

  /// Control change event type.
  static const int controlChange = 0xB;

  /// Program change event type.
  static const int programChange = 0xC;

  /// Channel after touch event type.
  static const int channelAfterTouch = 0xD;

  /// Pitch wheel event type.
  static const int pitchWheelChange = 0xE;

  /// Meta event event type.
  static const int metaEvent = 0xF;

  /// Meta command.
  static const int cmdMetaEvent = 0xFF;

  /// Constructor
  MidiEvent();

  /// Constructor with command
  MidiEvent.withParam(this._command);

  /// Compute command from an event type and a channel
  static int commandChannel(int eventType, int channel) {
    return ((eventType << 4) | (channel & 0xF));
  }

  /// Get the event type
  @Deprecated('use commandGetEventType')
  static int commandGetCommand(int command) => commandGetEventType(command);

  /// Get the event type
  static int commandGetEventType(int command) {
    return ((command & 0xF0) >> 4);
  }

  /// Get the channel
  static int commandGetChannel(int command) {
    // (command & 0xF)
    return (command & 0xF);
  }

  /// Get the event type
  int get eventType => commandGetEventType(command);

  /// Get the event type
  @Deprecated('user event type instead')
  int get codeCommand => eventType;

  /// Base command
  factory MidiEvent.base(int command) {
    MidiEvent event;

    final eventType = commandGetEventType(command);
    switch (eventType) {
      case noteOff:
        event = NoteOffEvent._();
        break;
      case noteOn:
        event = NoteOnEvent._();
        break;
      case keyAfterTouch:
        event = KeyAfterTouchEvent._();
        break;
      case controlChange:
        event = ControlChangeEvent._();
        break;
      case programChange:
        event = ProgramChangeEvent._();
        break;
      case channelAfterTouch:
        event = ChannelAfterTouchEvent._();
        break;
      case pitchWheelChange:
        event = PitchWheelChangeEvent._();
        break;
      default:
        // Meta!
        // not handled here
        // event = new MetaEvent();
        // return null;
        throw 'Event $eventType not supported in MidiEvent.base';
    }
    // ignore: prefer_initializing_formals
    event._command = command;
    return event;
  }

  /// Read data from a parser.
  void readData(MidiParser parser);

  /// Write data from a parser.
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
    return hexUint8(command);
  }
}

/// Channel event.
abstract class ChannelEvent extends MidiEvent {
  /// Channel
  int get channel => MidiEvent.commandGetChannel(command);

  /// Constructor
  ChannelEvent();

  /// Constructor with command and channel
  ChannelEvent.withParam(int command, int channel)
      : super.withParam(MidiEvent.commandChannel(command, channel));
}

/// Param1ByteEvent
abstract class Param1ByteEvent extends ChannelEvent {
  int? _param1;

  /// Constructor
  Param1ByteEvent();

  /// Constructor with command, channel and param1
  Param1ByteEvent.withParam(super.command, super.channel, this._param1)
      : super.withParam();

  @override
  void readData(MidiParser parser) {
    _param1 = parser.readUint8();
  }

  @override
  void writeData(MidiWriter writer) {
    writer.writeUint8(_param1!);
  }

  @override
  int get hashCode => super.hashCode * 17 + _param1!;

  @override
  bool operator ==(other) {
    if (super == (other) && other is Param1ByteEvent) {
      return other._param1 == _param1;
    }
    return false;
  }

  @override
  String toString() {
    return '${super.toString()} p1 $_param1';
  }
}

/// Program change event.
class ProgramChangeEvent extends Param1ByteEvent {
  /// Program
  int? get program => _param1;

  set program(int? program) {
    _param1 = program;
  }

  ProgramChangeEvent._();

  /// Constructor
  ProgramChangeEvent(int channel, int program) //
      : super.withParam(MidiEvent.programChange, channel, program);

  @override
  String toString() {
    return '${super.toString()} program change';
  }
}

/// 2 bytes param event
abstract class Param2BytesEvent extends Param1ByteEvent {
  int? _param2;

  /// Constructor
  Param2BytesEvent();

  /// Constructor with command, channel, param1 and param2
  Param2BytesEvent.withParam(
      super.command, super.channel, super.param1, this._param2) //
      : super.withParam();

  @override
  void readData(MidiParser parser) {
    super.readData(parser);
    _param2 = parser.readUint8();
  }

  @override
  void writeData(MidiWriter writer) {
    super.writeData(writer);
    writer.writeUint8(_param2!);
  }

  @override
  bool operator ==(other) {
    if (super == (other) && other is Param2BytesEvent) {
      return other._param2 == _param2;
    }
    return false;
  }

  @override
  int get hashCode => super.hashCode * 31 + _param2!;

  @override
  String toString() {
    return '${super.toString()} p2 $_param2';
  }
}

/// Channel after touch event.
class ChannelAfterTouchEvent extends Param1ByteEvent {
  /// Amount
  int? get amount => _param1;

  ChannelAfterTouchEvent._();

  /// Constructor
  ChannelAfterTouchEvent(int command, int channel, int amount) //
      : super.withParam(MidiEvent.channelAfterTouch, channel, amount);

  set amount(int? channel) {
    _param1 = channel;
  }

  @override
  String toString() {
    return '${super.toString()} channel after touch';
  }
}

/// Note On: 9x nn vv
/// <ol>
/// <li>nn note number</li>
/// <li>vv velocity</li>
/// </ol>
///
/// @author Alex
///
abstract class NoteEvent extends Param2BytesEvent {
  /// note
  int? get note => _param1;

  set note(int? note) {
    _param1 = note;
  }

  /// velocity
  int? get velocity => _param2;

  set velocity(int? velocity) {
    _param2 = velocity;
  }

  /// Constructor
  NoteEvent();

  /// Constructor with command, channel, note and velocity
  NoteEvent.withParam(
      super.command, super.channel, super.noteNumber, int super.velocity)
      : super.withParam();
}

/// Note on event.
class NoteOnEvent extends NoteEvent {
  NoteOnEvent._();

  /// Constructor
  NoteOnEvent(int channel, int noteNumber, int velocity) //
      : super.withParam(MidiEvent.noteOn, channel, noteNumber, velocity);

  @override
  String toString() {
    return '${super.toString()} note on';
  }
}

/// Note off event.
class NoteOffEvent extends NoteEvent {
  NoteOffEvent._();

  /// Constructor
  NoteOffEvent(int channel, int? noteNumber, int velocity) //
      : super.withParam(MidiEvent.noteOff, channel, noteNumber, velocity);

  @override
  String toString() {
    return '${super.toString()} note off';
  }
}

/// Key after touch event.
class KeyAfterTouchEvent extends NoteEvent {
  KeyAfterTouchEvent._();

  /// Constructor
  KeyAfterTouchEvent(int channel, int noteNumber, int velocity) //
      : super.withParam(MidiEvent.keyAfterTouch, channel, noteNumber, velocity);

  @override
  String toString() {
    return '${super.toString()} after touch';
  }
}

/// Pitch wheel change event
class PitchWheelChangeEvent extends Param2BytesEvent {
  /// bottom
  int? get bottom => _param1;

  set bottom(int? bottom) {
    _param1 = bottom;
  }

  /// top
  int? get top => _param2;

  set top(int? top) {
    _param2 = top;
  }

  PitchWheelChangeEvent._();

  /// Constructor
  PitchWheelChangeEvent(int channel, int noteNumber, int velocity) //
      : super.withParam(
            MidiEvent.pitchWheelChange, channel, noteNumber, velocity);

  @override
  String toString() {
    return '${super.toString()} pitch wheel change';
  }
}

/// cc control number vv new value
class ControlChangeEvent extends Param2BytesEvent {
  ControlChangeEvent._();

  /// Constructor
  ControlChangeEvent.withParam(
      int channel, int controllerType, int controllerValue)
      : super.withParam(
            MidiEvent.controlChange, channel, controllerType, controllerValue);

  /// all notes off
  static int allNotesOff = 123; // <= note off
  /// all reset
  static int allReset = 121; // <= reset
  /// all sound off
  static int allSoundOff = 120; // <= quick mute

  /// controller
  int? get controller => _param1;

  /// controller
  set controller(int? controller) {
    _param1 = controller;
  }

  /// value
  int? get value => _param2;

  set value(int? value) {
    _param2 = value;
  }

  @override
  String toString() {
    return '${super.toString()} control change';
  }

  /// Create a all sound off event
  static ControlChangeEvent newAllSoundOffEvent(int channel) =>
      ControlChangeEvent.withParam(channel, allSoundOff, 0);

  /// Create a all notes off event
  static ControlChangeEvent newAllNotesOffEvent(int channel) =>
      ControlChangeEvent.withParam(channel, allNotesOff, 0);

  /// Create a all reset event
  static ControlChangeEvent newAllResetEvent(int channel) =>
      ControlChangeEvent.withParam(channel, allReset, 0);
//null;
}

/// Normal SysEx Events.
///
/// These are the most common type of SysEx event and are used to hold a single
/// block of manufacturer specific data. The first byte is always 0xF0 and the
/// second is a variable-length value that specifies the length of the following
/// SysEx data in bytes. The SysEx data bytes must always end with a 0xF7 byte
/// to signal the end of the message.
/// SysEx Event Length  Data
/// 240 (0xF0)  variable-length data bytes, 0xF7
/// Normal SysEx Event Values
class SysExEvent extends MidiEvent {
  /// Data
  List<int> data;

  /// Constructor
  SysExEvent.withParam(super.command, [this.data = const <int>[]])
      : super.withParam(); // properly use the full command here (i.e. 0xFF)

  @override
  void readData(MidiParser parser) {
    var dataSize = parser.readVariableLengthData();
    if (dataSize > 0) {
      final buffer = OutBuffer(dataSize);
      parser.read(buffer, dataSize);
      data = buffer.data;
    }
  }

  @override
  void writeData(MidiWriter writer) {
    final dataSize = data.length;
    writer.writeVariableLengthData(dataSize);
    if (dataSize > 0) {
      writer.write(data);
    }
  }

  @override
  int get hashCode => super.hashCode * 17 + data.length;

  @override
  bool operator ==(other) {
    if (other is SysExEvent && super == (other)) {
      // ignore: inference_failure_on_instance_creation
      return (const ListEquality().equals(other.data, data));
    }
    return false;
  }

  @override
  String toString() {
    return '${super.toString()} sysex data ${hexQuickView(data)}';
  }
}

/// A Meta mide event.
abstract class MetaEvent extends MidiEvent {
  /// Meta command
  int? get metaCommand => _metaCommand;

  @Deprecated('removed some day')
  set metaCommand(int? metaCommand) {
    _metaCommand = metaCommand;
  }

  int? _metaCommand;

  /// Data
  List<int> get data => _data;

  @Deprecated('removed some day')
  set data(List<int> data) {
    _data = data;
  }

  List<int> _data;

  /// text
  static const int metaText = 0x1;

  /// track name
  static const int trackName = 0x3;

  /// time signature
  static const int metaTimeSig = 0x58;

  /// key signature
  static const int metaKeySig = 0x59;

  /// tempo
  static const int metaTempo = 0x51;

  /// end of track
  static const int metaEndOfTrack = 0x2F;

  MetaEvent._() : _data = <int>[];

  MetaEvent._withParam(this._metaCommand, {List<int>? data})
      : _data = data ?? <int>[],
        super.withParam(MidiEvent
            .cmdMetaEvent); // properly use the full command here (i.e. 0xFF)

  /// Constructor
  factory MetaEvent(int metaCommand, [List<int> data = const <int>[]]) {
    final event = MetaEvent.base(MidiEvent.cmdMetaEvent, metaCommand);
    // ignore: prefer_initializing_formals
    event._data = data;
    return event;
  }

  /// Constructor
  factory MetaEvent.base(int command, int metaCommand) {
    MetaEvent event;
    switch (metaCommand) {
      case metaText:
        event = MetaTextEvent._();
        break;
      case metaTimeSig:
        event = TimeSigEvent._();
        break;
      case metaTempo:
        event = TempoEvent._();
        break;
      case metaEndOfTrack:
        event = EndOfTrackEvent._();
        break;
      case trackName:
        event = TrackNameEvent._();
      case metaKeySig:
        event = KeySigEvent._();
        break;
      default:
        event = _MetaEvent();
        break;
    }
    event._command = command;
    // ignore: prefer_initializing_formals
    event._metaCommand = metaCommand;
    return event;
  }

  @override
  void readData(MidiParser parser) {
    // Don't re-read meta command
    _metaCommand ??= parser.readUint8();

    final dataSize = parser.readVariableLengthData();
    if (dataSize > 0) {
      final buffer = OutBuffer(dataSize);
      parser.read(buffer, dataSize);
      _data = buffer.data;
    }
  }

  @override
  void writeData(MidiWriter writer) {
    writer.writeUint8(metaCommand!);
    final dataSize = data.length;
    writer.writeVariableLengthData(dataSize);
    if (dataSize > 0) {
      writer.write(data);
    }
  }

  @override
  int get hashCode => super.hashCode * 17 + metaCommand!;

  @override
  bool operator ==(other) {
    if (other is MetaEvent && super == (other)) {
      if (other.metaCommand != metaCommand) {
        return false;
      }
      return (const ListEquality<int>().equals(other.data, data));
    }
    return false;
  }

  @override
  String toString() {
    return '${super.toString()} meta ${hexUint8(metaCommand!)}${data.isEmpty ? '' : ' data ${hexQuickView(data)}'}';
  }
}

/// Time Signature This meta event is used to set a sequences time signature.
///
/// The time signature defined with 4 bytes, a numerator, a denominator, a
/// metronome pulse and number of 32nd notes per MIDI quarter-note. The
/// numerator is specified as a literal value, but the denominator is
/// specified as (get ready) the value to which the power of 2 must be raised
/// to equal the number of subdivisions per whole note. For example, a value
/// of 0 means a whole note because 2 to the power of 0 is 1 (whole note), a
/// value of 1 means a half-note because 2 to the power of 1 is 2
/// (half-note), and so on. The metronome pulse specifies how often the
/// metronome should click in terms of the number of clock signals per click,
/// which come at a rate of 24 per quarter-note. For example, a value of 24
/// would mean to click once every quarter-note (beat) and a value of 48
/// would mean to click once every half-note (2 beats). And finally, the
/// fourth byte specifies the number of 32nd notes per 24 MIDI clock signals.
/// This value is usually 8 because there are usually 8 32nd notes in a
/// quarter-note. At least one Time Signature Event should appear in the
/// first track chunk (or all track chunks in a Type 2 file) before any
/// non-zero delta time events. If one is not specified 4/4, 24, 8 should be
/// assumed.
///
/// Meta Event Type Length Numer Denom Metro 32nds<br>
/// 255 (0xFF) 88 (0x58) 4 0-255 0-255 0-255 1-255 Time Signature Meta Event
/// Values
///
/// <li>04 nn dd ccbb
/// <ul>
/// <li>nn numerator time sig<
/// <li>denominator time sig (2 quarter, 3 eighth) etc...
/// <li>cc number of ticks in metronome click
/// <li>bb number of 32nd notes to the quarter notes
/// </ul>
///
/// @author Alex
///
class TimeSigEvent extends MetaEvent {
  TimeSigEvent._() : super._();

  /// Create data
  static List<int> createData(
      int num, int denom, int tickCount, int num32ndToQuarter) {
    return [num, denom, tickCount, num32ndToQuarter];
  }

  /// bottom to denom
  static int bottomToDenom(int bottom) {
    var denominator = 0;
    var initialBottom = bottom;
    while (bottom > 1) {
      bottom >>= 1;
      denominator++;
    }
    if (1 << denominator != initialBottom) {
      throw FormatException('bottom $bottom not supported');
    }
    return denominator;
  }

  /// Create a time signature event
  TimeSigEvent.topBottom(int top, int bottom)
      : this(top, bottomToDenom(bottom));

  /// Create a time signature event
  TimeSigEvent(int num, int denom,
      [int tickCount = 24, int num32ndToQuarter = 8])
      : super._withParam(MetaEvent.metaTimeSig,
            data: createData(num, denom, tickCount, num32ndToQuarter));

  /// bottom
  int get bottom {
    return 1 << data[1];
  }

  /// top
  int get top => data[0];

  @override
  String toString() {
    return '${super.toString()} $top/$bottom ${data[2]} ${data[3]}';
  }
}

/// Key signature
/// This meta event is used to specify the key (number of sharps or flats) and scale (major or minor) of a sequence. A positive value for the key specifies the number of sharps and a negative value specifies the number of flats. A value of 0 for the scale specifies a major key and a value of 1 specifies a minor key.
///
/// Meta Event 	Type 	Length 	Key 	Scale
/// 255 (0xFF) 	89 (0x59) 	2 	-7-7 	0-1
///
/// https://www.recordingblogs.com/wiki/midi-key-signature-meta-message
class KeySigEvent extends MetaEvent {
  KeySigEvent._() : super._();

  static const _keyFromSharps = ['C', 'G', 'D', 'A', 'E', 'B', 'F#', 'C#'];
  static const _keyFromFlats = ['C', 'F', 'Bb', 'Eb', 'Ab', 'Db', 'Cb', 'Gb'];

  /// values between -7 and 7 and specifies the key signature in terms of number of flats (if negative) or sharps (if positive)
  int get alterations => _fixAlterations(byteToSignedValue(data[0]));

  static int _fixAlterations(int alterations) {
    if (alterations < -7 || alterations > 7) {
      return 0;
    }
    return alterations;
  }

  /// 0 the scale is major, 1 the scale is minor.
  int get scale => data[1];

  /// Constructor
  KeySigEvent(int alterations, int scale)
      : super._withParam(MetaEvent.metaTimeSig,
            data: [signedValueToByte(_fixAlterations(alterations)), scale]);
  @override
  String toString() {
    return '${super.toString()} '
        '${alterations >= 0 ? _keyFromSharps[alterations] : _keyFromFlats[-alterations]} '
        '${scale == 1 ? 'minor' : (scale == 0 ? 'major' : 'unknown scale')}';
  }
}

/// Tempo
/// <p>
/// 51 03 tttttt tempo
/// </p>
///
/// <p>
/// This meta event sets the sequence tempo in terms of microseconds per
/// quarter-note which is encoded in three bytes. It usually is found in the
/// first track chunk, time-aligned to occur at the same time as a MIDI clock
/// message to promote more accurate synchronization. If no set tempo event
/// is present, 120 beats per minute is assumed. The following formula's can
/// be used to translate the tempo from microseconds per quarter-note to
/// beats per minute and back.
/// </p>
///
/// MICROSECONDS_PER_MINUTE = 60000000
///
/// <ul>
/// <li>BPM = MICROSECONDS_PER_MINUTE / MPQN</li>
/// <li>MPQN = * MICROSECONDS_PER_MINUTE / BPM</li>
/// </ul>
class TempoEvent extends MetaEvent {
  TempoEvent._() : super._();

  /// Tempo event with bpm
  TempoEvent.bpm(num bpm) : this(microsecondsPerMinute ~/ bpm);

  /// Constructor
  TempoEvent(int tempo)
      : super._withParam(MetaEvent.metaTempo,
            data: create3BytesBEIntegerBuffer(tempo));

  /// 60,000,000 microseconds per minute
  static const int microsecondsPerMinute = 60000000;

  /// 60,000 milliseconds per minute
  static const int millisecondsPerMinute = 60000;

  /// tempo per millis: 0.002 for 120 bpm
  num get beatPerMillis => 1000 / tempo;

  /// tempo (ex: 500000 for 120 bpm)
  int get tempo => read3BytesBEInteger(data);

  /// tempo bmp (ex: 120 bpm)
  num get tempoBpm => microsecondsPerMinute / tempo;

  @override
  String toString() {
    return '${super.toString()} bpm $tempoBpm';
  }
}

/// End Of Track
/// <p>
/// This meta event is used to signal the end of a track chunk and must
/// always appear as the last event in every track chunk.
/// <ul>
/// <li>Meta Event Type Length</li>
/// <li>255 (0xFF) 47 (0x2F) 0
/// <li>End Of Track Meta Event Values
/// </ul
///
/// @author Alex
///
class EndOfTrackEvent extends MetaEvent {
  EndOfTrackEvent._() : super._();

  /// Constructor
  EndOfTrackEvent() : super._withParam(MetaEvent.metaEndOfTrack);

  @override
  String toString() {
    return '${super.toString()} eot';
  }
}

/// This meta event defines the name of a sequence when in a Type 0 or Type 2
/// MIDI file or in the first track of a Type 1 MIDI file. It defines a track
/// name when it appears in any track after the first in a Type 1 MIDI file.
///
/// This meta event should always have a delta time of 0 and come before all
/// MIDI Channel Events and non-zero delta time events.
class TrackNameEvent extends MetaEvent {
  TrackNameEvent._() : super._();

  /// Constructor
  TrackNameEvent({super.data}) : super._withParam(MetaEvent.trackName);

  /// track name
  String get trackName => String.fromCharCodes(data);

  @override
  String toString() {
    return '${super.toString()} track name: $trackName';
  }
}

class _MetaEvent extends MetaEvent {
  _MetaEvent() : super._();
}

/// This meta event defines some text which can be used for any reason including
/// track notes, comments, etc. The text string is usually ASCII text, but may
/// be any character (0x00-0xFF)..
class MetaTextEvent extends MetaEvent {
  MetaTextEvent._() : super._();

  /// Constructor
  MetaTextEvent({super.data}) : super._withParam(MetaEvent.metaText);

  /// Constructor
  MetaTextEvent.text(String text)
      : super._withParam(MetaEvent.metaText, data: utf8.encode(text));

  /// track name
  String get text => utf8.decode(data);

  @override
  String toString() {
    return '${super.toString()} text: $text';
  }
}
