library ruby_dart_brewery;

import 'dart:async';
import 'dart:convert' show JSON;

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import 'src/constants.dart';
export 'src/constants.dart';

Future<VersionInfo> getVersionInfo(String channel, [int revision]) {
  var path = getChannelUrl(channel);

  if (revision == null) {
    path = p.join(path, 'latest');
  } else {
    path = p.join(path, revision.toString());
  }

  path = p.join(path, 'VERSION');

  return http.read(path).then(JSON.decode).then((json) {
    var info = new VersionInfo.fromMap(json);
    if (revision != null && revision != info.revision) {
      print("WEIRD: requested revision $revision, got '${info.revision}.");
    }
    return info;
  });
}

Future getPublishedBinary(String channel, String binaryPath) {
  VersionInfo latestInfo, revisionInfo;

  return getVersionInfo(channel).then((info) {
    print('$channel\tLatest revision: ${info.revision}');
    latestInfo = info;

    return getPublishedVersionInfo(channel, info.revision);
  }).then((info) {
    print('$channel\tPublished revision: ${info.revision}');
    revisionInfo = info;

    // Now try to get the binary
  });

  // get 'latest' version info

  // start trying to get the version info

}

Future<VersionInfo> getPublishedVersionInfo(String channel, int startRevision, [int attempts = 100]) {
  assert(attempts > 0);
  var attemptsLeft = attempts;
  var completer = new Completer<VersionInfo>();

  void work(int revision) {
    attemptsLeft--;
    if(attempts <= 0) {
      completer.completeError('Could not find published version for $channel starting at revision $startRevision in $attempts attemts.');
      return;
    }

    _getPublishedVersionInfoOrNull(channel, revision).then((info) {
      if (info == null) {
        work(revision - 1);
      } else {
        completer.complete(info);
      }
    });
  }

  work(startRevision);

  return completer.future;
}

Future<VersionInfo> _getPublishedVersionInfoOrNull(String channel, int revision) {
  return getVersionInfo(channel, revision).catchError((err, stack) {
    print('\terror getting $channel - $revision');
    return null;
  });
}

class BinaryInfo {
  final String binaryPath;
  final int binarySize;
  final String md5;
  final String sha256;
  final VersionInfo info;

  BinaryInfo(this.binaryPath, this.md5, this.sha256, this.info, this.binarySize);

  static Future<BinaryInfo> get(String channel, int revision, String binaryPath) {
    return getVersionInfo(channel, revision).then((info) {

    });
  }
}

/// requests:
///   key: full url
///   value: either 'stringContent' or 'size'
///
/// response:
///   key: full url
///   value - if it exists
///   - stringContent: content of the file (String)
///   - size: size of the file (int)
///   value - if not found - `null`
Future<Map<String, dynamic>> getFiles(http.Client client, Map<String, String> requests) {
  var result = {};

  return Future.forEach(requests.keys, (requestUrl) {
    var type = requests[requestUrl];

    if (type == 'stringContent') {
      return getStringContentOrNull(client, requestUrl).then((content) {
        result[requestUrl] = content;
      });
    } else if (type == 'size') {
      return getSizeOrNull(client, requestUrl).then((size) {
        result[requestUrl] = size;
      });
    } else {
      throw 'I do not like "$type".';
    }
  }).then((_) {
    return result;
  });
}

Future<String> getStringContentOrNull(http.Client client, String url) {
  return client.read(url).catchError((err, stack) {
    return null;
  });
}

Future<int> getSizeOrNull(http.Client client, String url) {
  return client.head(url).then((response) {
    return response.contentLength;
  }).catchError((err, stack) {
    return null;
  });
}

class VersionInfo {
  final int revision;
  final String version;
  final String dateString;

  VersionInfo(this.revision, this.version, this.dateString);

  factory VersionInfo.fromMap(Map<String, dynamic> map) {
    return new VersionInfo(int.parse(map['revision']), map['version'], map['date']);
  }

  String toString() => '$version @ $revision - $dateString';
}

String getChannelUrl(String channel) {
  switch(channel) {
    case 'be':
      return beRootUrl;
    case 'dev':
      return devRootUrl;
    case 'stable':
      return stableRootUrl;
    default:
      throw new ArgumentError('Channel "$channel" is unkwown.');
  }
}
