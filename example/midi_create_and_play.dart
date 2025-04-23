import 'create_midi_file.dart';
import 'midi_play.dart';

Future<void> main(List<String> args) async {
  var file = getDemoFileCDE();
  final player = StdoutMidiPlayer();
  player.load(file);
  player.resume();
  await player.done;
}
