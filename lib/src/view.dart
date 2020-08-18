part of docx_view;

typedef bool Check(XmlElement n);
typedef void OnFound(XmlElement e);

class SdtView {
  final String tag;
  final String name;
  final XmlElement content;
  final XmlElement sdt;
  SdtView(this.tag, this.name, this.content, this.sdt);
  factory SdtView.parse(XmlElement e) {
    if (e.name.local == "sdt") {
      XmlElement sdt = e;
      XmlElement sdtPr = View._findChild(sdt, "sdtPr");
      if (sdtPr != null) {
        XmlElement alias = View._findChild(sdtPr, "alias");
        XmlElement tag = View._findChild(sdtPr, "tag");
        if (alias != null && tag != null) {
          XmlElement content = View._findChild(sdt, "sdtContent");
          if (content != null) {
            XmlAttribute aliasAttr = View._findAttr(alias, "val");
            XmlAttribute tagAttr = View._findAttr(tag, "val");
            if (aliasAttr != null && tagAttr != null) {
              return SdtView(tagAttr.value, aliasAttr.value, content, sdt);
            }
          }
        }
      }
    }
    return null;
  }
}

class View<T extends Content> extends XmlElement {
  Map<String, List<View>> sub;
  final String tag;

  final ViewManager vm;
  View(this.vm, XmlName name,
      [Iterable<XmlAttribute> attributesIterable = const [],
      Iterable<XmlNode> children = const [],
      bool isSelfClosing = true,
      this.tag])
      : super(name, attributesIterable, children, isSelfClosing);

  View createNew(XmlName name,
      [Iterable<XmlAttribute> attributesIterable = const [],
      Iterable<XmlNode> children = const [],
      bool isSelfClosing = true,
      String tag]) {
    return null;
  }

  static traverse(XmlElement node, Check check, OnFound onFound) {
    if (node.children != null && node.children.isNotEmpty) {
      for (var c in node.children) {
        if (c is XmlElement) {
          if (check(c)) {
            onFound(c);
          } else {
            traverse(c, check, onFound);
          }
        }
      }
    }
  }

  static List<View> subViews(XmlElement e) {
    List<View> views = List();
    traverse(e, (test) => test is View, (e) => views.add(e));
    return views;
  }

  List<XmlElement> produce(T c) {
    return [];
  }

  static void replaceWithAll(
      XmlElement elem, List<XmlElement> to, bool clearParents) {
    if (clearParents) {
      for (XmlElement e in to) {
        if (e.parent != null) {
          e.parent.children.remove(e);
        }
        print(e.parent != null ? 'NOT NULL' : 'NULL');
      }
    }

    if (elem.name.local == 'table') {
      print(elem.name);
    }
    if (elem.parent != null) {
      // Root elem not have parents
      var childs = elem.parent.children;
      var index = childs.indexOf(elem);
      childs.removeAt(index);
      childs.insertAll(index, to);
    }
  }

  static XmlElement _findChild(XmlElement e, String tag) {
    return e.descendants.firstWhere(
        (test) => test is XmlElement && test.name.local == tag,
        orElse: () => null);
  }

  static XmlAttribute _findAttr(XmlElement e, String attr) {
    return e.attributes
        .firstWhere((test) => test.name.local == attr, orElse: () => null);
  }
}

class TextView extends View<TextContent> {
  TextView(ViewManager vm, XmlName name,
      [Iterable<XmlAttribute> attributesIterable = const [],
      Iterable<XmlNode> children = const [],
      bool isSelfClosing = true,
      String tag])
      : super(vm, name, attributesIterable, children, isSelfClosing, tag);
  @override
  List<XmlElement> produce(TextContent c) {
    List<XmlElement> list = [];
    bool textInserted = false;
    for (XmlElement e in this.children) {
      if (e.name.local == 'r') {
        if (!textInserted) {
          if (c != null) _findAndReplaceText(e, c.text);
          list.add(e);
          textInserted = true;
        }
      } else {
        list.add(e);
      }
    }
    return list;
  }

  @override
  TextView createNew(XmlName name,
      [Iterable<XmlAttribute> attributesIterable = const [],
      Iterable<XmlNode> children = const [],
      bool isSelfClosing = true,
      String tag]) {
    return TextView(vm, name, attributesIterable, children, isSelfClosing, tag);
  }

  void _findAndReplaceText(XmlElement from, String text) {
    XmlText t = from.descendants
        .firstWhere((test) => test is XmlText, orElse: () => null);
    if (t != null) {
      t.parent.children[0] = XmlText(text);
    }
  }
}

