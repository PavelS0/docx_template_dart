part of docx_view;

class _Num {
  int id;
  int abstractId;
}

class Numbering {
  Numbering._(this.entry, this._doc, this._copyVisitor);

  final DocxEntry entry;
  final XmlDocument _doc;
  final XmlCopyVisitor _copyVisitor;

  bool _modified = false;

  Map<String, _Num> _map = {};
  int _maxId;
  int _maxAbstractId;

  factory Numbering.from(DocxEntry entry) {
    final component = Numbering._(entry, entry.doc, XmlCopyVisitor());
    _fillNumMap(component, entry.doc.rootElement);
    return component;
  }

  bool get isModifed => _modified;

  static void _fillNumMap(Numbering component, XmlElement doc) {
    final map = <String, _Num>{};
    var maxId = 0;
    var maxAbstractId = 0;
    for (var c in doc.children) {
      if (c is XmlElement && c.name.local == 'num') {
        final aIdElem = c.children.firstWhere((node) =>
                node is XmlElement && node.name.local == 'abstractNumId')
            as XmlElement;

        if (aIdElem != null) {
          final numIdStr = c.getAttribute('numId', namespace: '*');
          final aNumIdStr = aIdElem.getAttribute('val', namespace: '*');
          final n = _Num();
          n.abstractId = int.parse(aNumIdStr);
          n.id = int.parse(numIdStr);
          map[numIdStr] = n;

          if (maxId < n.id) {
            maxId = n.id;
          }
          if (maxAbstractId < n.abstractId) {
            maxAbstractId = n.abstractId;
          }
        }
      }
    }

    component._map = map;
    component._maxId = maxId;
    component._maxAbstractId = maxAbstractId;
  }

  XmlElement _findAbstractNumNode(XmlElement src, int id) {
    final idStr = id.toString();
    final it = src.children.iterator;
    var found = false;
    while (it.moveNext() && !found) {
      final n = it.current;
      if (n is XmlElement && n.name.local == 'abstractNum') {
        final attr =
            n.attributes.firstWhere((a) => a.name.local == 'abstractNumId');
        found = attr != null && attr.value == idStr;
      }
    }
    if (found) {
      return it.current;
    } else {
      return null;
    }
  }

  void _changeAbstractNumNodeId(XmlElement abstractNode, int id) {
    final attr = abstractNode.attributes
        .firstWhere((a) => a.name.local == 'abstractNumId');
    abstractNode.attributes.remove(attr);
    abstractNode.attributes
        .add(XmlAttribute(XmlName('abstractNumId', 'w'), id.toString()));
  }

  void _findAndRemoveNsid(XmlElement abstractNode) {
    final nsid = abstractNode.children
        .firstWhere((n) => n is XmlElement && n.name.local == 'nsid');
    if (nsid != null) {
      abstractNode.children.remove(nsid);
    }
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
      final oldNum = _map[id];
      _maxId++;
      _maxAbstractId++;

      final newNum = _Num();
      newNum.id = _maxId;
      newNum.abstractId = _maxAbstractId;
      _map[newNum.id.toString()] = newNum;

      final numNode = createNumNode(newNum);
      _doc.rootElement.children.add(numNode);

      final abstractNumNode =
          _findAbstractNumNode(_doc.rootElement, oldNum.abstractId);
      final abstractNumNodeCopy = abstractNumNode.accept(_copyVisitor);
      _changeAbstractNumNodeId(abstractNumNodeCopy, newNum.abstractId);
      _findAndRemoveNsid(abstractNumNodeCopy);
      _doc.rootElement.children.insert(0, abstractNumNodeCopy);

      _modified = true;

      return newNum.id.toString();
    } else {
      return '';
    }
  }
}
