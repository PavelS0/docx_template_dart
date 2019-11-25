import 'package:DocxTemplate/src/core.dart';
import 'package:xml/xml.dart';
import 'init.dart';
/*
abstract class View<T> {
  String name;
  XmlElement ref;
  Map<String, View> sub;
  View();

  static XmlElement _simpleSearch(XmlElement from, String tag) {
    XmlElement xn = from.descendants.firstWhere((n) {
      bool found = false;
      if (n is XmlElement) {
        XmlElement e = n;
        found = e.name.local == tag; 
      }
      return found;
    }, orElse: () => null);
    return xn;
  }

  XmlElement _findChild(XmlElement e, String tag) {
    return e.children.firstWhere((test)=>test is XmlElement && test.name.local == tag, orElse: ()=>null);
  }

  XmlAttribute _findAttr(XmlElement e, String attr) {
    return e.children.firstWhere((test)=>test is XmlElement && test.name.local == tag, orElse: ()=>null);
  }

  void _findAndReplaceText(XmlElement from, String text)
  {
    XmlText t = from.descendants.firstWhere((test)=>test is XmlText, orElse: ()=> null);
    if (t != null) {
      t.parent.children[0] = XmlText(text);
    }
  }

  void _init (XmlElement e) {
    e.descendants.forEach((XmlNode node) 
    {
      if (node is XmlElement) { 
        if (node.name.local == "sdt") {
          XmlElement sdt = node;
          XmlElement sdtPr = _findChild(sdt, "sdtPr");
          if (sdtPr != null) {
            XmlElement alias = _findChild(sdtPr, "alias");
            XmlElement tag = _findChild(sdtPr, "tag");
            if (alias != null && tag != null) {
              XmlElement content = sdt.children.firstWhere((test)=>test is XmlElement && test.name.local == "sdtContent", orElse: ()=>null);
              if (content != null) {
                XmlAttribute aliasAttr = _findAttr(alias, "val");
                XmlAttribute tagAttr = _findAttr(alias, "val");
                if (aliasAttr != null && tagAttr != null) {
                  View v;
                  switch (tagAttr.value) {
                    case "table":
                      RowView tabv = RowView();
                      v = tabv;
                      break;
                    case "plain":
                      TextView tv = TextView();
                      v = tv;
                      break;
                    case "list":
                      ListView lv = ListView();
                      v = lv;
                      break;
                  }
                  v.name = aliasAttr.value;
                  v.ref = sdt;
                  v._init(content);
                  if (sub == null) {
                    sub = Map();
                  }
                  sub[v.name] = v;
                }
              }
            }
          }
        }
      }
    });
  }

  View.fromDoc(XmlDocument doc) {
    sub = Map();
  }

  XmlElement produce (T c);
}

class TextView extends View<TextContent> {
  TextView();
  @override
  XmlElement produce (TextContent c) {
    XmlElement copy = ref.copy();
    _findAndReplaceText(copy, c.text);
    return copy;
  }
}

class ListView extends View<ListContent> {
  ListView();
  @override
  XmlElement produce (ListContent c) {
    XmlElement copy = ref.copy();
    //copy.accept(visitor)
    XmlElement p = _findChild(copy, "p");
    if (p != null) {
      for (String k in sub.keys) {
        for (var cont in c.sub) {
          sub[k].produce(cont);
        }
      }
      for(var c in c.sub){
       
      }
    }
    return copy;
  }
}

class RowView extends View {
  RowView();
  RowView.from(XmlText from){
    XmlElement el = View._simpleSearch(from.parent, "tr");
    _init(el);
  }
}

class Content {
  String key;
  List<Content> sub;
  View _view;
  Content(this.key);

  void _init(InitNode inode){
    var cIn = inode.sub;
    for (Content s in sub) {
      if(cIn.containsKey(s.key)) {
        s._init(cIn[s.key]);
      }
    }
  }
}

class TextContent extends Content {
  String text;
  TextContent(String key, this.text): super (key);
  @override
  void _init(InitNode inode) {
    //_view = TextView.from(inode.ref);
    super._init(inode);
  }
}

class ListContent extends Content {
  List<Content> list;
  ListContent (String key, this.list): super (key);
  @override
  void _init(InitNode inode) {
    //_view = ListView.from(inode.ref);
     super._init(inode);
  }
}

class TableContent extends Content {
  List<RowContent> rows;
  TableContent (String key, this.rows): super (key);
  @override
  void _init(InitNode inode) {
    //_view = ListView.from(inode.ref);
     super._init(inode);
  }
}

class RowContent extends Content {
  Map<String, Content> cols;
  RowContent (String key, this.cols): super (key);
}*/
