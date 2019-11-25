import 'package:xml/xml.dart';
import 'core.dart';
import 'utils.dart';


TextNode _downToTextNode (Map<String, BaseNode> current) {
  TextNode tn;
  while (current != null && current.isNotEmpty && current[current.keys.first] is TemplateNode) {
    current = (current[current.keys.first] as TemplateNode).sub;
  }
  if (current != null && current.isNotEmpty) {
    assert (current[current.keys.first] is TextNode);
    tn = current[current.keys.first];
  }
  return tn;
}

XmlElement _getTemplate(XmlElement from, String tag) {
    XmlElement xn = from.ancestors.firstWhere((n) {
      bool found = false;
      if (n is XmlElement) {
        XmlElement e = n;
        found = e.name.local == tag; 
      }
      return found;
    });
    return xn;
  }

  XmlElement _createDummy (String tag) {
    XmlElement el = XmlElement(XmlName(nodeXmlName, namespaceXmlName));
    el.attributes.add(XmlAttribute(XmlName(attrXmlName, namespaceXmlName), tag));
    return el;
  }

  void _prepareTemplate(TemplateNode node) {
    TextNode tn = _downToTextNode(node.sub);
    XmlElement ref;
    if (node.content != null){
       if (node.content is TableContent) {
        ref = _getTemplate(tn.t.parent, "tr");
      } else if (node.content is ListContent) {
        ref = _getTemplate(tn.t.parent, "p");
      }
      
      replace(ref, _createDummy(node.tag));
      node.e = ref;
      prepare(node.sub);
    }
  }
  
  void _prepareText (TextNode node) {
    replace(node.t, _createDummy(node.tag));
  }

  void prepare(Map<String, BaseNode> nodes)
  {
    for (String k in nodes.keys) {
      if (nodes[k] is TemplateNode){
        _prepareTemplate(nodes[k]);
      } else if (nodes[k] is TextNode) {
        _prepareText(nodes[k]);
      }
    }
  }
