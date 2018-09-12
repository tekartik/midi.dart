library tekartik_midi_file_player;

import 'midi.dart';
import 'dart:math';
import 'package:tekartik_common_utils/log_utils.dart';

class PlayableEvent {
  num timestamp; // ms
  MidiEvent midiEvent;

  PlayableEvent(this.timestamp, this.midiEvent);

  @override
  String toString() {
    return '${formatTimestampMs(timestamp)} ${midiEvent.toString()}';
  }
}

class LocatedTrackPlayer {
  MidiTrack track;

  int _currentEventIndex = 0;
  num _currentEventMs = 0;
  LocatedEvent _current;

  LocatedTrackPlayer(this.track);

  LocatedEvent current(num timeUnitInMs) {
    if (_current == null) {
      if (_currentEventIndex < track.events.length) {
        TrackEvent trackEvent = track.events[_currentEventIndex];
        _currentEventMs += trackEvent.deltaTime * timeUnitInMs;
        _current = new LocatedEvent(_currentEventMs, trackEvent.midiEvent);
      }
    }
    return _current;
  }

  LocatedEvent next(num timeUnitInMs) {
    _currentEventIndex++;
    _current = null;
    return current(timeUnitInMs);
  }
}

class NoteOnKey {
  int channel;
  int note;

  NoteOnKey(this.channel, this.note);

  @override
  int get hashCode => channel * 128 + note;

  @override
  bool operator ==(other) {
    return other is NoteOnKey && other.channel == channel && other.note == note;
  }
}

/**
 * For all tracks
 */
class LocatedEvent {
  num absoluteMs; // ms since start without speed ratio affected

  MidiEvent midiEvent;

  LocatedEvent(this.absoluteMs, this.midiEvent);

  @override
  String toString() {
    return '${formatTimestampMs(absoluteMs)} ${midiEvent.toString()}';
  }
}

class MidiFilePlayer {
  Map<NoteOnKey, PlayableEvent> notesOn = new Map();

  MidiFile _file;

  MidiFilePlayer(this._file);

  bool get isPlaying => _startTimestamp != null && _lastPauseTimestamp == null;
  // in millis
  // This is changed when paused/resume
  num _startTimestamp;

  // save for updating _startTimestamp on resume
  num _lastPauseTimestamp;

  num get startTimestamp => _startTimestamp;

  // default tempo
  TempoEvent _currentTempoEvent = new TempoEvent.bpm(120);

  Iterable<PlayableEvent> get currentNoteOnEvents => notesOn.values;

  List<LocatedEvent> _locatedEvents;
  int currentLocatedEventIndex;

  List<LocatedEvent> get locatedEvents {
    _prepareForLocation();
    return _locatedEvents;
  }

  num get totalDurationMs {
    if (locatedEvents.isNotEmpty) {
      return locatedEvents.last.absoluteMs;
    }
    return 0;
  }

  // from 0 to 1
  num getProgress(num currentTimestamp) {
    num totalDuration = totalDurationMs;
    if (totalDuration == 0) {
      return 0;
    }
    num progress = timestampToAbsoluteMs(currentTimestamp) / totalDuration;
    return min(max(progress, 0), 1);
  }

  List<LocatedEvent> _prepareForLocation() {
    if (_locatedEvents == null) {
      List<LocatedTrackPlayer> trackPlayers = new List();
      for (int i = 0; i < _file.tracks.length; i++) {
        trackPlayers.add(new LocatedTrackPlayer(_file.tracks[i]));
      }

      _locatedEvents = new List();

      while (true) {
        // must be null each time
        LocatedTrackPlayer nextTrackPlayer;
        num nextMs;

        trackPlayers.forEach((LocatedTrackPlayer trackPlayer) {
          LocatedEvent event =
              trackPlayer.current(currentDeltaTimeUnitInMillis);
          if (event != null) {
            num trackNextMs = event.absoluteMs;
            if (nextMs == null || (trackNextMs < nextMs)) {
              nextMs = trackNextMs;
              nextTrackPlayer = trackPlayer;
            }
          }
        });

        if (nextTrackPlayer != null) {
          LocatedEvent event =
              nextTrackPlayer.current(currentDeltaTimeUnitInMillis);
          // if no next, remove track
          if (nextTrackPlayer.next(currentDeltaTimeUnitInMillis) == null) {
            trackPlayers.remove(nextTrackPlayer);
          }

          MidiEvent midiEvent = event.midiEvent;
          if (midiEvent is TempoEvent) {
            _setCurrentTempoEvent(midiEvent);
          }
          _locatedEvents.add(event);
        } else {
          break;
        }
      }
    }
    return _locatedEvents;
  }

