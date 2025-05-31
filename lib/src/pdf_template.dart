import 'package:docx_template/src/model.dart';
import 'package:docx_template/src/template.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:xml/xml.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'dart:convert';
import 'package:collection/collection.dart';

class PdfTemplate {
  final DocxTemplate docxTemplate;

  PdfTemplate(this.docxTemplate);

  Future<List<int>> generate() async {
    // Générer le DOCX avec un contenu vide
    final docxBytes = await docxTemplate.generate(Content('root'));
    if (docxBytes == null) throw Exception('Failed to generate DOCX');

    // Créer un fichier temporaire pour le DOCX
    final tempDocx = File('temp.docx');
    await tempDocx.writeAsBytes(docxBytes);

    // Lire le contenu du DOCX
    final docxContent = await _readDocxContent(tempDocx.path);

    // Nettoyer le fichier temporaire
    await tempDocx.delete();

    // Créer le PDF
    final pdf = pw.Document();

    // Ajouter une page avec le contenu
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // En-tête
                if (docxContent.header != null) ...[
                  pw.Container(
                    padding: const pw.EdgeInsets.only(bottom: 20),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        // Logo si présent
                        if (docxContent.headerImage != null)
                          pw.Image(
                            pw.MemoryImage(
                                Uint8List.fromList(docxContent.headerImage!)),
                            height: 50,
                            fit: pw.BoxFit.contain,
                          ),
                        // Texte de l'en-tête
                        if (docxContent.header != null)
                          pw.Text(
                            docxContent.header!,
                            style: pw.TextStyle(
                              fontSize: 16,
                              font: pw.Font.helveticaBold(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                // Contenu principal
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Titre du document
                      if (docxContent.title != null)
                        pw.Text(
                          docxContent.title!,
                          style: pw.TextStyle(
                            fontSize: 24,
                            font: pw.Font.helveticaBold(),
                          ),
                        ),
                      pw.SizedBox(height: 20),
                      // Liste des éléments
                      if (docxContent.items != null)
                        ...docxContent.items!.map((item) {
                          return pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 4),
                            child: pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('• '),
                                pw.Expanded(
                                  child: pw.Text(
                                    item,
                                    style: pw.TextStyle(
                                      fontSize: 12,
                                      font: pw.Font.helvetica(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
                // Pied de page
                if (docxContent.footer != null) ...[
                  pw.Container(
                    padding: const pw.EdgeInsets.only(top: 20),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Page ${context.pageNumber}',
                          style: pw.TextStyle(
                            fontSize: 10,
                            font: pw.Font.helvetica(),
                          ),
                        ),
                        pw.Text(
                          docxContent.footer!,
                          style: pw.TextStyle(
                            fontSize: 10,
                            font: pw.Font.helvetica(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<DocxContent> _readDocxContent(String filePath) async {
    // Lire le fichier DOCX
    final bytes = await File(filePath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    // Extraire les fichiers nécessaires
    final documentXml = archive.findFile('word/document.xml')?.content;
    final headerXml = archive.findFile('word/header1.xml')?.content;
    final headerImage = archive.findFile('word/media/image1.png')?.content;

    if (documentXml == null || headerXml == null) {
      throw Exception('Fichiers DOCX manquants');
    }

    // Parser le XML
    final document = XmlDocument.parse(utf8.decode(documentXml));
    final header = XmlDocument.parse(utf8.decode(headerXml));

    // Lire le contenu
    String? headerText;
    String? title;
    List<String> items = [];
    String? footer;

    // Lire le header
    final headerParagraphs = header.findAllElements('w:p');
    for (var p in headerParagraphs) {
  
      final sdt = p.findElements('w:sdt').firstOrNull;
      if (sdt != null) {
        final alias = sdt.findElements('w:alias').firstOrNull?.value;
        if (alias == 'header') {
          headerText = sdt.findElements('w:sdtContent').firstOrNull?.value;
          break;
        }
      }
    }

    // Lire le contenu principal
    final paragraphs = document.findAllElements('w:p');
    for (var p in paragraphs) {
      final text = p.findElements('w:t').map((t) => t.value).join();
      if (text.isEmpty) continue;

      // Chercher le titre (premier paragraphe non vide)
      if (title == null) {
        title = text;
        continue;
      }

      // Chercher les éléments de liste
      if (p.findElements('w:numPr').isNotEmpty) {
        items.add(text);
        continue;
      }

      // Chercher le footer (dernier paragraphe non vide)
      footer = text;
    }


    return DocxContent(
      header: headerText,
      title: title,
      items: items,
      footer: footer,
      headerImage: headerImage,
    );
  }
}

class DocxContent {
  final String? header;
  final String? title;
  final List<String>? items;
  final String? footer;
  final List<int>? headerImage;

  DocxContent({
    this.header,
    this.title,
    this.items,
    this.footer,
    this.headerImage,
  });
}
