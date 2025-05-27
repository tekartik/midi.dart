library;

import 'dart:math';

import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_common_utils/list_utils.dart';

import 'midi.dart';
export 'src/player/time.dart'
    show midiDeltaTimeToMillis, midiDeltaTimeUnitToMillis;

/// Format a timestamp in ms}
///
/// Playable event
class PlayableEvent {
  /// in millis
  final num timestamp; // ms
  /// The event to play
  final MidiEvent midiEvent;

  /// Constructor
  PlayableEvent(this.timestamp, this.midiEvent);

  @override
  String toString() {
    return '${formatTimestampMs(timestamp)} ${midiEvent.toString()}';
  }
}

/// Prepare located events
class LocatedTrackPlayer {
  /// The track
  MidiTrack track;

  /// Constructor
  LocatedTrackPlayer(this.track);

  /// List of located events
  List<LocatedEvent> get preLocatedEvents {
    var events = <LocatedEvent>[];
    var currentTime = 0;
    for (var event in track.events) {
      currentTime += event.deltaTime;
      events.add(LocatedEvent.pre(currentTime, event.midiEvent));
    }
    return events;
  }
}

/// Key for note on
class NoteOnKey {
  /// Channel
  int channel;

  /// Note
  int note;

  /// Constructor
  NoteOnKey(this.channel, this.note);

  @override
  int get hashCode => channel * 128 + note;

  @override
  bool operator ==(other) {
    return other is NoteOnKey && other.channel == channel && other.note == note;
  }
}

/// For all tracks
class LocatedEvent {
  /// Filled later
  late num absoluteMs; // ms since start without speed ratio affected
  /// Time in delta time
  late int time;

  /// The event
  final MidiEvent midiEvent;

  /// Constructor
  LocatedEvent.pre(this.time, this.midiEvent);

  /// Constructor
  @Deprecated('Use LocatedEvent.pre')
  LocatedEvent(this.absoluteMs, this.midiEvent);

  @override
  String toString() {
    return '${formatTimestampMs(absoluteMs)} $time ${midiEvent.toString()}';
  }
}

/// Basic player, computing event real time location.
///
class MidiFilePlayer {
  @visibleForTesting
  /// Notes on
  Map<NoteOnKey, PlayableEvent> notesOn = {};

  final MidiFile _file;

  /// Constructor
  MidiFilePlayer(this._file);

  /// True if playing
  bool get isPlaying => _startTimestamp != null && _lastPauseTimestamp == null;

  // in millis
  // This is changed when paused/resume
  num? _startTimestamp;

  // save for updating _startTimestamp on resume
  num? _lastPauseTimestamp;

  /// Start timestamp
  num? get startTimestamp => _startTimestamp;

  // default tempo
  TempoEvent _currentTempoEvent = TempoEvent.bpm(120);

  /// current notes on
  @visibleForTesting
  Iterable<PlayableEvent> get currentNoteOnEvents => notesOn.values;

  List<LocatedEvent>? _locatedEvents;

  /// Current located event index
  @visibleForTesting
  int? currentLocatedEventIndex;

  /// List of events with their absolute computed location.
  List<LocatedEvent>? get locatedEvents {
    _prepareForLocation();
    return _locatedEvents;
  }

  /// Midi file total duration in millis.
  num get totalDurationMs {
    if (locatedEvents!.isNotEmpty) {
      return locatedEvents!.last.absoluteMs;
    }
    return 0;
  }

  /// from 0 to 1.
  num getProgress(num currentTimestamp) {
    final totalDuration = totalDurationMs;
    if (totalDuration == 0) {
      return 0;
    }
    num progress = timestampToAbsoluteMs(currentTimestamp) / totalDuration;
    return min(max(progress, 0), 1);
  }

  List<LocatedEvent>? _prepareForLocation() {
    if (_locatedEvents == null) {
      _locatedEvents = listFlatten(
        _file.tracks.map((e) => LocatedTrackPlayer(e).preLocatedEvents),
      )..sort((a, b) => a.time.compareTo(b.time));

      var ms = 0.0;
      var time = 0;
      // Compute ms
      for (var event in _locatedEvents!) {
        var eventTime = event.time;
        var eventMs = ms + (eventTime - time) * currentDeltaTimeUnitInMillis;
        event.absoluteMs = eventMs;
        // update current time
        time = eventTime;
        ms = eventMs;
        final midiEvent = event.midiEvent;
        if (midiEvent is TempoEvent) {
          _setCurrentTempoEvent(midiEvent);
        }
      }
      return _locatedEvents;
    }
    return _locatedEvents;
  }

