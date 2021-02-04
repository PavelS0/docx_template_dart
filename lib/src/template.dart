import 'package:archive/archive.dart';
import 'package:docx_template/src/model.dart';
import 'package:docx_template/src/view_manager.dart';
import 'docx_entry.dart';

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
  Future<List<int>> generate(Content c) async {
    final vm = ViewManager.attach(_manager);
    vm.produce(c);
    _manager.updateArch();
    final enc = ZipEncoder();
    return enc.encode(_manager.arch);
  }
}
