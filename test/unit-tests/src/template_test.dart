import 'dart:io';

import 'package:docx_template/docx_template.dart';
import 'package:test/test.dart';

void main() {
  test('getTags', () async {
    final f = File("template.docx");
    final docx = await DocxTemplate.fromBytes(await f.readAsBytes());
    final list = docx.getTags();
    // print(list);
    expect(list.length, 12);
    expect(list.first, 'imgFirst');
    expect(list[1], 'docname');
    expect(list[2], 'list');
    expect(list[3], 'table');
    expect(list[4], 'passport');
    expect(list[5], 'plainlist');
    expect(list[6], 'multilineList');
    expect(list[7], 'multilineText2');
    expect(list[8], 'img');
    expect(list[9], 'link');
    expect(list[10], 'header');
    expect(list[11], 'logo');
  });

  // test('generate pdf', () async {
  //   final f = File("template.docx");
  //   final docx = await DocxTemplate.fromBytes(await f.readAsBytes());
  //   final list = docx.exportPdf();
  // });
}
