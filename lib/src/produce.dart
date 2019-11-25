import 'package:xml/xml.dart';
import 'core.dart';
import 'utils.dart';

XmlText _produceText(TextNode node, [TextContent content]) {
    XmlText text;
    if (content == null) {
      if (node.content != null) {
        text = XmlText((node.content as TextContent).text);
      }
    } else {
      text = XmlText(content.text);
    }
    return text;
  }

  _produceRow(XmlElement xml, Map<String, Content> row, Map<String, BaseNode> nodes) {
    Iterable<XmlElement> els = xml.findAllElements(namespaceXmlName +":"+nodeXmlName);
    for (XmlElement el in els) {
      String key = el.getAttribute(namespaceXmlName +":"+attrXmlName);
      BaseNode bn = nodes[key];
      if (bn is TextNode) {
        XmlNode newNode;
        if (row[key] is TextContent) {
           newNode = _produceText(bn, row[key]);
        }
        replace(el, newNode);
      } else if (bn is TemplateNode) {
        List<XmlNode> newNodes;
        newNodes = _produceTemplate(bn);
        replaceAll(el, newNodes);
      }
    }
  }

   List<XmlNode> _produceTable(TemplateNode node){
    List<XmlNode> table = List();
    TableContent t = node.content;
    for (Map<String, Content> row in t.rows) {
      XmlElement copy = node.e.copy();
      _produceRow(copy, row, node.sub);
      table.add(copy);
    }
    return table;
  }

  void _produceListItem(XmlElement xml, TextContent item, TemplateNode node) {
    Iterable<XmlElement> els = xml.findAllElements(namespaceXmlName +":"+nodeXmlName);
    XmlElement el = els.first;
    XmlText text = _produceText(node.sub["values"], item);
    replace(el, text);
  }

  List<XmlNode> _produceList(TemplateNode node){
    List<XmlNode> list = List();
    ListContent t = node.content;
    for (Content c in t.list) {
      if (c is TextContent) {
        XmlElement copy = node.e.copy();
        _produceListItem(copy, c, node);
        list.add(copy);
      } else if (c is ListContent) {
        if (node is TemplateNode) { 
          if (node.sub.containsKey(c.key)) {
            list.addAll(_produceList(node.sub[c.key]));
          }
        }
      }
    }
    return list;
  }

  List<XmlNode> _produceTemplate(TemplateNode node) {
    List<XmlNode> newNodes; 
    if (node.content is TableContent) {
      newNodes = _produceTable(node);
    } else if (node.content is ListContent){
      newNodes = _produceList(node);
    } 
    return newNodes;
  }

  void produce(XmlElement xml, Map<String, BaseNode> nodes)
  {
    Iterable<XmlElement> els = xml.findAllElements(namespaceXmlName +":"+nodeXmlName);
    for (XmlElement el in els) {
      String key = el.getAttribute(namespaceXmlName +":"+attrXmlName);
      BaseNode bn = nodes[key];
      if (bn is TextNode) {
        XmlNode newNode;
        newNode = _produceText(bn);
        replace(el, newNode);
      } else if (bn is TemplateNode) {
        List<XmlNode> newNodes;
      
        newNodes = _produceTemplate(bn);
        replaceAll(el, newNodes);
      }
    }
  }