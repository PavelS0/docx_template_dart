import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:xml/xml.dart';

class DocxEntryException implements Exception {
  DocxEntryException(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract class DocxEntry {
  DocxEntry();
  String _name = '';
  int _index = -1;
  void _load(Archive arch, String entryName);
  int _getIndex(Archive arch, String entryName) {
    return arch.files.indexWhere((element) => element.name == entryName);
  }

  void _updateArchive(Archive arch);

  void _updateData(Archive arch, List<int> data) {
    arch.addFile(ArchiveFile(_name, data.length, data));
  }
}

class DocxXmlEntry extends DocxEntry {
  DocxXmlEntry();

  XmlDocument? _doc;

  XmlDocument? get doc => _doc;

  @override
  void _load(Archive arch, String entryName) {
    _index = _getIndex(arch, entryName);
    if (_index > 0) {
      final f = arch.files[_index];
      final bytes = f.content as List<int>;
      final data = utf8.decode(bytes);
      _doc = XmlDocument.parse(data);
      _name = f.name;
    }
  }

  @override
  void _updateArchive(Archive arch) {
    if (doc != null) {
      final data = doc!.toXmlString(pretty: false);
      List<int> out = utf8.encode(data);
      _updateData(arch, out);
    }
  }
}

class DocxRel {
  DocxRel(this.id, this.type, this.target);
  final String id;
  final String type;
  String target;
}

class DocxRelsEntry extends DocxXmlEntry {
  DocxRelsEntry();
  late XmlElement _rels;
  int _id = 1000;
  int _imageId = 1000;

  String nextId() {
    _id++;
    return 'rId$_id';
  }

  String nextImageId() {
    return (_imageId++).toString();
  }

  DocxRel? getRel(String id) {
    final el = _rels.descendants.firstWhereOrNull((e) =>
        e is XmlElement &&
        e.name.local == 'Relationship' &&
        e.getAttribute('Id') == id);
    if (el != null) {
      final type = el.getAttribute('Type');
      final target = el.getAttribute('Target');
      if (type != null && target != null) {
        return DocxRel(id, type, target);
      }
    }
    return null;
  }

  void add(String id, DocxRel rel) {
    final n = _newRel(DocxRel(id, rel.type, rel.target));
    _rels.children.add(n);
  }

  void update(String id, DocxRel rel) {
    final el = _rels.descendants.firstWhereOrNull((e) =>
        e is XmlElement &&
        e.name.local == 'Relationship' &&
        e.getAttribute('Id') == id);
    if (el != null) {
      el.setAttribute('Type', rel.type);
      el.setAttribute('Target', rel.target);
    }
  }

  XmlElement _newRel(DocxRel rel) {
    final r = XmlElement(XmlName('Relationship'));
    r.attributes
      ..add(XmlAttribute(XmlName('Id'), rel.id))
      ..add(XmlAttribute(XmlName('Type'), rel.type))
      ..add(XmlAttribute(XmlName('Target'), rel.target));
    return r;
  }

  /* <Relationship Id="rId7" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/image2.jpeg"/> */

  @override
  void _load(Archive arch, String entryName) {
    super._load(arch, entryName);
    _rels = doc!.rootElement;
  }
}

class DocxBinEntry extends DocxEntry {
  DocxBinEntry([this._data]);
  List<int>? _data;
  List<int>? get data => _data;

  @override
  void _load(Archive arch, String entryName) {
    _index = _getIndex(arch, entryName);
    if (_index > 0) {
      final f = arch.files[_index];
      _data = f.content as List<int>?;
    }
  }

  @override
  void _updateArchive(Archive arch) {
    _updateData(arch, _data!);
  }
}

class DocxManager {
  final Archive arch;
  final _map = <String, DocxEntry>{};

  DocxManager(this.arch);

  T? getEntry<T extends DocxEntry>(T Function() creator, String name) {
    if (_map.containsKey(name)) {
      return _map[name] as T?;
    } else {
      final T t = creator();
      t._load(arch, name);
      _map[name] = t;
      return t;
    }
  }

  bool checkMapContainsKeys(String name) {
    if (!_map.containsKey(name)) {
      return true;
    }
    return false;
  }

  void add(String name, DocxEntry e) {
    if (_map.containsKey(name)) {
      // throw DocxEntryException('Entry already exists');
    } else {
      e._name = name;
      _map[name] = e;
    }
  }

  bool has(String name) {
    return _map.containsKey(name) ||
        arch.files.indexWhere((e) => e.name == name) > 0;
  }

  void put(String name, DocxEntry e) {
    if (!_map.containsKey(name)) {
      e._index = e._getIndex(arch, name);
    }

    e._name = name;
    _map[name] = e;
  }

  void updateArch() {
    _map.forEach((key, value) {
      value._updateArchive(arch);
    });
  }
}
