import 'package:archive/archive.dart';
import 'package:docx_template/docx_template.dart';
import 'package:docx_template/src/view_manager.dart';
import 'package:flutter/src/painting/text_style.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:xml/xml.dart';

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

class DocxTemplate {
  DocxTemplate._();
  late DocxManager _manager;
  late double linePitch = 1;
  double ratio = 28.35;
  double ratioText = 2.3;

  ///
  /// Load Template from byte buffer of docx file
  ///
  static Future<DocxTemplate> fromBytes(List<int> bytes) async {
    final component = DocxTemplate._();
    final arch = ZipDecoder().decodeBytes(bytes);

    component._manager = DocxManager(arch);

    return component;
  }

  Future<pw.Document> exportPdf() async {
    final pdf = pw.Document();
    final pdfPageFormat = await getPageFormat();
    pdf.addPage(
      pw.Page(
        pageFormat: pdfPageFormat,
        build: (pw.Context context) => generateBody(),
      ),
    );
    return pdf;
  }

  pw.Widget generateBody() {
    List<pw.Widget> listeWidget = [];
    final vm = ViewManager.attach(_manager, tagPolicy: TagPolicy.saveText);
    final document =
        vm.docxManager.getEntry(() => DocxXmlEntry(), 'word/document.xml')!.doc;
    document!.firstElementChild!.firstElementChild!.childElements
        .forEach((element) {
      if (element.name.local == 'p') {
        pw.TextAlign textAlign = pw.TextAlign.left;
        pw.FontWeight fontWeight = pw.FontWeight.normal;
        TextStyle font = GoogleFonts.inter();
        print(font.fontFamily);

        double fontSize = 11;
        pw.MainAxisAlignment mainAxisAlignement = pw.MainAxisAlignment.start;
        List<pw.Widget> listWidgetRow = [];
        element.childElements.forEach((elementParagraphe) {
          switch (elementParagraphe.name.local) {
            case 'pPr':
              elementParagraphe.childElements.forEach((elementpPr) {
                switch (elementpPr.name.local) {
                  case 'jc':
                    if (elementpPr.attributes.first.name.local == 'val') {
                      if (elementpPr.attributes.first.value == 'center') {
                        textAlign = pw.TextAlign.center;
                        mainAxisAlignement = pw.MainAxisAlignment.center;
                      }
                    }
                    break;
                  case 'rPr':
                    elementpPr.childElements.forEach((elementrPr) {
                      switch (elementrPr.name.local) {
                        case 'b':
                          fontWeight = pw.FontWeight.bold;
                          break;
                        case 'sz':
                          if (elementrPr.attributes.first.name.local == 'val') {
                            fontSize = double.parse(
                                    elementrPr.attributes.first.value) /
                                ratioText;
                          }
                          break;
                      }
                    });
                    break;
                }
              });
              break;
            case 'r':
              elementParagraphe.childElements.forEach((elementR) {
                switch (elementR.name.local) {
                  case 't':
                    if (listWidgetRow.length > 0) {
                      if (listWidgetRow.last.runtimeType == pw.Text) {
                        listWidgetRow.last = pw.Text(
                          (listWidgetRow.last as pw.Text).text.toPlainText() +
                              elementR.children.first.text,
                          style: pw.TextStyle(
                            fontWeight: fontWeight,
                            fontSize: fontSize,
                            font: pw.Font.times(),
                          ),
                        );
                        break;
                      }
                    }
                    print(fontSize);
                    listWidgetRow.add(
                      pw.Text(
                        elementR.children.first.text,
                        textAlign: textAlign,
                        style: pw.TextStyle(
                          fontWeight: fontWeight,
                          fontSize: fontSize,
                          font: pw.Font.times(),
                        ),
                      ),
                    );

                    break;
                }
              });

              break;
          }
        });
        listeWidget.add(
          pw.Row(
            mainAxisAlignment: mainAxisAlignement,
            children: listWidgetRow,
          ),
        );
        listeWidget.add(
          pw.SizedBox(height: linePitch),
        );
      }
    });

    return pw.Column(children: listeWidget);
  }

  Future<PdfPageFormat> getPageFormat() async {
    double width = 1;
    double height = 1;
    double paddingTop = 1;
    double paddingBottom = 1;
    double paddingLeft = 1;
    double paddingRight = 1;
    double headerHeight = 1;
    double footerHeight = 1;

    XmlNode sectPr = readSection(section: 'sectPr');
    for (var element in sectPr.childElements) {
      switch (element.name.local) {
        case 'pgSz':
          width = double.parse(element.attributes.first.value) / ratio;
          height = double.parse(element.attributes[1].value) / ratio;
          break;
        case 'pgMar':
          element.attributes.forEach((p0) {
            switch (p0.name.local) {
              case 'top':
                paddingTop = double.parse(p0.value) / ratio;
                break;
              case 'right':
                paddingRight = double.parse(p0.value) / ratio;
                break;
              case 'bottom':
                paddingBottom = double.parse(p0.value) / ratio;
                break;
              case 'left':
                paddingLeft = double.parse(p0.value) / ratio;
                break;
              case 'header':
                headerHeight = double.parse(p0.value) / ratio;
                break;
              case 'footer':
                footerHeight = double.parse(p0.value) / ratio;
                break;
            }
          });
          break;
        case 'docGrid':
          linePitch = double.parse(element.attributes.first.value) / ratio;
          break;
      }
    }

    return PdfPageFormat(
      width.round().toDouble(),
      height.round().toDouble(),
      marginTop: paddingTop.round().toDouble(),
      marginBottom: paddingBottom.round().toDouble(),
      marginLeft: paddingLeft.round().toDouble(),
      marginRight: paddingRight.round().toDouble(),
    );
  }

  XmlNode readSection({required String section}) {
    final vm = ViewManager.attach(_manager, tagPolicy: TagPolicy.saveText);
    final document =
        vm.docxManager.getEntry(() => DocxXmlEntry(), 'word/document.xml')!.doc;

    final sectPr = document!.children[2].firstChild!.children
        .where((element) => (element as XmlElement).name.local == section)
        .first;
    return sectPr;
  }

  ///
  ///Get all tags from template
  ///
  List<String> getTags() {
    final viewManager = ViewManager.attach(
      _manager,
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
      {TagPolicy tagPolicy = TagPolicy.saveText}) async {
    final vm = ViewManager.attach(_manager, tagPolicy: tagPolicy);
    vm.produce(c);
    _manager.updateArch();
    final enc = ZipEncoder();

    return enc.encode(_manager.arch);
  }
}
