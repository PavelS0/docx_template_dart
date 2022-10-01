import 'dart:io';

import 'package:docx_template/docx_template.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart';

void main() {
  test('getTags', () async {
    final f = File("template.docx");
    final docx = await DocxTemplate.fromBytes(await f.readAsBytes());
    final list = docx.getTags();
    expect(list.length, 8);
    expect(list.first, 'docname');
    expect(list[1], 'list');
    expect(list[2], 'table');
    expect(list[3], 'passport');
    expect(list[4], 'plainlist');
    expect(list[5], 'multilineList');
    expect(list[6], 'multilineText2');
    expect(list[7], 'img');
  });

  test('getPageFormat', () async {
    final f = File("doc_test.docx");
    final docx = await DocxTemplate.fromBytes(await f.readAsBytes());
    final pdfFormatPage = await docx.getPageFormat();
    expect(
      pdfFormatPage,
      PdfPageFormat(
        420,
        594,
        marginTop: 30,
        marginRight: 30,
        marginLeft: 40,
        marginBottom: 25,
      ),
    );
  });
  test('generate body', () async {
    final f = File("doc_test.docx");
    final docx = await DocxTemplate.fromBytes(await f.readAsBytes());
    final body = docx.generateBody();
  });

  test('export pdf', () async {
    final f = File("doc_test.docx");
    final docx = await DocxTemplate.fromBytes(await f.readAsBytes());
    final pdf = await docx.exportPdf();
    final file = File("example.pdf");
    await file.writeAsBytes(await pdf.save());
  });

  test('match font', () async {
    final f = File("doc_test.docx");
    final docx = await DocxTemplate.fromBytes(await f.readAsBytes());
    expect(
      docx
          .matchFont(
            fontText: 'Times New Roman',
          )
          .fontName,
      Font.times().fontName,
    );
    expect(
      docx
          .matchFont(
            fontText: 'Courier New',
          )
          .fontName,
      Font.courier().fontName,
    );
    expect(
      docx
          .matchFont(
            fontText: 'C',
          )
          .fontName,
      Font.helvetica().fontName,
    );
  });
}
