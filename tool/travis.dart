import 'package:process_run/shell.dart';

Future main() async {
  final shell = Shell();

  await shell.run('''

  dartanalyzer --fatal-warnings --fatal-infos .
  dartfmt -n . --set-exit-if-changed

  pub run test -p vm
  pub run test -p chrome -j 1
  pub run build_runner test -- -p chrome
  ''');
}
