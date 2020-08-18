import 'dart:io';

import 'package:docx_template/src/template.dart';
import 'package:docx_template/src/model.dart';

///
/// Read file template.docx, produce it and save as
///
void main() async {
  final f = File("template.docx");
  final docx = await DocxTemplate.fromBytes(await f.readAsBytes());

  Content c = Content();
  c
    ..add(TextContent("docname", "Simple docname"))
    ..add(TextContent("passport", "passport 1234 432134"))
    ..add(TableContent("table", [
      RowContent()
        ..add(TextContent("key1", "Paul"))
        ..add(TextContent("key2", "Viberg")),
      RowContent()
        ..add(TextContent("key1", "Wiktor"))
        ..add(TextContent("key2", "Wojtas"))
        ..add(ListContent("tablelist",
            [TextContent("value", "b"), TextContent("value", "c")]))
    ]))
    ..add(ListContent("list", [
      TextContent("value", "b")
        ..add(ListContent("listnested",
            [TextContent("value", "aaaaa"), TextContent("value", "bbbb")])),
      TextContent("value", "b"),
      TextContent("value", "c")
    ]))
    ..add(ListContent("plainlist", [
      PlainContent("plainview")..add(c["table"]),
      PlainContent("plainview")..add(c["table"])
    ]));

  await docx.generate(c);
}
