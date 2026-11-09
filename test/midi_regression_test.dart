library;

import 'dart:convert';

import 'package:tekartik_common_utils/hex_utils.dart';
import 'package:tekartik_midi/midi.dart';
import 'package:tekartik_midi/midi_file_player.dart';
import 'package:tekartik_midi/midi_parser.dart';
import 'package:tekartik_midi/midi_player_base.dart';
import 'package:tekartik_midi/midi_writer.dart';
import 'package:test/test.dart';

class _RecordingMidiPlayer extends MidiPlayerBase {
  final events = <PlayableEvent>[];

  @override
  num now;

  _RecordingMidiPlayer(this.now) : super(null);

  @override
  void rawPlayEvent(PlayableEvent event) {
    events.add(event);
  }
}

/// Write then read [event], the read event must be equal and of the same type.
MidiEvent _writeRead(MidiEvent event) {
  final writer = EventWriter(MidiWriter())..event = TrackEvent(0, event);
  writer.writeEvent();
  final parser = EventParser(MidiParser(writer.data))..parseEvent();
  expect(parser.event.runtimeType, event.runtimeType);
  expect(parser.event, event);
  return parser.event;
}

List<PlayableEvent> _playAll(MidiFilePlayer player) {
  var events = <PlayableEvent>[];
  PlayableEvent? event;
  while ((event = player.next) != null) {
    events.add(event!);
  }
  return events;
}

