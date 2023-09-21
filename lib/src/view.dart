part of docx_view;

typedef Check = bool Function(XmlElement n);
typedef OnFound = void Function(XmlElement e);

class View<T extends Content?> extends XmlElement {
  Map<String, List<View>>? sub;
  final SdtView? sdtView;
  final String tag;
  final List<View> childrensView;
  final View? parentView;
  View(
      XmlName name,
      Iterable<XmlAttribute> attributesIterable,
      Iterable<XmlNode> children,
      bool isSelfClosing,
      this.tag,
      this.sdtView,
      this.childrensView,
      this.parentView)
      : super(name, attributesIterable, children, isSelfClosing);

  View createNew(
      XmlName name,
      Iterable<XmlAttribute> attributesIterable,
      Iterable<XmlNode> children,
      bool isSelfClosing,
      String tag,
      SdtView? sdtView,
      List<View> childrensView,
      View? parentView) {
    return View(name, attributesIterable, children, isSelfClosing, tag, sdtView,
        childrensView, parentView);
  }

  List<XmlElement> produce(ViewManager vm, T c) {
    return [];
  }

  static XmlAttribute? _findAttr(XmlElement e, String attr) {
    return e.attributes.firstWhereOrNull((test) => test.name.local == attr);
  }
}

class TextView extends View<TextContent?> {
  TextView(
      XmlName name,
      Iterable<XmlAttribute> attributesIterable,
      Iterable<XmlNode> children,
      bool isSelfClosing,
      String tag,
      SdtView? sdtView,
      List<View> childrensView,
      View? parentView)
      : super(name, attributesIterable, children, isSelfClosing, tag, sdtView,
            childrensView, parentView);

  @override
  List<XmlElement> produce(ViewManager vm, TextContent? c) {
    XmlElement copy = XmlCopyVisitor().visitElement(this)!;
    final r = findR(copy);
    final pr = copy.descendants.firstWhereOrNull(
        (e) => e is XmlElement && e.name.local == 'hyperlink');
    if (pr != null) {
      final idAttr = pr.getAttribute('r:id');

      final docRels = vm.docxManager
          .getEntry(() => DocxRelsEntry(), 'word/_rels/document.xml.rels');
      if (idAttr != null && docRels != null) {
        final rel = docRels.getRel(idAttr);
        if (rel != null) {
          if (c != null) {
            rel.target = (c as HyperlinkContent).url;
            docRels.update(idAttr, rel);
          }
        }
      }
    }

    if (r != null && c != null) {
      _removeRSiblings(r);
      _updateRText(vm, r, c.text);
    }
    return List.from(copy.children);
  }

  @override
  TextView createNew(
      XmlName name,
      Iterable<XmlAttribute> attributesIterable,
      Iterable<XmlNode> children,
      bool isSelfClosing,
      String tag,
      SdtView? sdtView,
      List<View> childrensView,
      View? parentView) {
    return TextView(name, attributesIterable, children, isSelfClosing, tag,
        sdtView, childrensView, parentView);
  }

  XmlElement? findR(XmlElement src) => src.descendants
          .firstWhereOrNull((e) => e is XmlElement && e.name.local == 'r')
      as XmlElement?;

  void _removeRSiblings(XmlElement sib) {
    final parent = sib.parent;

    XmlElement? next = sib.nextSibling as XmlElement?;
    while (next != null) {
      final laterNext = next.nextSibling;
      if (next.name.local == 'r') {
        parent!.children.remove(next);
      }
      next = laterNext as XmlElement?;
    }

    XmlElement? prev = sib.previousSibling as XmlElement?;
    while (prev != null) {
      final laterPrev = prev.previousSibling;
      if (prev.name.local == 'r') {
        parent!.children.remove(prev);
      }
      prev = laterPrev as XmlElement?;
    }
  }

  XmlElement _brElement() => XmlElement(XmlName('br', 'w'));

  void _updateRText(ViewManager vm, XmlElement r, String? text) {
    final tIndex =
        r.children.indexWhere((e) => e is XmlElement && e.name.local == 't');
    if (tIndex >= 0) {
      final t = r.children[tIndex];
      var multiline = text != null && text.contains('\n');
      if (multiline) {
        var pasteIndex = tIndex + 1;
        final lines = text.split('\n');
        for (var l in lines) {
          if (l == lines.first) {
            // Update exists T tag
            t.children[0] = XmlText(l);
          } else {
            // Make T tag copy and add to R
            final XmlElement tCp =
                XmlCopyVisitor().visitElement(t as XmlElement)!;
            tCp.children[0] = XmlText(l);
            r.children.insert(pasteIndex++, tCp);
          }
          r.children.insert(pasteIndex++, _brElement());
        }
      } else {
        t.children[0] = XmlText(text!);
      }
    }
  }
}

