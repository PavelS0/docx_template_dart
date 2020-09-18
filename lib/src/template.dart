import 'package:archive/archive.dart';
import 'package:docx_template/src/model.dart';
import 'package:docx_template/src/view_manager.dart';
import 'docx_entry.dart';

class DocxTemplate {
  DocxTemplate._();

  Archive _arch;
  DocxEntry _documentEntry;
  DocxEntry _numberingEntry;

  ///
  /// Load Template from byte buffer of docx file
  ///
  static Future<DocxTemplate> fromBytes(List<int> bytes) async {
    final component = DocxTemplate._();
    final arch = ZipDecoder().decodeBytes(bytes);

    final docEntry = DocxEntry.fromArchive(arch, 'word/document.xml');
    final numberingEntry = DocxEntry.fromArchive(arch, 'word/numbering.xml');
    if (docEntry == null) {
      throw FormatException('Docx have unsupported format');
    }

    component._documentEntry = docEntry;
    component._numberingEntry = numberingEntry;
    component._arch = arch;

    return component;
  }

  ///
  /// Generates byte buffer with docx file content by given [c]
  ///
  Future<List<int>> generate(Content c) async {
    final vm = ViewManager.attach(_documentEntry, _numberingEntry, this);
    vm.produce(c);
    DocxEntry.updateArchive(_arch, _documentEntry);
    DocxEntry.updateArchive(_arch, _numberingEntry);

    final enc = ZipEncoder();
    return enc.encode(_arch);
  }
}
