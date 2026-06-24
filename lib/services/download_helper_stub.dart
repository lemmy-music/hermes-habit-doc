import 'dart:typed_data';

/// Stub implementation for non-web platforms.
/// Native platforms use file_picker for saving files.
void downloadOnWeb(String filename, Uint8List bytes) {
  throw UnsupportedError('Web download is only available on web platform.');
}
