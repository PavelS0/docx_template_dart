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

  void _replaceSdtWithView(SdtView sdtView, View v) {
    final sdt = sdtView.sdt;
    var sdtParent = sdt.parent;
    var sdtIndex = sdtParent.children.indexOf(sdtView.sdt);
    sdtParent.children.remove(sdt);
    sdtParent.children.insert(sdtIndex, v);
  }

  View _initTable(SdtView sdtView) {
    final childs = sdtView.content.children.toList();
    sdtView.content.children.clear();
    RowView tabv =
        RowView(this, XmlName("table"), [], childs, false, sdtView.name);
    return tabv;
  }

  View _initPlain(SdtView sdtView) {
    var childs = sdtView.content.children.toList();
    sdtView.content.children.clear();
    PlainView pv =
        PlainView(this, XmlName("plain"), [], childs, false, sdtView.name);
    return pv;
  }

  View _initText(SdtView sdtView) {
    var childs = sdtView.content.children.toList();
    sdtView.content.children.clear();
    TextView tv =
        TextView(this, XmlName("text"), [], childs, false, sdtView.name);
    return tv;
  }

  View _initList(SdtView sdtView) {
    var childs = sdtView.content.children.toList();
    sdtView.content.children.clear();
    ListView lv =
        ListView(this, XmlName("list"), [], childs, false, sdtView.name);
    return lv;
  }

  View _initView(SdtView sdtView, View parent) {
    View v;
    final sdt = sdtView.sdt;

    switch (sdtView.tag) {
      case "table":
        v = _initTable(sdtView);
        break;
      case "plain":
        v = _initPlain(sdtView);
        break;
      case "text":
        v = _initText(sdtView);
        break;
      case "list":
        v = _initList(sdtView);
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
