import 'package:archive/archive.dart';
import 'package:docx_template/docx_template.dart';
import 'package:docx_template/src/view_manager.dart';

import 'docx_entry.dart';

class DocxTemplateException implements Exception {
  final String message;

  DocxTemplateException(this.message);

  @override
  String toString() => message;
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

///
/// Image save policy
///
/// [remove] - remove template image from generated document if [ImageContent] is null
///
/// [save] - save template image in generated document if [ImageContent] is null
///
enum ImagePolicy { remove, save }

class DocxTemplate {
  DocxTemplate._();
  late DocxManager _manager;

  ///
  /// Load Template from byte buffer of docx file
  ///
  static Future<DocxTemplate> fromBytes(List<int> bytes) async {
    final component = DocxTemplate._();
    final arch = ZipDecoder().decodeBytes(bytes, verify: true);

    component._manager = DocxManager(arch);

    return component;
  }

//   exportPdf() async {
//     var configuration = Configuration('9849d3fc-3eb2-442a-a085-8d21d92c3ad3',
//         '798d958e76c462d62b41be3d754a9d25');
//     var wordsApi = WordsApi(configuration);
// // Upload file to cloud
//     var localFileContent = await (File('generated.docx').readAsBytes());
//     var uploadRequest = UploadFileRequest(
//         ByteData.view(localFileContent.buffer), 'fileStoredInCloud.docx');
//     await wordsApi.uploadFile(uploadRequest);
//
// // Save file as pdf in cloud
//     var saveOptionsData = PdfSaveOptionsData()
//       ..fileName = 'destStoredInCloud.pdf';
//     var saveAsRequest =
//         SaveAsRequest('fileStoredInCloud.docx', saveOptionsData);
//     await wordsApi.saveAs(saveAsRequest);
//   }

  ///
  ///Get all tags from template
  ///
  List<String> getTags() {
    final viewManager = ViewManager.attach(
      DocxManager(_manager.arch),
    );
    List<String> listTags = [];
    var sub = viewManager.root.sub;
    if (sub != null) {
      for (var key in sub.keys) {
        listTags.add(key);
      }
    }
    return listTags;
  }

  ///
  /// Generates byte buffer with docx file content by given [c]
  ///
  Future<List<int>?> generate(Content c,
      {TagPolicy tagPolicy = TagPolicy.saveText,
      ImagePolicy imagePolicy = ImagePolicy.save}) async {
    final vm = ViewManager.attach(_manager,
        tagPolicy: tagPolicy, imgPolicy: imagePolicy);
    vm.produce(c);
    _manager.updateArch();
    final enc = ZipEncoder();

    return enc.encode(_manager.arch, level: Deflate.DEFAULT_COMPRESSION);
  }
}