class PlainView extends View<PlainContent?> {
  PlainView(
      XmlName name,
      Iterable<XmlAttribute> attributesIterable,
      Iterable<XmlNode> children,
      bool isSelfClosing,
      String tag,
      SdtView? sdtView,
      List<View> childrensView,
      View? parentView)
      : super(name, attributesIterable, children, isSelfClosing, tag, sdtView,
            childrensView, parentView);
  @override
  List<XmlElement> produce(ViewManager vm, PlainContent? c) {
    View copy = XmlCopyVisitor().visitElement(this) as View;
    for (var v in copy.childrensView) {
      vm._produceInner(c, v);
    }
    return List.from(copy.children);
  }

  @override
  PlainView createNew(
      XmlName name,
      Iterable<XmlAttribute> attributesIterable,
      Iterable<XmlNode> children,
      bool isSelfClosing,
      String tag,
      SdtView? sdtView,
      List<View> childrensView,
      View? parentView) {
    return PlainView(name, attributesIterable, children, isSelfClosing, tag,
        sdtView, childrensView, parentView);
  }
}

class ListView extends View<ListContent?> {
  ListView(
      XmlName name,
      Iterable<XmlAttribute> attributesIterable,
      Iterable<XmlNode> children,
      bool isSelfClosing,
      String tag,
      SdtView? sdtView,
      List<View> childrensView,
      View? parentView)
      : super(name, attributesIterable, children, isSelfClosing, tag, sdtView,
            childrensView, parentView);

  XmlElement? _findFirstChild(XmlElement src, String name) =>
      src.children.isNotEmpty
          ? src.children.firstWhereOrNull(
              (e) => e is XmlElement && e.name.local == name) as XmlElement?
          : null;

  XmlElement? _getNumIdNode(XmlElement list) {
    if (list.children.isNotEmpty) {
      final e = list.children.first;
      if (e is XmlElement) {
        final pPr = _findFirstChild(e, 'pPr');
        if (pPr != null) {
          final numPr = _findFirstChild(pPr, 'numPr');
          if (numPr != null) {
            final numId = _findFirstChild(numPr, 'numId');
            return numId;
          }
        }
      }
    }
    return null;
  }

  String _getNewNumId(ViewManager vm, XmlElement list) {
    final numId = _getNumIdNode(list);
    if (numId != null) {
      final idNode = numId.getAttributeNode('val', namespace: '*');
      if (idNode != null) {
        final val = idNode.value;
        if (vm.numbering != null) {
          final newId = vm.numbering!.copy(val);
          return newId;
        } else {
          return val;
        }
      }
    }
    return '';
  }

  void _changeListId(XmlElement copy, String newId) {
    final numId = _getNumIdNode(copy);
    if (numId != null) {
      final idNode = numId.getAttributeNode('val', namespace: '*');
      numId.attributes.remove(idNode);
      numId.attributes.add(XmlAttribute(XmlName('val', 'w'), newId));
    }
  }

  @override
  List<XmlElement> produce(ViewManager vm, ListContent? c) {
    List<XmlElement> l = [];
    if (c == null) {
      if (vm._viewStack.length >= 2 && vm._viewStack.elementAt(1) is RowView) {
        //

        final doc = XmlDocument.parse('''
        <w:p>
          <w:pPr>
            <w:pStyle w:val="TableContents"/>
            <w:rPr>
              <w:lang w:val="en-US"/>
            </w:rPr>
          </w:pPr>
          <w:r>
            <w:rPr>
              <w:lang w:val="en-US"/>
            </w:rPr>
            <w:t></w:t>
          </w:r>
        </w:p>
        ''');

        /* XmlElement copy = this.accept(vm._copyVisitor);
        var views = View.subViews(copy);
        for (var v in views) {
          vm._produceInner(null, v);
        } */
        l = [doc.rootElement];
      }
      /*  */
    } else {
      final vs = vm._viewStack;
      String newNumId = '';
      if (vs.any((element) => element is PlainView || element is RowView)) {
        newNumId = _getNewNumId(vm, this);
      }
      for (var cont in c.list) {
        View copy = XmlCopyVisitor().visitElement(this) as View;

        if (newNumId.isNotEmpty &&
            vs.any((element) => element is PlainView || element is RowView)) {
          _changeListId(copy, newNumId);
        }

        for (var v in copy.childrensView) {
          vm._produceInner(cont, v);
        }

        l.addAll(copy.children.cast<XmlElement>());
      }
    }
    return l;
  }

