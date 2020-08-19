# docx_template_dart
A Docx template engine

Generates docx from template file (see template.docx in repo root) with content controls. Enable developer mode in MS Word to see content controls tags.

# Example

```
  // or in the case of Flutter, you can use rootBundle.load, then get bytes
  final f = File("template.docx");
  final docx = await DocxTemplate.fromBytes(await f.readAsBytes());

  Content c = Content();
  c
    ..add(TextContent("docname", "Simple docname"))
    ..add(TextContent("passport", "Passport NE0323 4456673"))
    ..add(TableContent("table", [
      RowContent()
        ..add(TextContent("key1", "Paul"))
        ..add(TextContent("key2", "Viberg"))
        ..add(TextContent("key3", "Engineer")),
      RowContent()
        ..add(TextContent("key1", "Alex"))
        ..add(TextContent("key2", "Houser"))
        ..add(TextContent("key3", "CEO & Founder"))
        ..add(ListContent("tablelist", [
          TextContent("value", "Mercedes-Benz C-Class S205"),
          TextContent("value", "Lexus LX 570")
        ]))
    ]))
    ..add(ListContent("list", [
      TextContent("value", "Engine")
        ..add(ListContent("listnested", [
          TextContent("value", "BMW M30"),
          TextContent("value", "2GZ GE")
        ])),
      TextContent("value", "Gearbox"),
      TextContent("value", "Chassis")
    ]))
    ..add(ListContent("plainlist", [
      PlainContent("plainview")
        ..add(TableContent("table", [
          RowContent()
            ..add(TextContent("key1", "Paul"))
            ..add(TextContent("key2", "Viberg"))
            ..add(TextContent("key3", "Engineer")),
          RowContent()
            ..add(TextContent("key1", "Alex"))
            ..add(TextContent("key2", "Houser"))
            ..add(TextContent("key3", "CEO & Founder"))
            ..add(ListContent("tablelist", [
              TextContent("value", "Mercedes-Benz C-Class S205"),
              TextContent("value", "Lexus LX 570")
            ]))
        ])),
      PlainContent("plainview")
        ..add(TableContent("table", [
          RowContent()
            ..add(TextContent("key1", "Nathan"))
            ..add(TextContent("key2", "Anceaux"))
            ..add(TextContent("key3", "Music artist"))
            ..add(ListContent(
                "tablelist", [TextContent("value", "Peugeot 508")])),
          RowContent()
            ..add(TextContent("key1", "Louis"))
            ..add(TextContent("key2", "Houplain"))
            ..add(TextContent("key3", "Music artist"))
            ..add(ListContent("tablelist", [
              TextContent("value", "Range Rover Velar"),
              TextContent("value", "Lada Vesta SW Sport")
            ]))
        ])),
    ]));

  final d = await docx.generate(c);
  final of = File('generated.docx');
  await of.writeAsBytes(d);
```