  // 1 means normal speed, 2 means twice faster, 0.5 means 50% slower
  num _speedRatio = 1;
  void setSpeedRatio(num ratio, [num currentTimestamp]) {
    // Change start time according to now
    if (currentTimestamp != null) {
      // The delta has the old ratio
      // start        current
      //   |------------|
      num currentMs = timestampToAbsoluteMs(currentTimestamp);
      _speedRatio = ratio;
      _startTimestamp -= (absoluteMsToTimestamp(currentMs) - currentTimestamp);
    } else {
      _speedRatio = ratio;
    }
  }

  //TODO
//  void setSpeedRatio(num ratio, num timestamp) {
//    _speedRatio = ratio;
//  }

  void _setCurrentTempoEvent(TempoEvent event) {
    // invalidate param
    currentDeltaTimeUnitInMillis = null;
    _currentTempoEvent = event;
  }

  num get tempoBpm => _currentTempoEvent.tempoBpm;

  num _currentDeltaTimeUnitInMillis; // no ratio
  //num _currentTimeUnitInMillis;

  // no ratio
  num get currentDeltaTimeUnitInMillis {
    if (_currentDeltaTimeUnitInMillis == null) {
      // beat = quarter note
      num beatPerMillis = _currentTempoEvent.beatPerMillis;

      // check midi docs here
      if (_file.ppq != null) {
        _currentDeltaTimeUnitInMillis = 1 / (_file.ppq * beatPerMillis);
      } else {
        _currentDeltaTimeUnitInMillis = 1 /
            (_file.frameCountPerSecond *
                _file.divisionCountPerFrame *
                beatPerMillis);
      }
    }
    return _currentDeltaTimeUnitInMillis;
  }

  set currentDeltaTimeUnitInMillis(num value) {
    _currentDeltaTimeUnitInMillis = value;
  }

//  num deltaTimeToMillis(int delay) {
//    return delay * _currentTimeUnitInMillis;
//  }

  // apply ratio
  num absoluteMsToTimestamp(num absoluteMs) {
    return startTimestamp + absoluteMs / _speedRatio;
  }

  num timestampToAbsoluteMs(num timestamp) {
    return (timestamp - startTimestamp) * _speedRatio;
  }

  // don't pause if not paused yet
  void pause(num timestamp) {
    if (_lastPauseTimestamp == null) {
      _lastPauseTimestamp = timestamp;
    }
  }

  void start(num timestamp) {
    notesOn = new Map();
    _locatedEvents = null;
    _startTimestamp = timestamp;

    currentLocatedEventIndex = null;
  }

  // Todo
  void resume(num timestamp) {
    if (_startTimestamp == null) {
      start(timestamp);
    } else {
      if (_lastPauseTimestamp != null) {
        _startTimestamp += timestamp - _lastPauseTimestamp;
        _lastPauseTimestamp = null;
      }
    }
  }

  PlayableEvent get next {
    if (!isPlaying) {
      return null;
    }
    if (currentLocatedEventIndex == null) {
      currentLocatedEventIndex = 0;
    } else {
      currentLocatedEventIndex++;
    }
    if (currentLocatedEventIndex < locatedEvents.length) {
      LocatedEvent locatedEvent = locatedEvents[currentLocatedEventIndex];
      num timestamp = absoluteMsToTimestamp(locatedEvent.absoluteMs);

      PlayableEvent event =
          new PlayableEvent(timestamp, locatedEvent.midiEvent);
      MidiEvent midiEvent = locatedEvent.midiEvent;

// And Note on event and remove note off event (and note on with velocity 0)
      if (midiEvent is NoteOnEvent) {
        NoteOnKey key = new NoteOnKey(midiEvent.channel, midiEvent.note);

        if (midiEvent.velocity > 0) {
          notesOn[key] = event;
        } else {
          notesOn.remove(key);
        }
      } else if (midiEvent is NoteOffEvent) {
        NoteOnKey key = new NoteOnKey(midiEvent.channel, midiEvent.note);
        notesOn.remove(key);
      }

      return event;
    }
    return null;
  }
}

Duration getMidiFileDuration(MidiFile file) {
  MidiFilePlayer player = new MidiFilePlayer(file);
  return new Duration(milliseconds: player.totalDurationMs.ceil());
}
