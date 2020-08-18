import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:docx_template/src/model.dart';
import 'package:docx_template/src/numbering.dart';
import 'package:docx_template/src/view_manager.dart';
import 'package:xml/xml.dart';
import 'docx_entry.dart';

class DocxTemplate {
  DocxTemplate._() {}

  XmlCopyVisitor visitor = XmlCopyVisitor();
  Archive _arch;
  DocxEntry _documentEntry;
  Numbering numbering;

  ///
  /// Load Template from byte buffer of docx file
  ///
  static Future<DocxTemplate> fromBytes(List<int> bytes) async {
    final component = DocxTemplate._();
    final arch = ZipDecoder().decodeBytes(bytes);

    final docEntry = DocxEntry.fromArchive(arch, 'word/document.xml');
    if (docEntry == null) {
      throw FormatException('Docx have unsupported format');
    }
    component._documentEntry = docEntry;
    component._arch = arch;
    component.numbering = Numbering.from(arch);
    return component;
  }

  ///
  /// Generates byte buffer with docx file content by given [c]
  ///
  Future<List<int>> generate(Content c) async {
    XmlDocument doc = parse(_documentEntry.data);
    final vm = ViewManager.attach(doc, this);
    vm.produce(c);
    String out = doc.toXmlString(pretty: true);
    DocxEntry.updateArchive(_arch, _documentEntry, out);

    final enc = ZipEncoder();
    return enc.encode(_arch);
  }
}
