import 'package:xml/xml.dart';
import 'utils.dart';
/*
class View {
  static const namespaceXmlName = "docx_dummy";
  static const nodeXmlName = "node";
  static const attrXmlName = "node";
  final String tag;
  Map<String, View> sub;
  View next;
  View._({this.sub, this.next, this.tag});
  View.fromDoc(XmlDocument doc) : tag = "" {
    sub = Map();
    RegExp exp = RegExp(r"^.*{{([.a-zA-Z0-9]+)}}.*");
    doc.descendants.forEach((XmlNode node) 
    { 
      if (node is XmlText) {
        RegExpMatch matches = exp.firstMatch(node.text);
        if (matches != null) {
          String path = matches.group(1);
          _initDocNode(sub, path, node);
        }
      }
    });
  }

  _init(XmlElement el, Content content){
    parent = el.parent;
    pos = parent.children.indexOf(el);
    view = el.copy();
  }

  void _replaceWithDummy (XmlText which, String tag) {
    XmlElement el = XmlElement(XmlName(nodeXmlName, namespaceXmlName));
    el.attributes.add(XmlAttribute(XmlName(attrXmlName, namespaceXmlName), tag));
    var siblings = which.parent.children; 
    int index = siblings.indexOf(which);
    siblings.insert(index, el);
    siblings.remove(which);
  }

  /// Получает список вида "person.groups.name", разбивает по точке и ищет объекты в мапе,
  /// а так же созжает их если они не существею
  void _initDocNode(Map<String, InitNode> nodes, String path, XmlText text){
    Map<String, InitNode> current = nodes;
    List<String> keys = path.split(".");
    for (String key in keys) {
      if (current.containsKey(key)) {
        if (key == keys.last) {
          current[key].next = InitNode._(tag: key);
          _replaceWithDummy(text, key);
        } else {
          if(current[key].sub == null) {
            current[key].sub = Map();
          }
          current = current[key].sub;
        }
      } else {
        current[key] = InitNode._(tag: key);
        if (key != keys.last) {
          current[key].sub = Map();
          current = current[key].sub;
        }
      }
    }
  }
}

*/