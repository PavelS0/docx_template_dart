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

  static final XmlCopyVisitor defaultInstance = XmlCopyVisitor();

  @override
  XmlAttribute visitAttribute(XmlAttribute node) {
    return XmlAttribute(visitName(node.name), node.value, node.attributeType);
  }

  @override
  XmlCDATA visitCDATA(XmlCDATA node) {
    return XmlCDATA(node.value);
  }

  @override
  XmlComment visitComment(XmlComment node) {
    return XmlComment(node.value);
  }

  @override
  XmlDoctype visitDoctype(XmlDoctype node) {
    return XmlDoctype(node.value!);
  }

  @override
  XmlDocument visitDocument(XmlDocument node) {
    return XmlDocument(node.children.map(
      (p0) {
        if (p0.nodeType == XmlNodeType.TEXT) {
          return visitText(p0 as XmlText);
        } else {
          return visitElement(p0 as XmlElement) as XmlNode;
        }
      },
    ));
  }

  @override
  XmlDocumentFragment visitDocumentFragment(XmlDocumentFragment node) {
    return XmlDocumentFragment(node.children.map(
      (p0) {
        if (p0.nodeType == XmlNodeType.TEXT) {
          return visitText(p0 as XmlText);
        } else {
          return visitElement(p0 as XmlElement) as XmlNode;
        }
      },
    ));
  }

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

      final attrs = node.attributes
          .map<XmlAttribute>(
            (p0) => visitAttribute(p0),
          )
          .toList(); // copy attrs

      final childs = node.children.map<XmlNode>(
        (p0) {
          if (p0.nodeType == XmlNodeType.TEXT) {
            return visitText(p0 as XmlText);
          } else {
            return visitElement(p0 as XmlElement) as XmlNode;
          }
        },
      ).toList(); // copy childs

      final name = visitName(node.name);
      final childsViews = tree.children.map((f) => f.v!).toList();
      final parentView = tree.parent?.v;

      final v = node.createNew(name, attrs, childs, node.isSelfClosing,
          node.tag, node.sdtView, childsViews, parentView);

      _current!.v = v;
      _current = old;
      return v;
    } else {
      return XmlElement(
          visitName(node.name), node.attributes.map((p0) => visitAttribute(p0)),
          node.children.map((p0) {
        if (p0.nodeType == XmlNodeType.TEXT) {
          return visitText(p0 as XmlText);
        } else {
          return visitElement(p0 as XmlElement) as XmlNode;
        }
      }), node.isSelfClosing);
    }
  }

  @override
  XmlName visitName(XmlName name) {
    return XmlName.fromString(name.qualified);
  }

  @override
  XmlProcessing visitProcessing(XmlProcessing node) {
    return XmlProcessing(node.target, node.value);
  }

  @override
  XmlText visitText(XmlText node) {
    return XmlText(node.value);
  }
}
