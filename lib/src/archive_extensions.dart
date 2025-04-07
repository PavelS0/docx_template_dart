import 'package:archive/archive.dart';

extension ArchiveExtensions on Archive {
  void updateFileAt(int index, ArchiveFile file) {
    if (index < 0 || index >= this.length) return;
    this[index] = file;
  }
}
