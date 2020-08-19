import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import 'docx_entry.dart';

class _Num {
  int id;
  int abstractId;
}

class Numbering {
  Numbering._(this.arch, this.entry, this.doc);
  final Archive arch;
  final DocxEntry entry;
  final XmlDocument doc;

  bool _modified = false;

  Map<String, _Num> _map = {};
  int _maxId;

  factory Numbering.from(Archive arch) {
    final entry = DocxEntry.fromArchive(arch, 'word/numbering.xml');
    if (entry == null) {
      throw FormatException('Docx have unsupported format');
    }
    final doc = parse(entry.data);

    final component = Numbering._(arch, entry, doc);
    _fillNumMap(component, doc.rootElement);

    return component;
  }

  static void _fillNumMap(Numbering component, XmlElement doc) {
    final map = <String, _Num>{};
    var maxId = 0;
    for (var c in doc.children) {
      if (c is XmlElement && c.name.local == 'num') {
        final aIdElem = c.children.firstWhere(
            (node) => node is XmlElement && node.name.local == 'abstractNumId');

        if (aIdElem != null) {
          final numIdStr = c.getAttribute('numId');
          final aNumIdStr = c.getAttribute('val');
          final n = _Num();
          n.abstractId = int.parse(aNumIdStr);
          n.id = int.parse(numIdStr);
          map[numIdStr] = n;

          if (maxId < n.id) {
            maxId = n.id;
          }
        }
      }
    }

    component._map = map;
    component._maxId = maxId;
  }

  String copy(String id) {
    if (_map.containsKey(id)) {
      final n = _Num();
      n.id = _maxId + 1;
      n.abstractId = _map[id].abstractId;
      _map[n.id.toString()] = n;
      final e = XmlElement(XmlName('num', 'w'), [
        XmlAttribute(XmlName('numId', 'w'), n.id.toString())
      ], [
        XmlElement(XmlName('abstractNumId', 'w'),
            [XmlAttribute(XmlName('val', 'w'), n.abstractId.toString())])
      ]);
      _modified = true;
      doc.rootElement.children.add(e);
      return n.id.toString();
    } else {
      return '';
    }
  }

  flushToArchive() {
    if (_modified) {
      String out = doc.toXmlString(pretty: false);
      DocxEntry.updateArchive(arch, entry, out);
    }
  }
}
