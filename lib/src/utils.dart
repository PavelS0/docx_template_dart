import 'package:xml/xml.dart';

replace(XmlNode which, XmlNode onWhich) {
    // TODO: Use ReplaceRange..
     var siblings = which.parent.children; 
    if (onWhich != null) 
    {
      int index = siblings.indexOf(which);
      siblings.insert(index, onWhich);
      siblings.remove(which);
      siblings.forEach((f)=>print(f.toXmlString()));
    } else {
      siblings.remove(which);
    }
  }
  replaceAll(XmlNode which, List<XmlNode> onWhich) {
   // TODO: Use ReplaceRange..
    var siblings = which.parent.children; 
    if (onWhich != null) 
    {
      int index = siblings.indexOf(which);
      siblings.insertAll(index, onWhich);
      siblings.remove(which);
      siblings.forEach((f)=>print(f.toXmlString()));
    } else {
      siblings.remove(which);
    }
  }

  copyAndReplace(){}
  