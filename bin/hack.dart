import 'dart:async';
import 'dart:isolate';

import 'package:ruby_dart_brewery/ruby_dart_brewery.dart';

void main() {
  var rp = new ReceivePort();

  getPublishedBinary('be', DART_EDITOR_MAC_64_PATH).then((_) {
    print(_);
    print('done!');
  }).whenComplete(() {
    rp.close();
  });
}

void gettingInfo() {

  Future.forEach(['be', 'dev', 'stable'], (channel) {
    return _printChannel(channel);
  });
}

Future _printChannel(String channel) {
  return getVersionInfo(channel).then((versionInfo) {
    print(versionInfo);
  });
}