class PlainView extends View<PlainContent> {
  PlainView(ViewManager vm, XmlName name,
      [Iterable<XmlAttribute> attributesIterable = const [],
      Iterable<XmlNode> children = const [],
      bool isSelfClosing = true,
      String tag])
      : super(vm, name, attributesIterable, children, isSelfClosing, tag);
  @override
  List<XmlElement> produce(PlainContent c) {
    XmlElement copy = this.accept(vm._copyVisitor);
    var views = View.subViews(copy);
    for (var v in views) {
      vm._produceInner(c, v);
    }
    return List.from(copy.children);
  }

  @override
  PlainView createNew(XmlName name,
      [Iterable<XmlAttribute> attributesIterable = const [],
      Iterable<XmlNode> children = const [],
      bool isSelfClosing = true,
      String tag]) {
    return PlainView(
        vm, name, attributesIterable, children, isSelfClosing, tag);
  }
}

class ListView extends View<ListContent> {
  ListView(ViewManager vm, XmlName name,
      [Iterable<XmlAttribute> attributesIterable = const [],
      Iterable<XmlNode> children = const [],
      bool isSelfClosing = true,
      String tag])
      : super(vm, name, attributesIterable, children, isSelfClosing, tag);

  void _changeListId(XmlElement copy) {
    if (copy.children.isNotEmpty) {
      final e = copy.children.first;
      if (e is XmlElement) {
        final elements = e.findElements('numId', namespace: 'w');
        if (elements.isNotEmpty) {
          final e = elements.first;
          final idNode = e.getAttributeNode('val');
          final newId = vm.t.numbering.copy(idNode.value);
          /* e.attributes.remove(idNode);
          e.attributes.add(XmlAttribute(XmlName('val', 'w'), newId)); */
        }
      }
    }
  }

  @override
  List<XmlElement> produce(ListContent c) {
    List<XmlElement> l = [];
    if (c == null) {
      if (vm._viewStack.length >= 2 && vm._viewStack.elementAt(1) is RowView) {
        //

        final doc = parse('''
        <w:p>
          <w:pPr>
            <w:pStyle w:val="TableContents"/>
            <w:rPr>
              <w:lang w:val="en-US"/>
            </w:rPr>
          </w:pPr>
          <w:r>
            <w:rPr>
              <w:lang w:val="en-US"/>
            </w:rPr>
            <w:t></w:t>
          </w:r>
        </w:p>
        ''');

        /* XmlElement copy = this.accept(vm._copyVisitor);
        var views = View.subViews(copy);
        for (var v in views) {
          vm._produceInner(null, v);
        } */
        l = [doc.rootElement];
      }
      /*  */
    } else {
      for (var cont in c.list) {
        XmlElement copy = this.accept(vm._copyVisitor);
        final vs = vm._viewStack;
        if (vs.any((element) => element is PlainView || element is RowView)) {
          _changeListId(copy);
        }

        var views = View.subViews(copy);
        for (var v in views) {
          vm._produceInner(cont, v);
        }
        if (copy.children != null) {
          l.addAll(copy.children.cast<XmlElement>());
        }
      }
    }
    return l;
  }

  @override
  ListView createNew(XmlName name,
      [Iterable<XmlAttribute> attributesIterable = const [],
      Iterable<XmlNode> children = const [],
      bool isSelfClosing = true,
      String tag]) {
    return ListView(vm, name, attributesIterable, children, isSelfClosing, tag);
  }
}

class RowView extends View<TableContent> {
  RowView(ViewManager vm, XmlName name,
      [Iterable<XmlAttribute> attributesIterable = const [],
      Iterable<XmlNode> children = const [],
      bool isSelfClosing = true,
      String tag])
      : super(vm, name, attributesIterable, children, isSelfClosing, tag);

  @override
  List<XmlElement> produce(TableContent c) {
    List<XmlElement> l = [];

    if (c == null) {
      XmlElement copy = this.accept(vm._copyVisitor);
      l = List.from(copy.children);
    } else {
      for (var cont in c.rows) {
        XmlElement copy = this.accept(vm._copyVisitor);
        var views = View.subViews(copy);
        for (var v in views) {
          vm._produceInner(cont, v);
        }
        if (copy.children != null) {
          l.addAll(copy.children.cast<XmlElement>());
        }
      }
    }
    return l;
  }

  @override
  RowView createNew(XmlName name,
      [Iterable<XmlAttribute> attributesIterable = const [],
      Iterable<XmlNode> children = const [],
      bool isSelfClosing = true,
      String tag]) {
    return RowView(vm, name, attributesIterable, children, isSelfClosing, tag);
  }
}
