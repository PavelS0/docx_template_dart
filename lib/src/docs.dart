import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:xml/xml.dart';
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';
import 'dart:io';
import 'model.dart';
import 'visitor.dart';
import 'view.dart';

enum State { none, loaded, generated }

class DocxTemplate {
  XmlCopyVisitor visitor = XmlCopyVisitor();
  Directory _cacheDir = Directory("docx_cache");
  Directory _tmpDir;
  path.Context _tmpDirPath;
  State state = State.none;

  DocxTemplate([cacheDir]) {
    if (cacheDir != null) {
      _cacheDir = cacheDir;
    }
  }
  File f;
  List<int> compBytes;
  File template;

  Future<void> load(File f) async {
    if (!await _cacheDir.exists()) {
      _cacheDir.create();
    }
    if (await f.exists()) {
      var tmpDirName = md5
          .convert(
              utf8.encode(f.path) + [DateTime.now().millisecondsSinceEpoch])
          .toString();
      var cacheDirPath = path.Context(current: _cacheDir.path);
      _tmpDirPath = path.Context(current: cacheDirPath.absolute((tmpDirName)));
      _tmpDir = Directory(_tmpDirPath.current);
      if (!await _tmpDir.exists()) {
        _tmpDir.create();
      }

      compBytes = await f.readAsBytes();
      Archive archive = ZipDecoder().decodeBytes(compBytes);
      for (ArchiveFile file in archive) {
        String filename = file.name;
        if (file.isFile) {
          List<int> data = file.content;
          var nf = File(_tmpDirPath.absolute(filename));
          await nf.create(recursive: true);
          await nf.writeAsBytes(data);
        } else {
          var nd = Directory(_tmpDirPath.absolute(filename));
          await nd.create(recursive: true);
        }
      }
      state = State.loaded;
    } else {
      throw Exception("file not found");
    }
  }

  Future<void> generate(Content c) async {
    if (state != State.loaded) {
      throw Exception("Cannot generate docx, template not loaded");
    }
    template = File(_tmpDirPath.absolute("word", "document.xml"));
    if (await template.exists()) {
      XmlDocument doc = parse(await template.readAsString());
      var v = View.attchToDoc(doc);
      v.produce(c);
      String ermak = doc.toXmlString(pretty: false);
      await template.writeAsString(ermak);
      state = State.generated;
    }
  }

  Future<void> save(String filename, [cleanup = true]) async {
    if (state != State.generated) {
      throw Exception("Cannot save docx not generated");
    }
    var encoder = ZipFileEncoder();
    encoder.zipDirectory(_tmpDir, filename: filename);
    if (cleanup) {
      _tmpDir.delete(recursive: true);
      state = State.none;
    }
  }

  List<int> saveAsBytes([cleanup = true]) {
    if (state != State.generated) {
      throw Exception("Cannot save docx not generated");
    }
    Archive a = createArchiveFromDirectory(_tmpDir, includeDirName: false);
    if (cleanup) {
      _tmpDir.delete(recursive: true);
      state = State.none;
    }
    return ZipEncoder().encode(a);
  }
}
