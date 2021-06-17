part of docx_view;

///
/// Copy visitor wich can copy custum elements extendeds of View
///
/* class XmlCopyVisitor with XmlVisitor {
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
} */

class _Tree {
  List<_Tree> children = [];
  _Tree? parent;
  View? v;
}

class XmlCopyVisitor with XmlVisitor {
  _Tree? _current;

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
  XmlElement? visitElement(XmlElement node) {
    if (node is View) {
      final tree = _Tree();
      if (_current != null) {
        _current!.children.add(tree);
        tree.parent = _current;
      }

      final old = _current;
      _current = tree;

      final attrs =
          node.attributes.map<XmlAttribute>(visit).toList(); // copy attrs
      final childs = node.children.map<XmlNode>(visit).toList(); // copy childs
      final name = visit(node.name);

      final childsViews = tree.children.map((f) => f.v!).toList();
      final parentView = tree.parent?.v;

      final v = node.createNew(name, attrs, childs, node.isSelfClosing,
          node.tag, node.sdtView, childsViews, parentView);

      _current!.v = v;
      _current = old;
      return v;
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
