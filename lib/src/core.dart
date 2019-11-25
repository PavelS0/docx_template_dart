import 'package:xml/xml.dart';
import 'model.dart';

export 'model.dart';



class BaseNode {
  String tag;
  Content content;
  XmlNode parent;
  int pos;
}

class TextNode extends BaseNode {
  XmlText t;
}

class TemplateNode extends BaseNode {
  XmlElement e;
  Map<String, BaseNode> sub = Map();
}

const namespaceXmlName = "docx_dummy";
const nodeXmlName = "node";
const attrXmlName = "node";