  @override
  ListView createNew(
      XmlName name,
      Iterable<XmlAttribute> attributesIterable,
      Iterable<XmlNode> children,
      bool isSelfClosing,
      String tag,
      SdtView? sdtView,
      List<View> childrensView,
      View? parentView) {
    return ListView(name, attributesIterable, children, isSelfClosing, tag,
        sdtView, childrensView, parentView);
  }
}

class RowView extends View<TableContent?> {
  RowView(
      XmlName name,
      Iterable<XmlAttribute> attributesIterable,
      Iterable<XmlNode> children,
      bool isSelfClosing,
      String tag,
      SdtView sdtView,
      List<View> childrensView,
      View? parentView)
      : super(name, attributesIterable, children, isSelfClosing, tag, sdtView,
            childrensView, parentView);

  @override
  List<XmlElement> produce(ViewManager vm, TableContent? c) {
    List<XmlElement> l = [];

    if (c == null) {
      XmlElement copy = XmlCopyVisitor().visitElement(this)!;
      l = List.from(copy.children);
    } else {
      for (var cont in c.rows) {
        View copy = XmlCopyVisitor().visitElement(this) as View;
        for (var v in copy.childrensView) {
          vm._produceInner(cont, v);
        }
        l.addAll(copy.children.cast<XmlElement>());
      }
    }
    return l;
  }

  @override
  RowView createNew(
      XmlName name,
      Iterable<XmlAttribute> attributesIterable,
      Iterable<XmlNode> children,
      bool isSelfClosing,
      String tag,
      SdtView? sdtView,
      List<View> childrensView,
      View? parentView) {
    return RowView(name, attributesIterable, children, isSelfClosing, tag,
        sdtView!, childrensView, parentView);
  }
}

class ImgView extends View<ImageContent?> {
  ImgView(
      XmlName name,
      Iterable<XmlAttribute> attributesIterable,
      Iterable<XmlNode> children,
      bool isSelfClosing,
      String tag,
      SdtView? sdtView,
      List<View> childrensView,
      View? parentView)
      : super(name, attributesIterable, children, isSelfClosing, tag, sdtView,
            childrensView, parentView);

  @override
  List<XmlElement> produce(ViewManager vm, ImageContent? c) {
    List<XmlElement> l = [];
    XmlElement copy = XmlCopyVisitor().visitElement(this) as View;
    l = List.from(copy.children);
    if (c != null) {
      final pr = copy.descendants
          .firstWhereOrNull((e) => e is XmlElement && e.name.local == 'blip');
      if (pr != null) {
        final idAttr = pr.getAttribute('r:embed');

        final listDocRelEntry = <DocxRelsEntry?>[
          vm.docxManager
              .getEntry(() => DocxRelsEntry(), 'word/_rels/document.xml.rels'),
          ...vm.docxManager.arch.map((file) {
            if (file.name.contains("header") && file.name.contains(".rels")) {
              return vm.docxManager.getEntry(() => DocxRelsEntry(),
                  'word/_rels/${file.name.split('/').last}');
            }
          }).where((element) => element != null),
          ...vm.docxManager.arch.map((file) {
            if (file.name.contains("footer") && file.name.contains(".rels")) {
              return vm.docxManager.getEntry(() => DocxRelsEntry(),
                  'word/_rels/${file.name.split('/').last}');
            }
          }).where((element) => element != null),
        ];

        listDocRelEntry.forEach((relsEntry) {
          if (idAttr != null && relsEntry != null) {
            final rel = relsEntry.getRel(idAttr);
            if (rel != null) {
              final base = path.basename(rel.target);
              final ext = path.extension(base);
              final imageId = relsEntry.nextImageId();

              rel.target =
                  path.join(path.dirname(rel.target), 'image$imageId$ext');
              final imagePath = 'word/${rel.target}';
              final relId = relsEntry.nextId();
              pr.setAttribute('r:embed', relId);
              relsEntry.add(relId, rel);

              vm.docxManager.add(imagePath, DocxBinEntry(c.img));
            }
          }
        });
      }
    } else if (vm.imagePolicy == ImagePolicy.remove){
      final drawing = copy.descendants
          .firstWhereOrNull((e) => e is XmlElement && e.name.local == 'drawing');
      if (drawing != null ) {
        drawing.parent!.children.remove(drawing);
      }
    }
    return l;
  }

  @override
  ImgView createNew(
      XmlName name,
      Iterable<XmlAttribute> attributesIterable,
      Iterable<XmlNode> children,
      bool isSelfClosing,
      String tag,
      SdtView? sdtView,
      List<View> childrensView,
      View? parentView) {
    return ImgView(name, attributesIterable, children, isSelfClosing, tag,
        sdtView, childrensView, parentView);
  }
}
