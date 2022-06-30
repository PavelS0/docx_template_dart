part of docx_view;

class SdtView {
  final SdtView? parent;

  final String tag;
  final String name;
  final XmlElement content;
  final XmlElement sdt;
  final XmlAttribute _idVal;

  final List<SdtView> childs;

  set id(int n) {
    _idVal.value = n.toString();
  }

  SdtView(this.tag, this.name, this.content, this.sdt, this._idVal,
      [this.parent, this.childs = const []]);

  static XmlElement? firstChild(XmlElement e, String name) {
    return e.children.firstWhereOrNull(
        (test) => test is XmlElement && test.name.local == name) as XmlElement?;
  }

  static void _addNextSdt(XmlElement e, SdtView parent) {
    for (var c in e.children) {
      if (c is XmlElement) {
        if (c.name.local == "sdt") {
          var sdtV = SdtView.parse(c, parent);
          if (sdtV != null) {
            parent.childs.add(sdtV);
            _addNextSdt(sdtV.content, sdtV);
          }
        } else {
          _addNextSdt(c, parent);
        }
      }
    }
  }

  static void traverseTree(
      SdtView tree, void Function(SdtView v, SdtView? parent) visit) {
    for (var e in tree.childs) {
      visit(e, e.parent);
      traverseTree(e, visit);
    }
  }

  static SdtView getTree(XmlElement root) {
    final rootSdt = SdtView(
        'root',
        'root',
        XmlElement(XmlName('root')),
        XmlElement(XmlName('root')),
        XmlAttribute(XmlName('root'), ''),
        null, []);

    _addNextSdt(root, rootSdt);
    return rootSdt;
  }

  static SdtView? parse(XmlElement e, [SdtView? parent]) {
    if (e.name.local == "sdt") {
      final sdt = e;
      final sdtPr = firstChild(sdt, "sdtPr");
      if (sdtPr != null) {
        final alias = firstChild(sdtPr, "alias");
        final tag = firstChild(sdtPr, "tag");
        final id = firstChild(sdtPr, "id");
        if (alias != null && tag != null && id != null) {
          final idVal = View._findAttr(id, "val");

          final content = firstChild(sdt, "sdtContent");
          if (content != null) {
            final aliasAttr = View._findAttr(alias, "val");
            final tagAttr = View._findAttr(tag, "val");
            if (aliasAttr != null && tagAttr != null && idVal != null) {
              return SdtView(tagAttr.value, aliasAttr.value, content, sdt,
                  idVal, parent, []);
            }
          }
        }
      }
    }
    return null;
  }
}
