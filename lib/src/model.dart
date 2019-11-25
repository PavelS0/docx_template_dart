import 'dart:collection';

import 'package:DocxTemplate/src/core.dart';
import 'package:xml/xml.dart';

class Content extends MapBase<String, Content> {
  String key;
  Map<String, Content> sub = Map();
  Content(this.key);

  @override
  Content operator [](Object key) {
    return sub[key];
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
  Content remove(Object key) {
    return sub.remove(key);
  }
}

class TextContent extends Content {
  String text;
  TextContent(String key, this.text): super (key);
}

class ListContent extends Content {
  List<Content> list;
  ListContent (String key, this.list): super (key);
}

class TableContent extends Content {
  List<RowContent> rows;
  TableContent (String key, this.rows): super (key);
}

class RowContent extends Content {
  Map<String, Content> cols;
  RowContent (String key, this.cols): super (key);
}


///
/// content["name"] = TextContent("value");
/// content["posirtions"] = ListContent([TextContent("value"), TextContent("value"), TextContent("value")]);
/// 
///
///
///
class Doc {
  String id;
  Map<String, Content> elements;
}