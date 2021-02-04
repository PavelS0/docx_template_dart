import 'dart:convert';
import 'package:archive/archive.dart';
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
    if (_index < 0) {
      arch.addFile(ArchiveFile(_name, data.length, data));
    } else {
      arch.files[_index] = ArchiveFile(_name, data.length, data);
    }
  }
}

class DocxXmlEntry extends DocxEntry {
  DocxXmlEntry();

  XmlDocument _doc;

  XmlDocument get doc => _doc;

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
      final data = doc.toXmlString(pretty: false);
      List<int> out = utf8.encode(data);
      _updateData(arch, out);
    }
  }
}

class DocxRel {
  DocxRel(this.id, this.type, this.target);
  final String id;
  final String type;
  final String target;
}

class DocxRelsEntry extends DocxXmlEntry {
  DocxRelsEntry();

  getRel(String id) {}

  @override
  void _load(Archive arch, String entryName) {
    super._load(arch, entryName);
  }
}

class DocxBinEntry extends DocxEntry {
  DocxBinEntry([this._data]);
  List<int> _data;
  List<int> get data => _data;

  @override
  void _load(Archive arch, String entryName) {
    _index = _getIndex(arch, entryName);
    if (_index > 0) {
      final f = arch.files[_index];
      _data = f.content as List<int>;
    }
  }

  @override
  void _updateArchive(Archive arch) {
    _updateData(arch, _data);
  }
}

class DocxManager {
  final Archive arch;
  final _map = <String, DocxEntry>{};

  DocxManager(this.arch);

  T getEntry<T extends DocxEntry>(T Function() creator, String name) {
    if (_map.containsKey(name)) {
      return _map[name] as T;
    } else {
      final T t = creator();
      t._load(arch, name);
      _map[name] = t;
      return t;
    }
  }

  void add(String name, DocxEntry e) {
    if (_map.containsKey(name))
      throw DocxEntryException('Entry already exists');
    else {
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
