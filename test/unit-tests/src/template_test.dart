import 'dart:io';

import 'package:docx_template/docx_template.dart';
import 'package:test/test.dart';

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

  // test('generate pdf', () async {
  //   final f = File("template.docx");
  //   final docx = await DocxTemplate.fromBytes(await f.readAsBytes());
  //   final list = docx.exportPdf();
  // });
}
