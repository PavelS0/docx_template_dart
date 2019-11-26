import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:xml/xml.dart';
import 'dart:io';
import 'model.dart';
import 'visitor.dart';
import 'view.dart';

class DocxTemplate {
  XmlCopyVisitor visitor = XmlCopyVisitor();

  DocxTemplate();
  File f;
  List<int> compBytes;
  File template;

  void load (String path) {
    f = File(path);
    if (f.existsSync()){
      compBytes = f.readAsBytesSync();
      Archive archive = ZipDecoder().decodeBytes(compBytes);
      for (ArchiveFile file in archive) {
        String filename = file.name;
        if (file.isFile) {
          List<int> data = file.content;
          File('docx_cache/' + filename)
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        } else {
          Directory('docx_cache/' + filename)
            ..create(recursive: true);
        }
      }
    } else {
      print("File not found");
    }
  }
  void generate(Content c) {
    template =  File('docx_cache/word/document.xml');
    if (template.existsSync()) {
      XmlDocument doc = parse(template.readAsStringSync());
      var v = View.attchToDoc(doc);
      v.produce(c);

      String ermak = doc.toXmlString(pretty: true);
      template.writeAsStringSync(ermak);
    }
  }

  void save() {
    var encoder = ZipFileEncoder();
    encoder.zipDirectory(Directory('docx_cache'), filename: 'new.docx');
  }

  List<int> saveAsBytes() {
    Archive a = createArchiveFromDirectory(Directory("docx_cache"), includeDirName: false);
    return ZipEncoder().encode(a);
  }

  static List<Content> fromMap(Map<String, dynamic> map){
    List<Content> l = List();
    map.forEach((k, v){
      if (v is Map) {
        
      } else if (v is List) {

      } else {
        l.add(TextContent(k, v.toString()));
      }
    });
    return l;
  }
}