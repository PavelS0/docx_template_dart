import 'package:archive/archive.dart';
import 'package:docx_template/src/model.dart';
import 'package:docx_template/src/view_manager.dart';
import 'docx_entry.dart';

class DocxTemplateException implements Exception {
  final String message;

  DocxTemplateException(this.message);

  @override
  String toString() => this.message;
}

///
/// Sdt tags policy enum
///
/// [removeAll] - remove all sdt tags from document
///
/// [saveNullified] - save ONLY tags where [Content] is null
///
/// [saveText] - save ALL TextContent field (include nullifed [Content])
///
enum TagPolicy { removeAll, saveNullified, saveText }

class DocxTemplate {
  DocxTemplate._();
  DocxManager _manager;

  ///
  /// Load Template from byte buffer of docx file
  ///
  static Future<DocxTemplate> fromBytes(List<int> bytes) async {
    final component = DocxTemplate._();
    final arch = ZipDecoder().decodeBytes(bytes);

    component._manager = DocxManager(arch);

    return component;
  }

  ///
  /// Generates byte buffer with docx file content by given [c]
  ///
  Future<List<int>> generate(Content c,
      {TagPolicy tagPolicy = TagPolicy.saveText}) async {
    final vm = ViewManager.attach(_manager, tagPolicy: tagPolicy);
    vm.produce(c);
    _manager.updateArch();
    final enc = ZipEncoder();
    return enc.encode(_manager.arch);
  }
}
