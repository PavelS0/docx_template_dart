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
  final DocxTemplate t;
  final View root;
  final Numbering numbering;

  Queue<View> _viewStack = Queue();
  ViewManager._(this.t, this.root, this.numbering);

  factory ViewManager.attach(
      DocxEntry documentEntry, DocxEntry numberingEntry, DocxTemplate t) {
    final root = View(null, XmlName('root'));
    Numbering numbering;
    if (numberingEntry != null) {
      numbering = Numbering.from(numberingEntry);
    }
    ViewManager vm = ViewManager._(t, root, numbering);
    vm._init(documentEntry.doc.rootElement, root);

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

  View _initView(SdtView sdtView, View parent) {
    View v;
    var sdt = sdtView.sdt;
    var childs = sdtView.content.children.toList();
    switch (sdtView.tag) {
      case "table":
        sdtView.content.children.clear();
        RowView tabv =
            RowView(this, XmlName("table"), [], childs, false, sdtView.name);
        v = tabv;
        break;
      case "plain":
        sdtView.content.children.clear();
        PlainView pv =
            PlainView(this, XmlName("plain"), [], childs, false, sdtView.name);
        v = pv;
        break;
      case "text":
        sdtView.content.children.clear();
        TextView tv =
            TextView(this, XmlName("text"), [], childs, false, sdtView.name);
        v = tv;
        break;
      case "list":
        sdtView.content.children.clear();
        ListView lv =
            ListView(this, XmlName("list"), [], childs, false, sdtView.name);
        v = lv;
        break;
    }
    if (v != null) {
      var sdtParent = sdt.parent;
      var sdtIndex = sdtParent.children.indexOf(sdtView.sdt);
      sdtParent.children.remove(sdt);
      sdtParent.children.insert(sdtIndex, v);

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
      produced = v.produce(c[v.tag]);
    } else if (c != null && c.key == v.tag) {
      produced = v.produce(c);
    } else {
      produced = v.produce(null);
    }
    View.replaceWithAll(v, produced, true);
    _viewStack.removeFirst();
    return produced;
  }
}
