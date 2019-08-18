import 'package:process_run/shell.dart';

Future main() async {
  var shell = Shell();

  await shell.run('''

  dartanalyzer --fatal-warnings --fatal-infos lib test tool example
  dartfmt -w lib test tool example --set-exit-if-changed

  pub run test -p vm
  pub run test -p chrome -j 1
  pub run build_runner test -- -p chrome
  ''');
}
