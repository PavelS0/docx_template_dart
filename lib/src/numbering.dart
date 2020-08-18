import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import 'docx_entry.dart';

class Numbering {
  Numbering._(this.arch, this.entry, this.doc);
  final Archive arch;
  final DocxEntry entry;
  final XmlDocument doc;

  bool _modified = false;

  factory Numbering.from(Archive arch) {
    final entry = DocxEntry.fromArchive(arch, 'word/numbering.xml');
    if (entry == null) {
      throw FormatException('Docx have unsupported format');
    }
    final doc = parse(entry.data);

    final component = Numbering._(arch, entry, doc);
    return component;
  }

  String copy(String id) {
    //doc.findAllElements(name)
    String out = doc.toXmlString(pretty: false);

    _modified = true;
    return '45';
  }

  flushToArchive() {
    if (_modified) {
      String out = doc.toXmlString(pretty: false);
      DocxEntry.updateArchive(arch, entry, out);
    }
  }
}
