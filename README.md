# docx_template_dart
A Docx template engine

Generates docx from template file.

In order to use the library, you need to learn how to insert and edit content control tags in Microsoft Word.
LibreOffice and other office programs are not supported because they do not have a content control tag system.

To do this, go to the project repository and download the template file [template.docx](https://github.com/PavelS0/docx_template_dart/blob/master/template.docx)

Then open the file in Microsoft Word, go to the program settings and enable Developer mode. You may need to restart the program. After that, the developer tab will be available.

In order to make the tags visible, you need to enable "design mode" on the developer tab, to view and edit the tag parameters, you need select tag, then click "properties" button on developer tab.

To create a tag, you need to use the "Aa" buttons on the developer tab, clicking on the button will open a window where:
the TAG field can be one from the following list: list, table, text, plain, img
the TITLE field is the name of the tag, which will be passed to constructors of the Content classes

For example:
If we set the tag equal to 'list' and the title equal to 'cars', then we must use the corresponding 
```ListContent ('cars', [*here contents*])```

For the 'text' tag and the title equal to 'block_name' we use:
```TextContent('block_name', 'Example text')```
etc.


List of supported tags:
+ list - a list, which can contain the following tags: text, plain
+ table - table row
+ text - a simple text field
+ plain - a block that can contain text, tables, images, lists, which can be repeated several times if you wrap it in a list tag
+ img - block with a picture, can be used in text or inside tables



# Example

```
  final f = File("template.docx");
  final docx = await DocxTemplate.fromBytes(await f.readAsBytes());

  /* 
    Or in the case of Flutter, you can use rootBundle.load, then get bytes
    
    final data = await rootBundle.load('lib/assets/users.docx');
    final bytes = data.buffer.asUint8List();

    final docx = await DocxTemplate.fromBytes(bytes);
  */

  // Load test image for inserting in docx
  final testFileContent = await File('test.jpg').readAsBytes();

  final listNormal = ['Foo', 'Bar', 'Baz'];
  final listBold = ['ooF', 'raB', 'zaB'];

  final contentList = <Content>[];

  final b = listBold.iterator;
  for (var n in listNormal) {
    b.moveNext();

    final c = PlainContent("value")
      ..add(TextContent("normal", n))
      ..add(TextContent("bold", b.current));
    contentList.add(c);
  }

  Content c = Content();
  c
    ..add(TextContent("docname", "Simple docname"))
    ..add(TextContent("passport", "Passport NE0323 4456673"))
    ..add(TableContent("table", [
      RowContent()
        ..add(TextContent("key1", "Paul"))
        ..add(TextContent("key2", "Viberg"))
        ..add(TextContent("key3", "Engineer"))
        ..add(ImageContent('img', testFileContent)),
      RowContent()
        ..add(TextContent("key1", "Alex"))
        ..add(TextContent("key2", "Houser"))
        ..add(TextContent("key3", "CEO & Founder"))
        ..add(ListContent("tablelist", [
          TextContent("value", "Mercedes-Benz C-Class S205"),
          TextContent("value", "Lexus LX 570")
        ]))
        ..add(ImageContent('img', testFileContent))
    ]))
    ..add(ListContent("list", [
      TextContent("value", "Engine")
        ..add(ListContent("listnested", contentList)),
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
    ]))
    ..add(ListContent("multilineList", [
      PlainContent("multilinePlain")
        ..add(TextContent('multilineText', 'line 1')),
      PlainContent("multilinePlain")
        ..add(TextContent('multilineText', 'line 2')),
      PlainContent("multilinePlain")
        ..add(TextContent('multilineText', 'line 3'))
    ]))
    ..add(TextContent('multilineText2', 'line 1\nline 2\n line 3'))
    ..add(ImageContent('img', testFileContent));

  final d = await docx.generate(c);
  final of = File('generated.docx');
  if (d != null) await of.writeAsBytes(d);
```

DocxTemplate.generate takes two additional parameters:
1) tagPolicy set rules to remove content control tags from the document
2) imagePolicy
Where ImagePolicy.remove - deletes the image if the ImageContent object is not provided
ImagePolicy.save - leaves the original images from the template if the ImageContent object is not specified