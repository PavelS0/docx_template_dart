part of docx_view;

///
/// Copy visitor wich can copy custum elements extendeds of View
///
class XmlCopyVisitor with XmlVisitor {
  static final XmlTransformer defaultInstance = XmlTransformer();

  @override
  XmlAttribute visitAttribute(XmlAttribute node) =>
      XmlAttribute(visit(node.name), node.value, node.attributeType);

  @override
  XmlCDATA visitCDATA(XmlCDATA node) => XmlCDATA(node.text);

  @override
  XmlComment visitComment(XmlComment node) => XmlComment(node.text);

  @override
  XmlDoctype visitDoctype(XmlDoctype node) => XmlDoctype(node.text);

  @override
  XmlDocument visitDocument(XmlDocument node) =>
      XmlDocument(node.children.map(visit));

  @override
  XmlDocumentFragment visitDocumentFragment(XmlDocumentFragment node) =>
      XmlDocumentFragment(node.children.map(visit));

  @override
  XmlElement visitElement(XmlElement node) {
    if (node is View) {
      return node.createNew(visit(node.name), node.attributes.map(visit),
          node.children.map(visit), node.isSelfClosing, node.tag, node.sdtView);
    } else {
      return XmlElement(visit(node.name), node.attributes.map(visit),
          node.children.map(visit), node.isSelfClosing);
    }
  }

  @override
  XmlName visitName(XmlName name) => XmlName.fromString(name.qualified);

  @override
  XmlProcessing visitProcessing(XmlProcessing node) =>
      XmlProcessing(node.target, node.text);

  @override
  XmlText visitText(XmlText node) => XmlText(node.text);
}
