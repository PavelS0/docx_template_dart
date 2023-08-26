import 'dart:collection';

///
/// Root content element, use method add() to add inner contents
///
class Content extends MapBase<String, Content> {
  String key;
  Map<String, Content> sub = {};
  Content([this.key = '', Map<String, Content>? sub]) : sub = sub ?? {};

  @override
  Content? operator [](Object? key) {
    return sub[key as String];
  }

  @override
  void operator []=(String key, Content value) {
    sub[key] = value;
  }

  @override
  void clear() {
    sub.clear();
  }

  @override
  Iterable<String> get keys => sub.keys;

  @override
  Content? remove(Object? key) {
    return sub.remove(key);
  }

  add(Content c) {
    sub[c.key] = c;
  }

  ///
  /// Dont use, not implemented!
  ///
  static List<Content> fromMap(Map<String, dynamic> map) {
    throw Exception("not implemented");
  }
}

///
/// Plain content take nodes from docx "as is" its useful
/// to use with ListContent.
///
class PlainContent extends Content {
  PlainContent(String key) : super(key, {});
}

class TextContent extends Content {
  late String text;
  TextContent(String key, dynamic text) : super(key, {}) {
    if (text is String) {
      this.text = text;
    } else {
      this.text = text.toString();
    }
  }
}

class HyperlinkContent extends TextContent {
  late String text;
  final String url;
  HyperlinkContent({
    required String key,
    required dynamic text,
    required this.url,
  }) : super(key, {}) {
    if (text is String) {
      this.text = text;
    } else {
      this.text = text.toString();
    }
  }
}

class ListContent extends Content {
  List<Content> list;
  ListContent(String key, this.list) : super(key, {});
}

class TableContent extends Content {
  List<RowContent> rows;
  TableContent(String key, this.rows) : super(key, {});
  addRow(RowContent content) {
    rows.add(content);
  }
}

class RowContent extends Content {
  RowContent([Map<String, Content>? cols]) : super("", cols ?? {});
}

class ImageContent extends Content {
  List<int>? img;
  bool removeFromTemplate = false;
  String? filename;
  ImageContent(String key, this.img) : super(key, {});
}
