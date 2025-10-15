// lib/report_service.dart

import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http; // Import the http package
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:html' as html;

class ReportService {
  Future<Uint8List> generateMemberReport(
    Map<String, dynamic> memberData,
    List<Map<String, dynamic>> paymentHistory,
  ) async {
    final pdf = pw.Document();
    final logo = pw.MemoryImage(
      (await rootBundle.load('assets/logo.png')).buffer.asUint8List(),
    );

    // --- NEW: Fetch the member's avatar image ---
    pw.ImageProvider? memberImage;
    if (memberData['avatar_url'] != null &&
        memberData['avatar_url'].isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(memberData['avatar_url']));
        if (response.statusCode == 200) {
          memberImage = pw.MemoryImage(response.bodyBytes);
        }
      } catch (e) {
        print('Could not fetch member image: $e');
      }
    }
    // --- END NEW ---

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          _buildHeader(logo, memberData),
          pw.SizedBox(height: 30),
          // MODIFIED: Pass the fetched image to the details section
          _buildMemberDetails(memberData, memberImage),
          pw.SizedBox(height: 20),
          _buildPaymentHistory(paymentHistory),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(pw.MemoryImage logo, Map<String, dynamic> memberData) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Member Report',
                style:
                    pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 5),
            pw.Text('Luxury Gym', style: const pw.TextStyle(fontSize: 18)),
          ],
        ),
        pw.Image(logo, height: 60),
      ],
    );
  }

  // MODIFIED: This widget now accepts an ImageProvider and uses a two-column layout
  pw.Widget _buildMemberDetails(
      Map<String, dynamic> memberData, pw.ImageProvider? memberImage) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Member Details',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.Divider(thickness: 1.5),
        pw.SizedBox(height: 10),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Column for member details
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                      'Serial #:', memberData['serial_number'] ?? 'N/A'),
                  _buildDetailRow('Name:', memberData['name'] ?? 'N/A'),
                  _buildDetailRow('Email:', memberData['email'] ?? 'N/A'),
                  _buildDetailRow('Phone:', memberData['phone'] ?? 'N/A'),
                  _buildDetailRow(
                      'Status:',
                      (memberData['status'] as String?)?.toUpperCase() ??
                          'N/A'),
                  _buildDetailRow(
                    'Fee Due Date:',
                    memberData['fee_due_date'] != null
                        ? DateFormat('dd MMM yyyy')
                            .format(DateTime.parse(memberData['fee_due_date']))
                        : 'N/A',
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 20),
            // Column for member photo
            if (memberImage != null)
              pw.Container(
                width: 100,
                height: 100,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey, width: 1),
                  image: pw.DecorationImage(
                    image: memberImage,
                    fit: pw.BoxFit.cover,
                  ),
                ),
              )
            else
              pw.Container(
                  width: 100,
                  height: 100,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey, width: 1),
                  ),
                  child: pw.Center(
                      child: pw.Text('No Photo',
                          style: const pw.TextStyle(color: PdfColors.grey)))),
          ],
        ),
      ],
    );
  }

  // Helper widget for a clean detail row
  pw.Widget _buildDetailRow(String title, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 90,
            child: pw.Text(title,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }

  // MODIFIED: Payment history table now includes a "Notes" column
  pw.Widget _buildPaymentHistory(List<Map<String, dynamic>> paymentHistory) {
    if (paymentHistory.isEmpty) {
      return pw.Text('No payment history available.',
          style: const pw.TextStyle(fontSize: 16));
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Payment History',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.Divider(thickness: 1.5),
        pw.Table.fromTextArray(
          cellAlignment: pw.Alignment.centerLeft,
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          headers: ['Date', 'Amount', 'Type', 'Method', 'Notes'],
          data: paymentHistory.map((payment) {
            return [
              DateFormat('dd MMM yyyy')
                  .format(DateTime.parse(payment['payment_date'])),
              'PKR ${payment['amount']}',
              payment['payment_type'] ?? '',
              payment['payment_method'] ?? '',
              payment['notes'] ?? '', // Add the notes field
            ];
          }).toList(),
        ),
      ],
    );
  }

  Future<void> shareReport(Uint8List pdfBytes, String memberName) async {
    if (kIsWeb) {
      final blob = html.Blob([pdfBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = '${memberName}_report.pdf';
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
    } else {
      await Printing.sharePdf(
          bytes: pdfBytes, filename: '${memberName}_report.pdf');
    }
  }
}
