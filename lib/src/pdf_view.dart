import 'dart:typed_data';

import 'package:docx_template/src/model.dart';
import 'package:pdf/widgets.dart' as pw;

abstract class PdfView<T extends Content?> {
  final String tag;
  final PdfView? parentView;
  final List<PdfView> childrenViews;

  PdfView(this.tag, this.parentView, this.childrenViews);

  pw.Widget produce(T content);
}

class PdfTextView extends PdfView<TextContent?> {
  PdfTextView(String tag, PdfView? parentView, List<PdfView> childrenViews)
      : super(tag, parentView, childrenViews);

  @override
  pw.Widget produce(TextContent? content) {
    if (content == null) return pw.Container();

    return pw.Text(
      content.text,
      style: pw.TextStyle(
        fontSize: 12,
        font: pw.Font.helvetica(),
      ),
    );
  }
}

class PdfImageView extends PdfView<ImageContent?> {
  PdfImageView(String tag, PdfView? parentView, List<PdfView> childrenViews)
      : super(tag, parentView, childrenViews);

  @override
  pw.Widget produce(ImageContent? content) {
    if (content == null || content.img == null) return pw.Container();

    return pw.Image(
      pw.MemoryImage(Uint8List.fromList(content.img!)),
      fit: pw.BoxFit.contain,
    );
  }
}

class PdfListView extends PdfView<ListContent?> {
  PdfListView(String tag, PdfView? parentView, List<PdfView> childrenViews)
      : super(tag, parentView, childrenViews);

  @override
  pw.Widget produce(ListContent? content) {
    if (content == null) return pw.Container();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: content.list.map((item) {
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Row(
            children: [
              pw.Text('• '),
              ...childrenViews.map((view) => view.produce(item)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class PdfRowView extends PdfView<TableContent?> {
  PdfRowView(String tag, PdfView? parentView, List<PdfView> childrenViews)
      : super(tag, parentView, childrenViews);

  @override
  pw.Widget produce(TableContent? content) {
    if (content == null) return pw.Container();

    return pw.Table(
      border: pw.TableBorder.all(),
      children: content.rows.map((row) {
        return pw.TableRow(
          children: childrenViews.map((view) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: view.produce(row),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}

class PdfPlainView extends PdfView<Content?> {
  PdfPlainView(String tag, PdfView? parentView, List<PdfView> childrenViews)
      : super(tag, parentView, childrenViews);

  @override
  pw.Widget produce(Content? content) {
    if (content == null) return pw.Container();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: childrenViews.map((view) {
        final childContent = content[view.tag];
        return view.produce(childContent);
      }).toList(),
    );
  }
}