void main() {
  group('regression', () {
    test('key signature round trip', () {
      var event = KeySigEvent(-3, 1);
      expect(event.metaCommand, MetaEvent.metaKeySig);
      var read = _writeRead(event) as KeySigEvent;
      expect([read.alterations, read.scale], [-3, 1]);
      _writeRead(TimeSigEvent.topBottom(6, 8));
      _writeRead(TempoEvent.bpm(90));
      _writeRead(MetaTextEvent.text('hello'));
      _writeRead(TrackNameEvent(data: utf8.encode('track')));
    });

    test('meta event of the meta command type', () {
      expect(MetaEvent(MetaEvent.metaKeySig, [0, 0]), isA<KeySigEvent>());
      expect(
        MetaEvent(MetaEvent.metaTimeSig, [4, 2, 24, 8]),
        isA<TimeSigEvent>(),
      );
    });

    test('key signature names', () {
      expect(KeySigEvent(-6, 0).toString(), contains('Gb major'));
      expect(KeySigEvent(-7, 0).toString(), contains('Cb major'));
      expect(KeySigEvent(0, 1).toString(), contains('A minor'));
      expect(KeySigEvent(1, 1).toString(), contains('E minor'));
      expect(KeySigEvent(-1, 1).toString(), contains('D minor'));
      expect(KeySigEvent(2, 0).toString(), contains('D major'));
    });

    test('time signature', () {
      var event = TimeSigEvent.topBottom(4, 4);
      expect(event.data, [4, 2, 24, 8]);
      expect(event.bottom, 4);
      expect(TimeSigEvent(4, 2), event);
      expect(
        () => TimeSigEvent.bottomToDenom(3),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('bottom 3 '),
          ),
        ),
      );
    });

    test('text decoding never throws', () {
      // latin1 lyrics (.kar)
      var latin1Event = MetaTextEvent(data: latin1.encode('élève'));
      expect(latin1Event.text, 'élève');
      expect(latin1Event.toString(), contains('élève'));
      // utf8 track names
      var trackName = TrackNameEvent(data: utf8.encode('élève'));
      expect(trackName.trackName, 'élève');
      expect(MetaTextEvent.text('été').text, 'été');
    });

    test('same time events keep their order', () {
      final file = MidiFile()..ppq = 240;
      final track = MidiTrack();
      for (var i = 0; i < 100; i++) {
        track.addEvent(0, NoteOnEvent(0, i, 100));
      }
      // Off then on of the same note on the same tick.
      track.addEvent(240, NoteOffEvent(0, 60, 0));
      track.addEvent(0, NoteOnEvent(0, 60, 100));
      file.addTrack(track);
      final events = MidiFilePlayer(file).locatedEvents!;
      expect([
        for (var i = 0; i < 100; i++) (events[i].midiEvent as NoteEvent).note,
      ], List.generate(100, (i) => i));
      expect(events[100].midiEvent, isA<NoteOffEvent>());
      expect(events[101].midiEvent, isA<NoteOnEvent>());
    });

    test('restart uses the initial tempo', () {
      final file = MidiFile()..ppq = 240;
      final track = MidiTrack();
      track.addEvent(0, NoteOnEvent(0, 60, 100));
      track.addEvent(240, TempoEvent.bpm(60));
      track.addEvent(240, NoteOffEvent(0, 60, 0));
      file.addTrack(track);

      final freshTimestamps = (() {
        final player = MidiFilePlayer(file)..start(0);
        return _playAll(player).map((e) => e.timestamp.round()).toList();
      })();
      expect(freshTimestamps, [0, 500, 1500]);

      final player = MidiFilePlayer(file);
      expect(player.totalDurationMs, closeTo(1500, 0.01));
      player.start(0);
      expect(_playAll(player).map((e) => e.timestamp.round()), freshTimestamps);
      // Played again
      player.start(0);
      expect(_playAll(player).map((e) => e.timestamp.round()), freshTimestamps);
    });

    test('smpte timing does not depend on the tempo', () {
      final file = MidiFile()..setFrameDivision(25, 40);
      final track = MidiTrack();
      track.addEvent(0, TempoEvent.bpm(60));
      track.addEvent(1000, EndOfTrackEvent());
      file.addTrack(track);
      expect(MidiFilePlayer(file).totalDurationMs, closeTo(1000, 0.01));
      expect(
        midiDeltaTimeUnitToMillis(
          frameCountPerSecond: 25,
          divisionCountPerFrame: 40,
        ),
        closeTo(1, 0.0001),
      );
      expect(file.delayToMillis(1000), closeTo(1000, 0.01));
    });

    test('delayToMillis', () {
      final file = MidiFile()..ppq = 480;
      // 120 bpm, the default tempo.
      expect(file.delayToMillis(480), closeTo(500, 0.01));
    });

    test('all notes off', () {
      final player = _RecordingMidiPlayer(0);
      player.allNotesOff();
      expect(player.events.length, MidiEvent.channelCount);
      expect(
        player.events.map(
          (e) => (e.midiEvent as ControlChangeEvent).controller,
        ),
        everyElement(ControlChangeEvent.allNotesOff),
      );
      player.events.clear();
      player.allSoundOff();
      expect(
        (player.events.first.midiEvent as ControlChangeEvent).controller,
        ControlChangeEvent.allSoundOff,
      );
      player.events.clear();
      player.allReset();
      expect(
        (player.events.first.midiEvent as ControlChangeEvent).controller,
        ControlChangeEvent.allReset,
      );
    });

    test('output timestamp', () {
      final player = _RecordingMidiPlayer(0);
      final file = MidiFile()..ppq = 240;
      file.addTrack(MidiTrack()..addEvent(100000, EndOfTrackEvent()));
      player.load(file);
      // A pause of 1000 ms.
      player.rawPause();
      player.now = 1000;
      player.resume();
      // The pre fill duration twice, the pause is already in the event
      // timestamp, not counted again.
      expect(
        player.eventTimestampToOutputTimestamp(
          PlayableEvent(100, NoteOnEvent(0, 60, 100)),
        ),
        500,
      );
      player.pause();
    });

    test('new midi file', () {
      final file = MidiFile();
      expect(file.ppq, MidiFile.ppqDefault);
      expect(file.timeDivision, MidiFile.ppqDefault);
      expect(FileWriter.fileData(file), isNotEmpty);
      expect(file, MidiFile()..ppq = 120);
    });

    test('midi file hash code', () {
      MidiFile newFile() {
        final file = MidiFile();
        final track = MidiTrack()..addEvent(0, EndOfTrackEvent());
        file.addTrack(track);
        return file;
      }

      expect(newFile(), newFile());
      expect(newFile().hashCode, newFile().hashCode);
      expect({newFile(), newFile()}.length, 1);
    });

    test('running status after a meta event', () {
      // note on, a text meta event, then a note on with a running status.
      final data = parseHexString('00 90 40 60 00 ff 01 00 00 41 50');
      final parser = EventParser(MidiParser(data));
      expect(parser.parseEvent(), NoteOnEvent(0, 0x40, 0x60));
      expect(parser.parseEvent(), isA<MetaTextEvent>());
      expect(parser.parseEvent(), NoteOnEvent(0, 0x41, 0x50));
    });

    test('a huge event data length fails without allocating it', () {
      // One track: a text meta event of length FF FF FF 7F (256 MB) in a
      // 29 byte file. It used to allocate 2 GB before failing.
      final data = parseHexString(
        '4d 54 68 64 00 00 00 06 00 01 00 01 00 78 '
        '4d 54 72 6b 00 00 00 08 00 ff 01 ff ff ff 7f',
      );
      final sysex = parseHexString(
        '4d 54 68 64 00 00 00 06 00 01 00 01 00 78 '
        '4d 54 72 6b 00 00 00 08 00 f0 ff ff ff 7f',
      );
      final sw = Stopwatch()..start();
      for (var i = 0; i < 20; i++) {
        expect(() => FileParser.dataFile(data), throwsFormatException);
        expect(() => FileParser.dataFile(sysex), throwsFormatException);
      }
      expect(sw.elapsed, lessThan(const Duration(seconds: 5)));
    });

    test('a zero time division is invalid', () {
      // ppq 0, then 25 frames per second of 0 ticks.
      for (final division in ['00 00', 'e7 00']) {
        final data = parseHexString(
          '4d 54 68 64 00 00 00 06 00 01 00 01 $division '
          '4d 54 72 6b 00 00 00 08 00 90 40 60 00 ff 2f 00',
        );
        expect(
          () => FileParser.dataFile(data),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              'invalid time division',
            ),
          ),
        );
      }
    });

    test('alien chunks are skipped', () {
      final data = parseHexString(
        '4d 54 68 64 00 00 00 06 00 00 00 01 00 78 '
        // An unknown chunk of 2 bytes.
        '58 46 49 48 00 00 00 02 01 02 '
        '4d 54 72 6b 00 00 00 04 00 ff 2f 00',
      );
      final file = FileParser.dataFile(data)!;
      expect(file.trackCount, 1);
      expect(file.tracks.first.events.single.midiEvent, isA<EndOfTrackEvent>());
      // Truncated in the alien chunk.
      expect(
        () => FileParser.dataFile(data.sublist(0, 20)),
        throwsFormatException,
      );
    });

    test('many events due at once are played without a stack overflow', () {
      final file = MidiFile()..ppq = 120;
      final track = MidiTrack();
      for (var i = 0; i < 50000; i++) {
        track.addEvent(1, NoteOnEvent(0, 60, 100));
      }
      file.addTrack(track);
      final player = _RecordingMidiPlayer(0);
      player.load(file);
      // The first timer comes late (a device asleep): everything is due.
      player.now = 1e9;
      player.resume(0);
      expect(player.events.length, 50000);
    });
  });
}
