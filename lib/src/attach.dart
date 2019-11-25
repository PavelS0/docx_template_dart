import 'core.dart';

void attachContent(List<Content> list, Map<String, BaseNode> node) 
  {
    for (Content c in list) {
     if (node.containsKey(c.key)) {
       if (c is TextContent) {
         assert(node[c.key] is TextNode);
       } else if (c is ListContent || c is TableContent) {
         assert(node[c.key] is TemplateNode);
         TemplateNode tn = node[c.key];
         tn.content = c;
         if (c.sub != null && tn.sub != null && tn.sub.isNotEmpty) {
           //attachContent(c.sub, tn.sub);
         }
       }
        node[c.key].content = c;
      }
    }
  }