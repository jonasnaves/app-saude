import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class PDFGenerator {
  /// Gera PDF da consulta com Resumo, Anamnese e Prescrição
  static Future<Uint8List> generateConsultationPDF({
    required String summary,
    required String anamnesis,
    String? prescription,
    String? consultationId,
  }) async {
    final pdf = pw.Document();

    // Formatar data e hora
    final now = DateTime.now();
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // Cabeçalho
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'PRONTUÁRIO MÉDICO',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Data: ${dateFormat.format(now)} | Hora: ${timeFormat.format(now)}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      if (consultationId != null)
                        pw.Text(
                          'ID: $consultationId',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Resumo Clínico
            if (summary.isNotEmpty) ...[
              pw.Header(
                level: 1,
                child: pw.Text(
                  'RESUMO CLÍNICO',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Paragraph(
                text: summary,
                style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5),
              ),
              pw.SizedBox(height: 20),
            ],

            // Anamnese
            if (anamnesis.isNotEmpty) ...[
              pw.Header(
                level: 1,
                child: pw.Text(
                  'ANAMNESE',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Paragraph(
                text: anamnesis,
                style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5),
              ),
              pw.SizedBox(height: 20),
            ],

            // Prescrição
            if (prescription != null && prescription.isNotEmpty) ...[
              pw.Header(
                level: 1,
                child: pw.Text(
                  'PRESCRIÇÃO',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Paragraph(
                text: prescription,
                style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.5),
              ),
              pw.SizedBox(height: 20),
            ],

            // Rodapé
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Text(
              'Documento gerado automaticamente pelo Assistente Médico Inteligente',
              style: pw.TextStyle(
                fontSize: 9,
                fontStyle: pw.FontStyle.italic,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }
}


