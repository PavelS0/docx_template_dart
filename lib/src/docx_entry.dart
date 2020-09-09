import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

class DocxEntry {
  DocxEntry._(this.arch, this.name, this.index, this.doc);
  final Archive arch;
  final String name;
  final int index;
  final XmlDocument doc;

  static DocxEntry fromArchive(Archive arch, String entryName) {
    final ei = arch.files.indexWhere((element) => element.name == entryName);
    if (ei == null) {
      return null;
    }
    final f = arch.files[ei];
    final bytes = f.content as List<int>;
    final data = utf8.decode(bytes);
    final doc = XmlDocument.parse(data);
    final e = DocxEntry._(arch, f.name, ei, doc);
    return e;
  }

  static updateArchive(Archive arch, DocxEntry entry) {
    final data = entry.doc.toXmlString(pretty: false);
    List<int> out = utf8.encode(data);
    arch.files[entry.index] = ArchiveFile(
        entry.name, out.length, out, arch.files[entry.index].compressionType);
  }
}
