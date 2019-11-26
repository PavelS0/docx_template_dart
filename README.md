# docx_template_dart
A Docx template engine

Generates docx from template file (see template.docx in repo root) with content controls. Enable developer mode in MS Word to see content controls tags.

'''DocxTemplate docx = DocxTemplate();
  await docx.load(File("template.docx"));
  // Root element
  Content c = Content();
  c..add(TextContent("docname", "Simple docname"))
  ..add(TextContent("passport", "passport 1234 432134"))
  ..add(
    TableContent("table", [
      RowContent()
        ..add(TextContent("key1", "Paul"))
        ..add(TextContent("key2", "Viberg")),
      RowContent()
        ..add(TextContent("key1", "Wiktor"))
        ..add(TextContent("key2", "Wojtas"))
        ..add(ListContent("tablelist", [TextContent("value", "b"), TextContent("value", "c")]))
    ])
  )
  ..add(ListContent("list", [
    TextContent("value", "b")..add(ListContent("listnested", [TextContent("value", "aaaaa"), TextContent("value", "bbbb")])),
    TextContent("value", "b"), 
    TextContent("value", "c")
    ]))
  ..add(ListContent("plainlist", [
    PlainContent("plainview")..add(c["table"]),
    PlainContent("plainview")..add(c["table"])
  ]));
  
  await docx.generate(c);
  await docx.save("generated.docx");'''
