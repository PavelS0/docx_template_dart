part of docx_view;

class _Num {
  int id;
  int abstractId;
  _Num(this.id, this.abstractId);
}

class Numbering {
  Numbering._(this.entry, this._doc);

  final DocxEntry entry;
  final XmlDocument _doc;

  bool _modified = false;

  Map<String, _Num> _map = {};
  int _maxId = 0;
  int _maxAbstractId = 0;

  static Numbering? from(DocxManager manager) {
    final DocxXmlEntry? xml =
        manager.getEntry(() => DocxXmlEntry(), 'word/numbering.xml');
    if (xml != null && xml.doc != null) {
      final component = Numbering._(xml, xml.doc!);
      _fillNumMap(component, xml.doc!.rootElement);
      return component;
    } else {
      return null;
    }
  }

  bool get isModifed => _modified;

  static void _fillNumMap(Numbering component, XmlElement doc) {
    final map = <String, _Num>{};
    int maxId = 0;
    int maxAbstractId = 0;
    for (var c in doc.children) {
      if (c is XmlElement && c.name.local == 'num') {
        final aIdElem = c.children.firstWhere((node) =>
                node is XmlElement && node.name.local == 'abstractNumId')
            as XmlElement;

        final numIdStr = c.getAttribute('numId', namespace: '*')!;
        final aNumIdStr = aIdElem.getAttribute('val', namespace: '*')!;
        final n = _Num(int.parse(numIdStr), int.parse(aNumIdStr));
        map[numIdStr] = n;

        if (maxId < n.id) {
          maxId = n.id;
        }
        if (maxAbstractId < n.abstractId) {
          maxAbstractId = n.abstractId;
        }
      }
    }

    component._map = map;
    component._maxId = maxId;
    component._maxAbstractId = maxAbstractId;
  }

  XmlElement? _findAbstractNumNode(XmlElement src, int? id) {
    final idStr = id.toString();
    final it = src.children.iterator;
    var found = false;
    while (it.moveNext() && !found) {
      final n = it.current;
      if (n is XmlElement && n.name.local == 'abstractNum') {
        final attr = n.attributes
            .firstWhereOrNull((a) => a.name.local == 'abstractNumId');
        found = attr != null && attr.value == idStr;
      }
    }
    if (found) {
      return it.current as XmlElement?;
    } else {
      return null;
    }
  }

  void _changeAbstractNumNodeId(XmlElement abstractNode, int? id) {
    final attr = abstractNode.attributes
        .firstWhere((a) => a.name.local == 'abstractNumId');
    abstractNode.attributes.remove(attr);
    abstractNode.attributes
        .add(XmlAttribute(XmlName('abstractNumId', 'w'), id.toString()));
  }

  void _findAndRemoveNsid(XmlElement abstractNode) {
    final nsid = abstractNode.children
        .firstWhere((n) => n is XmlElement && n.name.local == 'nsid');
    abstractNode.children.remove(nsid);
  }

  XmlElement createNumNode(_Num n) {
    return XmlElement(XmlName('num', 'w'), [
      XmlAttribute(XmlName('numId', 'w'), n.id.toString())
    ], [
      XmlElement(XmlName('abstractNumId', 'w'),
          [XmlAttribute(XmlName('val', 'w'), n.abstractId.toString())])
    ]);
  }

  String copy(String id) {
    if (_map.containsKey(id)) {
      final oldNum = _map[id]!;
      _maxId++;
      _maxAbstractId++;

      final newNum = _Num(_maxId, _maxAbstractId);
      _map[newNum.id.toString()] = newNum;

      final numNode = createNumNode(newNum);
      _doc.rootElement.children.add(numNode);

      final abstractNumNode =
          _findAbstractNumNode(_doc.rootElement, oldNum.abstractId)!;

      final abstractNumNodeCopy =
          XmlCopyVisitor().visitElement(abstractNumNode);
      _changeAbstractNumNodeId(abstractNumNodeCopy!, newNum.abstractId);
      _findAndRemoveNsid(abstractNumNodeCopy);
      _doc.rootElement.children.insert(0, abstractNumNodeCopy);

      _modified = true;

      return newNum.id.toString();
    } else {
      return '';
    }
  }
}
