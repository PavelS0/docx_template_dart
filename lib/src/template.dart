import 'package:archive/archive.dart';
import 'package:docx_template/docx_template.dart';
import 'package:docx_template/src/view_manager.dart';
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
  double ratioText = 2.5;

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
        pw.FontStyle fontStyle = pw.FontStyle.normal;
        pw.Font font = pw.Font.helvetica();
        pw.TextDecoration textDecoration = pw.TextDecoration.none;
        PdfColor color = PdfColor.fromHex('#00000000');
        pw.TextDecorationStyle textDecorationStyle =
            pw.TextDecorationStyle.solid;

        double fontSize = 11;
        bool option = false;
        pw.MainAxisAlignment mainAxisAlignement = pw.MainAxisAlignment.start;
        List<pw.Widget> listWidgetRow = [];

        element.childElements.forEach((elementParagraphe) {
          switch (elementParagraphe.name.local) {
            case 'pPr':
              elementParagraphe.childElements.forEach((elementpPr) {
                switch (elementpPr.name.local) {
                  case 'jc':
                    if (elementpPr.attributes.first.name.local == 'val') {
                      switch (elementpPr.attributes.first.value) {
                        case 'center':
                          textAlign = pw.TextAlign.center;
                          mainAxisAlignement = pw.MainAxisAlignment.center;
                          break;
                        case 'left':
                          textAlign = pw.TextAlign.left;
                          mainAxisAlignement = pw.MainAxisAlignment.start;
                          break;
                        case 'right':
                          textAlign = pw.TextAlign.right;
                          mainAxisAlignement = pw.MainAxisAlignment.end;
                          break;
                      }
                    }
                    break;
                  case 'numPr':
                    option = true;
                    break;
                  case 'rPr':
                    elementpPr.childElements.forEach((elementrPr) {
                      switch (elementrPr.name.local) {
                        case 'b':
                          fontWeight = pw.FontWeight.bold;
                          break;
                        case 'i':
                          fontStyle = pw.FontStyle.italic;
                          break;
                        case 'color':
                          if (elementrPr.attributes.first.name.local == 'val') {
                            color = PdfColor.fromHex(
                                '#${elementrPr.attributes.first.value}');
                          }

                          break;
                        case 'u':
                          if (elementrPr.attributes.first.name.local == 'val') {
                            switch (elementrPr.attributes.first.value) {
                              case 'single':
                                textDecoration = pw.TextDecoration.underline;
                                textDecorationStyle =
                                    pw.TextDecorationStyle.solid;
                                break;
                              case 'double':
                                textDecoration = pw.TextDecoration.underline;
                                textDecorationStyle =
                                    pw.TextDecorationStyle.double;
                                break;
                            }
                          }
                          break;
                        case 'rFonts':
                          font = matchFont(
                            fontText: elementrPr.attributes.first.value,
                          );
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
                createRow(
                  option: option,
                  elementR: elementR,
                  listWidgetRow: listWidgetRow,
                  color: color,
                  fontSize: fontSize,
                  font: font,
                  textDecoration: textDecoration,
                  textDecorationStyle: textDecorationStyle,
                  textAlign: textAlign,
                  fontWeight: fontWeight,
                  fontStyle: fontStyle,
                );
              });
              break;
            case 'text':
              elementParagraphe.childElements.forEach((elementSdt) {
                switch (elementSdt.name.local) {
                  case 'r':
                    elementSdt.childElements.forEach((elementRSdt) {
                      createRow(
                        option: option,
                        elementR: elementRSdt,
                        listWidgetRow: listWidgetRow,
                        color: color,
                        fontSize: fontSize,
                        font: font,
                        textDecoration: textDecoration,
                        textDecorationStyle: textDecorationStyle,
                        textAlign: textAlign,
                        fontWeight: fontWeight,
                        fontStyle: fontStyle,
                      );
                    });
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

  pw.Font matchFontStyle({
    required pw.Font font,
    required pw.FontWeight fontWeight,
    required pw.FontStyle fontStyle,
  }) {
    switch (font.fontName) {
      case 'Times-Roman':
        if (fontWeight == pw.FontWeight.bold &&
            fontStyle == pw.FontStyle.italic) {
          return pw.Font.timesBoldItalic();
        }
        if (fontWeight == pw.FontWeight.bold) {
          return pw.Font.timesBold();
        }
        if (fontStyle == pw.FontStyle.italic) {
          return pw.Font.timesItalic();
        }
        return pw.Font.times();
      case 'Courier':
        if (fontWeight == pw.FontWeight.bold &&
            fontStyle == pw.FontStyle.italic) {
          return pw.Font.courierBoldOblique();
        }
        if (fontWeight == pw.FontWeight.bold) {
          return pw.Font.courierBold();
        }
        if (fontStyle == pw.FontStyle.italic) {
          return pw.Font.courierOblique();
        }
        return pw.Font.courier();
    }
    if (fontWeight == pw.FontWeight.bold && fontStyle == pw.FontStyle.italic) {
      return pw.Font.helveticaBoldOblique();
    }
    if (fontWeight == pw.FontWeight.bold) {
      return pw.Font.helveticaBold();
    }
    if (fontStyle == pw.FontStyle.italic) {
      return pw.Font.helveticaOblique();
    }
    return pw.Font.helvetica();
  }

  pw.Font matchFont({
    required String fontText,
  }) {
    switch (fontText) {
      case 'Times New Roman':
        return pw.Font.times();
      case 'Courier New':
        return pw.Font.courier();
    }
    return pw.Font.helvetica();
  }

  void createRow({
    required XmlElement elementR,
    required List<pw.Widget> listWidgetRow,
    required PdfColor color,
    required double fontSize,
    required pw.Font font,
    required pw.TextDecoration textDecoration,
    required pw.TextDecorationStyle textDecorationStyle,
    required pw.TextAlign textAlign,
    required pw.FontWeight fontWeight,
    required pw.FontStyle fontStyle,
    required bool option,
  }) {
    switch (elementR.name.local) {
      case 't':
        if (listWidgetRow.length > 0) {
          if (listWidgetRow.last.runtimeType == pw.Expanded) {
            listWidgetRow.last = pw.Expanded(
              child: pw.Text(
                ((listWidgetRow.last as pw.Expanded).child as pw.Text)
                        .text
                        .toPlainText() +
                    elementR.text,
                textAlign: textAlign,
                style: pw.TextStyle(
                  color: color,
                  fontSize: fontSize,
                  font: matchFontStyle(
                    font: font,
                    fontWeight: fontWeight,
                    fontStyle: fontStyle,
                  ),
                  decoration: textDecoration,
                  decorationStyle: textDecorationStyle,
                ),
              ),
            );
            break;
          }
        }
        listWidgetRow.add(
          option == true
              ? pw.Expanded(
                  child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.start,
                      children: [
                        pw.Container(
                          width: fontSize / 3,
                          height: fontSize / 3,
                          decoration: pw.BoxDecoration(
                            color: color,
                            borderRadius: pw.BorderRadius.all(
                              pw.Radius.circular(fontSize / 6),
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 5),
                        pw.Text(
                          elementR.children.first.text,
                          textAlign: textAlign,
                          style: pw.TextStyle(
                            color: color,
                            fontSize: fontSize,
                            font: matchFontStyle(
                              font: font,
                              fontWeight: fontWeight,
                              fontStyle: fontStyle,
                            ),
                            decoration: textDecoration,
                            decorationStyle: textDecorationStyle,
                          ),
                        ),
                      ]),
                )
              : pw.Expanded(
                  child: pw.Text(
                    elementR.children.first.text,
                    textAlign: textAlign,
                    style: pw.TextStyle(
                      color: color,
                      fontSize: fontSize,
                      font: matchFontStyle(
                        font: font,
                        fontWeight: fontWeight,
                        fontStyle: fontStyle,
                      ),
                      decoration: textDecoration,
                      decorationStyle: textDecorationStyle,
                    ),
                  ),
                ),
        );

        break;
      case 'rPr':
        elementR.childElements.forEach((elementSdtPr) {
          switch (elementSdtPr.name.local) {
            case 'b':
              fontWeight = pw.FontWeight.bold;
              break;
            case 'i':
              fontStyle = pw.FontStyle.italic;
              break;
            case 'color':
              if (elementSdtPr.attributes.first.name.local == 'val') {
                color =
                    PdfColor.fromHex('#${elementSdtPr.attributes.first.value}');
              }

              break;
            case 'u':
              if (elementSdtPr.attributes.first.name.local == 'val') {
                switch (elementSdtPr.attributes.first.value) {
                  case 'single':
                    textDecoration = pw.TextDecoration.underline;
                    textDecorationStyle = pw.TextDecorationStyle.solid;
                    break;
                  case 'double':
                    textDecoration = pw.TextDecoration.underline;
                    textDecorationStyle = pw.TextDecorationStyle.double;
                    break;
                }
              }
              break;
            case 'rFonts':
              font = matchFont(
                fontText: elementSdtPr.attributes.first.value,
              );
              break;
            case 'sz':
              if (elementSdtPr.attributes.first.name.local == 'val') {
                fontSize = double.parse(elementSdtPr.attributes.first.value) /
                    ratioText;
              }
              break;
          }
        });
        break;
    }
  }
}
