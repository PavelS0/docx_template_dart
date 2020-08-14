import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:xml/xml.dart';
import 'model.dart';
import 'visitor.dart';
import 'view.dart';

class _DocxEntry {
  _DocxEntry._(this.arch, this.name, this.index, this.data);
  final Archive arch;
  final String name;
  final int index;
  final String data;

  static _DocxEntry fromArchive(Archive arch, int fileIndex) {
    final f = arch.files[fileIndex];
    final bytes = f.content as List<int>;
    final data = utf8.decode(bytes);
    final e = _DocxEntry._(arch, f.name, fileIndex, data);
    return e;
  }

  static updateArchive(Archive arch, _DocxEntry entry, String data) {
    List<int> out = utf8.encode(data);
    arch.files[entry.index] = ArchiveFile(
        entry.name, out.length, out, arch.files[entry.index].compressionType);
  }
}

class DocxTemplate {
  DocxTemplate._() {}

  XmlCopyVisitor visitor = XmlCopyVisitor();
  Archive _arch;
  _DocxEntry _documentEntry;

  ///
  /// Load Template from byte buffer of docx file
  ///
  static Future<DocxTemplate> fromBytes(List<int> bytes) async {
    final component = DocxTemplate._();
    final arch = ZipDecoder().decodeBytes(bytes);

    final di =
        arch.files.indexWhere((element) => element.name == 'word/document.xml');
    if (di >= 0) {
      component._documentEntry = _DocxEntry.fromArchive(arch, di);
    } else {
      throw FormatException('Docx have unsupported format');
    }

    component._arch = arch;
    return component;
  }

  ///
  /// Generates byte buffer with docx file content by given [c]
  ///
  Future<List<int>> generate(Content c) async {
    XmlDocument doc = parse(_documentEntry.data);
    var v = View.attchToDoc(doc);
    v.produce(c);
    String out = doc.toXmlString(pretty: false);
    _DocxEntry.updateArchive(_arch, _documentEntry, out);

    final enc = ZipEncoder();
    return enc.encode(_arch);
  }
}
