library docx_view;

import 'dart:collection';

import 'package:docx_template/docx_template.dart';
import 'package:docx_template/src/docx_entry.dart';
import 'package:xml/xml.dart';

part 'view.dart';
part 'visitor.dart';
part 'numbering.dart';

class ViewManager {
  final XmlCopyVisitor _copyVisitor = XmlCopyVisitor();
  final View root;
  final DocxManager docxManager;
  final Numbering numbering;

  Queue<View> _viewStack = Queue();
  ViewManager._(this.root, this.numbering, this.docxManager);

  factory ViewManager.attach(DocxManager docxMan) {
    final root = View(XmlName('root'));
    final numbering = Numbering.from(docxMan);
    ViewManager vm = ViewManager._(root, numbering, docxMan);
    final xmlEntry =
        docxMan.getEntry(() => DocxXmlEntry(), 'word/document.xml');
    vm._init(xmlEntry.doc.rootElement, root);

    return vm;
  }

  void _init(XmlElement node, View parent) {
    View.traverse(node, (n) => n.name.local == "sdt", (e) {
      var sdtV = SdtView.parse(e);
      if (sdtV != null) {
        var v = _initView(sdtV, parent);
        if (v != null) {
          _init(v, v);
        }
      }
    });
  }

  void _replaceSdtWithView(SdtView sdtView, View v) {
    final sdt = sdtView.sdt;
    var sdtParent = sdt.parent;
    var sdtIndex = sdtParent.children.indexOf(sdtView.sdt);
    sdtParent.children.remove(sdt);
    sdtParent.children.insert(sdtIndex, v);
  }

  View _initView(SdtView sdtView, View parent) {
    View v;
    final sdtChilds = sdtView.content.children.toList();
    sdtView.content.children.clear();

    switch (sdtView.tag) {
      case "table":
        v = RowView(XmlName("table"), [], sdtChilds, false, sdtView.name);
        break;
      case "plain":
        v = PlainView(XmlName("plain"), [], sdtChilds, false, sdtView.name);
        break;
      case "text":
        v = TextView(XmlName("text"), [], sdtChilds, false, sdtView.name);
        break;
      case "list":
        v = ListView(XmlName("list"), [], sdtChilds, false, sdtView.name);
        break;
      case "img":
        v = ImgView(XmlName("img"), [], sdtChilds, false, sdtView.name);
        break;
    }
    if (v != null) {
      _replaceSdtWithView(sdtView, v);

      if (parent.sub == null) {
        parent.sub = {};
      }
      final sub = parent.sub;

      if (sub.containsKey(sdtView.name)) {
        sub[sdtView.name].add(v);
      } else {
        sub[sdtView.name] = [v];
      }
    }
    return v;
  }

  produce(Content c) {
    for (var key in root.sub.keys) {
      for (var v in root.sub[key]) {
        _produceInner(c, v);
      }
    }
  }

  List<XmlElement> _produceInner(Content c, View v) {
    _viewStack.addFirst(v);
    List<XmlElement> produced;
    if (c != null && c.containsKey(v.tag)) {
      produced = v.produce(this, c[v.tag]);
    } else if (c != null && c.key == v.tag) {
      produced = v.produce(this, c);
    } else {
      produced = v.produce(this, null);
    }
    View.replaceWithAll(v, produced, true);
    _viewStack.removeFirst();
    return produced;
  }
}
