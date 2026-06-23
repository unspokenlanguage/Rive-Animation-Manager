// lib/src/helpers/io_stub.dart
import 'dart:typed_data';

/// A stub class for dart:io File to allow web compilation.
/// On the web, local file paths are not supported, so this safely mocks the API.
class File {
  final String path;
  
  File(this.path);
  
  Future<bool> exists() async => false;
  
  Future<Uint8List> readAsBytes() async {
    throw UnsupportedError('File operations are not supported on the web platform.');
  }
}
