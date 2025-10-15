// lib/report_service.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

class ReportService {
  Future<Uint8List> generateMemberReport(
    Map<String, dynamic> memberData,
    List<Map<String, dynamic>> paymentHistory,
  ) async {
    final pdf = pw.Document();

    // Load custom fonts
    final font = await PdfGoogleFonts.poppinsRegular();
    final boldFont = await PdfGoogleFonts.poppinsBold();
    final italicFont = await PdfGoogleFonts.poppinsItalic();

    final theme = pw.ThemeData.withFont(
      base: font,
      bold: boldFont,
      italic: italicFont,
    );

    // Load gym logo
    final logoImage = pw.MemoryImage(
      (await rootBundle.load('assets/logo_blue.png')).buffer.asUint8List(),
    );

    // Fetch member's avatar image
    pw.ImageProvider? memberImage;
    if (memberData['avatar_url'] != null &&
        memberData['avatar_url'].isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(memberData['avatar_url']));
        if (response.statusCode == 200) {
          memberImage = pw.MemoryImage(response.bodyBytes);
        }
      } catch (e) {
        if (kDebugMode) {
          print('Could not fetch member image: $e');
        }
      }
    }

    // Colors
    const primaryColor = PdfColor.fromInt(0xFF0077B6);
    const validColor = PdfColor.fromInt(0xFF2A9D8F);
    const lightGrey = PdfColor.fromInt(0xFFF2F2F2);
    const darkGrey = PdfColor.fromInt(0xFF333333);

    pdf.addPage(
      pw.Page(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Stack(
            children: [
              pw.Center(
                child: pw.Opacity(
                  opacity: 0.05,
                  child: pw.Image(logoImage, height: 400),
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildHeader(logoImage, primaryColor),
                  pw.SizedBox(height: 20),
                  _buildTitle('Member Report', primaryColor),
                  pw.SizedBox(height: 15),

                  // Membership Validity Banner
                  _buildValidityBanner(memberData, validColor),
                  pw.SizedBox(height: 15),

                  _buildMemberDetails(memberData, memberImage, lightGrey, darkGrey),
                  pw.SizedBox(height: 20),
                  
                  pw.Text('Payment History',
                      style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor)),
                  pw.SizedBox(height: 10),
                  _buildPaymentHistory(paymentHistory, primaryColor, lightGrey),
                  pw.Spacer(),
                  _buildFooter(darkGrey),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(pw.ImageProvider logo, PdfColor primaryColor) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Image(logo, height: 60),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('Luxury Gym',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 24,
                    color: primaryColor)),
            pw.Text('Fitness & Wellness Center',
                style: const pw.TextStyle(color: PdfColors.grey700)),
            pw.SizedBox(height: 5),
            pw.Text('Basement Iqra Mart Ikrampur Kharki',
                style: const pw.TextStyle(fontSize: 9)),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildTitle(String title, PdfColor primaryColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: primaryColor,
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Center(
        child: pw.Text(
          title,
          style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white),
        ),
      ),
    );
  }
  
  pw.Widget _buildValidityBanner(Map<String, dynamic> data, PdfColor validColor) {
    final dueDateString = data['fee_due_date'];
    String validityText = 'Membership validity not set';
    PdfColor bannerColor = PdfColors.grey500;

    if (dueDateString != null) {
      final dueDate = DateTime.parse(dueDateString);
      validityText = 'Membership Valid Till: ${DateFormat('dd MMMM, yyyy').format(dueDate)}';
      bannerColor = validColor;
    }

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      decoration: pw.BoxDecoration(
        color: bannerColor,
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Center(
        child: pw.Text(
          validityText,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 12),
        ),
      ),
    );
  }

  pw.Widget _buildMemberDetails(Map<String, dynamic> data,
      pw.ImageProvider? image, PdfColor bgColor, PdfColor textColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Serial #', data['serial_number'] ?? 'N/A'),
                _buildDetailRow('Name', data['name'] ?? 'N/A'),
                _buildDetailRow('Email', data['email'] ?? 'N/A'),
                _buildDetailRow('Phone', data['phone'] ?? 'N/A'),
                _buildDetailRow(
                    'Status', (data['status'] as String?)?.toUpperCase() ?? 'N/A'),
                _buildDetailRow(
                  'Fee Due Date',
                  data['fee_due_date'] != null
                      ? DateFormat('dd MMMM yyyy')
                          .format(DateTime.parse(data['fee_due_date']))
                      : 'N/A',
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 20),
          pw.Column(
            children: [
                 pw.ClipRRect(
                  horizontalRadius: 10,
                  verticalRadius: 10,
                  child: image != null
                      ? pw.Image(image, width: 100, height: 100, fit: pw.BoxFit.cover)
                      : pw.Container(
                          width: 100,
                          height: 100,
                          color: PdfColors.grey300,
                          child: pw.Center(
                              child: pw.Text('No Photo',
                                  style: const pw.TextStyle(color: PdfColors.grey700)))),
                ),
                pw.SizedBox(height: 10),
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: data['user_id'] ?? 'invalid-id',
                  width: 80,
                  height: 80,
                ),
                pw.Text('Member ID', style: const pw.TextStyle(fontSize: 8))
            ]
          )
        ],
      ),
    );
  }

  pw.Widget _buildDetailRow(String title, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 90,
            child:
                pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }

  pw.Widget _buildPaymentHistory(List<Map<String, dynamic>> history,
      PdfColor headerColor, PdfColor rowColor) {
    if (history.isEmpty) {
      return pw.Center(
          child: pw.Text('No payment history available.',
              style: const pw.TextStyle(fontSize: 16, color: PdfColors.grey)));
    }

    final headers = ['Date', 'Amount', 'Type', 'Method', 'Notes'];

    final data = history.map((payment) {
      return [
        DateFormat('dd MMM, yyyy').format(DateTime.parse(payment['payment_date'])),
        'PKR ${NumberFormat('#,##0').format(payment['amount'])}',
        (payment['payment_type'] as String?)?.replaceAll('_', ' ').split(' ').map((e) => e[0].toUpperCase() + e.substring(1)).join(' ') ?? 'N/A',
        (payment['payment_method'] as String?)?.toUpperCase() ?? 'N/A',
        payment['notes'] ?? '',
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: null,
      headerStyle:
          pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: pw.BoxDecoration(
        color: headerColor,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
        4: pw.Alignment.centerLeft,
      },
      rowDecoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: rowColor, width: 1.5)),
      ),
    );
  }

   pw.Widget _buildFooter(PdfColor textColor) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Generated on: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
            pw.Text('For questions, contact: +92 123 4567890',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
          ],
        )
      ],
    );
  }

  Future<void> shareReport(Uint8List pdfBytes, String memberName) async {
    final cleanName = memberName.replaceAll(' ', '_');
    if (kIsWeb) {
      final base64 = base64Encode(pdfBytes);
      final url = 'data:application/pdf;base64,$base64';
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } else {
      await Printing.sharePdf(
          bytes: pdfBytes, filename: '${cleanName}_report.pdf');
    }
  }
}

