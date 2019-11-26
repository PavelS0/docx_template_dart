import 'dart:collection';

class Content extends MapBase<String, Content> {
  String key;
  Map<String, Content> sub;
  Content([this.key, this.sub]);

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
  
  add(Content c) {
    if(sub == null) {
      sub = Map();
    }
    sub[c.key] = c;
  }
}


class PlainContent extends Content {
  PlainContent(String key) : super (key, {});
}

class TextContent extends Content {
  String text;
  TextContent(String key, this.text): super (key, {});
}

class ListContent extends Content {
  List<Content> list;
  ListContent (String key, this.list): super (key, {});
}

class TableContent extends Content {
  List<RowContent> rows;
  TableContent (String key, this.rows): super (key, {});
  addRow(RowContent content) {
    if (rows == null) {
      rows = List();
    }
    rows.add(content);
  }
}

class RowContent extends Content {
  RowContent ([Map<String, Content> cols]): super ("", cols);
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