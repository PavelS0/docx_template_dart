import 'package:docx_template/docx_template.dart';
import 'package:xml/xml.dart';
import 'model.dart';
import 'visitor.dart';

typedef bool Check(XmlElement n);
typedef void OnFound(XmlElement e);

class _SdtView {
  final String tag;
  final String name;
  final XmlElement content;
  final XmlElement sdt;
  _SdtView(this.tag, this.name, this.content, this.sdt);
  factory _SdtView.parse(XmlElement e) {
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
              return _SdtView(tagAttr.value, aliasAttr.value, content, sdt);
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
  final XmlDocument doc;
  final XmlCopyVisitor _copyVisitor = XmlCopyVisitor();
  final DocxTemplate t;
  View(this.t, XmlName name,
      [Iterable<XmlAttribute> attributesIterable = const [],
      Iterable<XmlNode> children = const [],
      bool isSelfClosing = true,
      this.doc,
      this.tag])
      : super(name, attributesIterable, children, isSelfClosing);

  factory View.attchToDoc(XmlDocument document, DocxTemplate t) {
    var v = View(t, XmlName("docx_template"), [], [], false, document);
    v._init(document.rootElement, t);
    return v;
  }

  View createNew(XmlName name,
      [Iterable<XmlAttribute> attributesIterable = const [],
      Iterable<XmlNode> children = const [],
      bool isSelfClosing = true,
      String tag]) {
    return null;
  }

  produce(T c) {
    if (doc == null) {
      throw Exception("first call [attachToDoc]");
    }
    for (var key in sub.keys) {
      for (var v in sub[key]) {
        if (c.containsKey(key)) {
          var list = v._produce(c[key]);
          _replaceWithAll(v, list, true);
        }
      }
    }
  }

  static _traverse(XmlElement node, Check check, OnFound onFound) {
    if (node.children != null && node.children.isNotEmpty) {
      for (var c in node.children) {
        if (c is XmlElement) {
          if (check(c)) {
            onFound(c);
          } else {
            _traverse(c, check, onFound);
          }
        }
      }
    }
  }

  static List<View> _subViews(XmlElement e) {
    List<View> views = List();
    _traverse(e, (test) => test is View, (e) => views.add(e));
    return views;
  }

  List<XmlElement> _produce(T c) {
    return null;
  }

  List<XmlElement> _produceInner(Content c, View v) {
    List<XmlElement> produced;
    if (c.containsKey(v.tag)) {
      produced = v._produce(c[v.tag]);
    } else if (c.key == v.tag) {
      produced = v._produce(c);
    }
    if (produced != null) {
      _replaceWithAll(v, produced, true);
    }
    return produced;
  }

  void _replaceWithAll(
      XmlElement elem, List<XmlElement> to, bool clearParents) {
    if (clearParents) {
      for (XmlElement e in to) {
        if (e.parent != null) {
          e.parent.children.remove(e);
        }
      }
    }
    var childs = elem.parent.children;
    var index = childs.indexOf(elem);
    childs.removeAt(index);
    childs.insertAll(index, to);
  }

  /*
  void _moveChilds(XmlElement from, XmlElement to) {
    var childs = from.children.toList();
    if (to.children.isNotEmpty) {
      throw XmlParentException("childrens list of [to] must be empty");
    }
    from.children.clear();
    to.children.addAll(childs);
  }
  */

  View _initView(_SdtView sdtView, DocxTemplate t) {
    View v;
    var sdt = sdtView.sdt;
    var childs = sdtView.content.children.toList();
    switch (sdtView.tag) {
      case "table":
        sdtView.content.children.clear();
        RowView tabv =
            RowView(t, XmlName("table"), [], childs, false, sdtView.name);
        v = tabv;
        break;
      case "plain":
        sdtView.content.children.clear();
        PlainView pv =
            PlainView(t, XmlName("plain"), [], childs, false, sdtView.name);
        v = pv;
        break;
      case "text":
        sdtView.content.children.clear();
        TextView tv =
            TextView(t, XmlName("text"), [], childs, false, sdtView.name);
        v = tv;
        break;
      case "list":
        sdtView.content.children.clear();
        ListView lv =
            ListView(t, XmlName("list"), [], childs, false, sdtView.name);
        v = lv;
        break;
    }
    if (v != null) {
      var sdtParent = sdt.parent;
      var sdtIndex = sdtParent.children.indexOf(sdtView.sdt);
      sdtParent.children.remove(sdt);
      sdtParent.children.insert(sdtIndex, v);

      if (sub == null) {
        sub = Map();
      }
      if (sub.containsKey(sdtView.name)) {
        sub[sdtView.name].add(v);
      } else {
        sub[sdtView.name] = [v];
      }
    }
    return v;
  }

  void _init(XmlElement node, DocxTemplate t) {
    _traverse(node, (n) => n.name.local == "sdt", (e) {
      var sdtV = _SdtView.parse(e);
      if (sdtV != null) {
        var v = _initView(sdtV, t);
        if (v != null) {
          v._init(v, t);
        }
      }
    });
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

  void _findAndReplaceText(XmlElement from, String text) {
    XmlText t = from.descendants
        .firstWhere((test) => test is XmlText, orElse: () => null);
    if (t != null) {
      t.parent.children[0] = XmlText(text);
    }
  }
}

class TextView extends View<TextContent> {
  TextView(DocxTemplate t, XmlName name,
      [Iterable<XmlAttribute> attributesIterable = const [],
      Iterable<XmlNode> children = const [],
      bool isSelfClosing = true,
      String tag])
      : super(t, name, attributesIterable, children, isSelfClosing, null, tag);
  @override
  List<XmlElement> _produce(TextContent c) {
    List<XmlElement> list = List.from(this.children);
    _findAndReplaceText(this, c.text);
    this.children.clear();
    return list;
  }

  @override
  TextView createNew(XmlName name,
      [Iterable<XmlAttribute> attributesIterable = const [],
      Iterable<XmlNode> children = const [],
      bool isSelfClosing = true,
      String tag]) {
    return TextView(t, name, attributesIterable, children, isSelfClosing, tag);
  }
}

class PlainView extends View<PlainContent> {
  PlainView(DocxTemplate t, XmlName name,
      [Iterable<XmlAttribute> attributesIterable = const [],
      Iterable<XmlNode> children = const [],
      bool isSelfClosing = true,
      String tag])
      : super(t, name, attributesIterable, children, isSelfClosing, null, tag);
  @override
  List<XmlElement> _produce(PlainContent c) {
    XmlElement copy = this.accept(_copyVisitor);
    var views = View._subViews(copy);
    for (var v in views) {
      _produceInner(c, v);
    }
    return List.from(copy.children);
  }

  @override
  PlainView createNew(XmlName name,
      [Iterable<XmlAttribute> attributesIterable = const [],
      Iterable<XmlNode> children = const [],
      bool isSelfClosing = true,
      String tag]) {
    return PlainView(t, name, attributesIterable, children, isSelfClosing, tag);
  }
}

class ListView extends View<ListContent> {
  ListView(DocxTemplate t, XmlName name,
      [Iterable<XmlAttribute> attributesIterable = const [],
      Iterable<XmlNode> children = const [],
      bool isSelfClosing = true,
      String tag])
      : super(t, name, attributesIterable, children, isSelfClosing, null, tag);

  @override
  List<XmlElement> _produce(ListContent c) {
    List<XmlElement> l = [];
    for (var cont in c.list) {
      XmlElement copy = this.accept(_copyVisitor);
      var views = View._subViews(copy);
      for (var v in views) {
        _produceInner(cont, v);
      }
      if (copy.children != null) {
        l.addAll(copy.children.cast<XmlElement>());
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
    return ListView(t, name, attributesIterable, children, isSelfClosing, tag);
  }
}

class RowView extends View<TableContent> {
  RowView(DocxTemplate t, XmlName name,
      [Iterable<XmlAttribute> attributesIterable = const [],
      Iterable<XmlNode> children = const [],
      bool isSelfClosing = true,
      String tag])
      : super(t, name, attributesIterable, children, isSelfClosing, null, tag);

  @override
  List<XmlElement> _produce(TableContent c) {
    List<XmlElement> l = [];
    for (var cont in c.rows) {
      XmlElement copy = this.accept(_copyVisitor);
      var views = View._subViews(copy);
      for (var v in views) {
        _produceInner(cont, v);
      }
      if (copy.children != null) {
        l.addAll(copy.children.cast<XmlElement>());
      }
    }
    return l;

    /*
    тут надо старое переебать
    
    List<XmlElement> l = [];
    XmlElement tr = View._findChild(this, "tr");
    for (var cont in c.rows) {
      var copy = tr.accept(_copyVisitor);
      var views = View._subViews(copy);
      for (var v in views) {
        if (cont.cols.containsKey(v.tag)) {
          var produced = v._produce(cont.cols[v.tag]);
          _replaceWithAll(v, produced, false);
        }
      }
      l.add(copy);
    }
    return l;
    */
  }

  @override
  RowView createNew(XmlName name,
      [Iterable<XmlAttribute> attributesIterable = const [],
      Iterable<XmlNode> children = const [],
      bool isSelfClosing = true,
      String tag]) {
    return RowView(t, name, attributesIterable, children, isSelfClosing, tag);
  }
}