  // 1 means normal speed, 2 means twice faster, 0.5 means 50% slower
  num _speedRatio = 1;

  /// Allow changing speed ratio without altering the tempo.
  void setSpeedRatio(num ratio, [num? currentTimestamp]) {
    // Change start time according to now
    if (currentTimestamp != null) {
      // The delta has the old ratio
      // start        current
      //   |------------|
      final currentMs = timestampToAbsoluteMs(currentTimestamp);
      _speedRatio = ratio;
      _startTimestamp =
          _startTimestamp! -
          (absoluteMsToTimestamp(currentMs) - currentTimestamp);
    } else {
      _speedRatio = ratio;
    }
  }

  void _setCurrentTempoEvent(TempoEvent event) {
    // invalidate param so that it gets computed again
    currentDeltaTimeUnitInMillis = null;
    _currentTempoEvent = event;
  }

  /// Current tempo in bmp.
  @visibleForTesting
  num get tempoBpm => _currentTempoEvent.tempoBpm;

  num? _currentDeltaTimeUnitInMillis; // no ratio
  //num _currentTimeUnitInMillis;

  /// no ratio
  @visibleForTesting
  num get currentDeltaTimeUnitInMillis {
    if (_currentDeltaTimeUnitInMillis == null) {
      // beat = quarter note
      final beatPerMillis = _currentTempoEvent.beatPerMillis;

      // check midi docs here
      if (_file.ppq != null) {
        _currentDeltaTimeUnitInMillis = 1 / (_file.ppq! * beatPerMillis);
      } else {
        _currentDeltaTimeUnitInMillis =
            1 /
            (_file.frameCountPerSecond! *
                _file.divisionCountPerFrame! *
                beatPerMillis);
      }
    }
    return _currentDeltaTimeUnitInMillis!;
  }

  @visibleForTesting
  set currentDeltaTimeUnitInMillis(num? value) {
    _currentDeltaTimeUnitInMillis = value;
  }

  //  num deltaTimeToMillis(int delay) {
  //    return delay * _currentTimeUnitInMillis;
  //  }

  /// Find the player timestamp given a millisecond location.
  num absoluteMsToTimestamp(num absoluteMs) {
    return startTimestamp! + absoluteMs / _speedRatio;
  }

  /// Convert a player timestamp to a millisecond location
  num timestampToAbsoluteMs(num timestamp) {
    return (timestamp - startTimestamp!) * _speedRatio;
  }

  /// Pause. Don't pause if not paused yet
  void pause(num timestamp) {
    _lastPauseTimestamp ??= timestamp;
  }

  /// Start player.
  void start(num timestamp) {
    notesOn = {};
    _locatedEvents = null;
    _startTimestamp = timestamp;

    currentLocatedEventIndex = null;
  }

  /// Result (TODO)
  void resume(num timestamp) {
    if (_startTimestamp == null) {
      start(timestamp);
    } else {
      if (_lastPauseTimestamp != null) {
        _startTimestamp = _startTimestamp! + timestamp - _lastPauseTimestamp!;
        _lastPauseTimestamp = null;
      }
    }
  }

  /// get the next event
  PlayableEvent? get next {
    if (!isPlaying) {
      return null;
    }
    if (currentLocatedEventIndex == null) {
      currentLocatedEventIndex = 0;
    } else {
      currentLocatedEventIndex = currentLocatedEventIndex! + 1;
    }
    if (currentLocatedEventIndex! < locatedEvents!.length) {
      final locatedEvent = locatedEvents![currentLocatedEventIndex!];
      final timestamp = absoluteMsToTimestamp(locatedEvent.absoluteMs);

      final event = PlayableEvent(timestamp, locatedEvent.midiEvent);
      final midiEvent = locatedEvent.midiEvent;

      // And Note on event and remove note off event (and note on with velocity 0)
      if (midiEvent is NoteOnEvent) {
        final key = NoteOnKey(midiEvent.channel, midiEvent.note);

        if (midiEvent.velocity > 0) {
          notesOn[key] = event;
        } else {
          notesOn.remove(key);
        }
      } else if (midiEvent is NoteOffEvent) {
        final key = NoteOnKey(midiEvent.channel, midiEvent.note);
        notesOn.remove(key);
      }

      return event;
    }
    return null;
  }
}

/// Get a file duration.
Duration getMidiFileDuration(MidiFile file) {
  final player = MidiFilePlayer(file);
  return Duration(milliseconds: player.totalDurationMs.ceil());
}
