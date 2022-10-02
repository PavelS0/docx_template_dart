import 'package:docx_template/docx_template.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ImagePdf', () {
    test('Compare', () {
      expect(
        ImagePdf(path: 'path', id: 'id'),
        ImagePdf(path: 'path', id: 'id'),
      );
    });
    test('Copywith', () {
      expect(
        ImagePdf(path: 'path', id: 'id').copywith(),
        ImagePdf(path: 'path', id: 'id'),
      );
    });
    test('Copywith path', () {
      expect(
        ImagePdf(path: 'path', id: 'id').copywith(path: 'newPath'),
        ImagePdf(path: 'newPath', id: 'id'),
      );
    });
    test('Copywith id', () {
      expect(
        ImagePdf(path: 'path', id: 'id').copywith(id: 'newId'),
        ImagePdf(path: 'path', id: 'newId'),
      );
    });
  });
}
