/// Cross-platform download helper.
///
/// On **web**: uses dart:html anchor download trick.
/// On **native**: not used (file_picker handles native saves).
library download_helper;

import 'dart:typed_data';

import 'download_helper_stub.dart'
    if (dart.library.html) 'download_helper_web.dart';

/// Triggers a file download. Only functional on web; throws on native.
void triggerWebDownload(String filename, Uint8List bytes) =>
    downloadOnWeb(filename, bytes);
