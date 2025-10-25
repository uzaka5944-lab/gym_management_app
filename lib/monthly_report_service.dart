import 'dart:convert'; // Corrected import
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'main.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb

// Data class to hold all report data
class MonthlyReportData {
  final Map<String, double> summary;
  final int monthlyFeeCount;
  final int newAdmissionCount;
  final List<Map<String, dynamic>> payments;
  final double total;

  MonthlyReportData({
    required this.summary,
    required this.monthlyFeeCount,
    required this.newAdmissionCount,
    required this.payments,
    required this.total,
  });
}

class MonthlyReportService {
  Future<Uint8List> generateMonthlyFinancialReport(
    MonthlyReportData report,
    DateTime selectedDate,
  ) async {
    final pdf = pw.Document();

    // Load fonts
    final font = await PdfGoogleFonts.poppinsRegular();
    final boldFont = await PdfGoogleFonts.poppinsBold();
    final urduFont = await PdfGoogleFonts.notoNaskhArabicRegular();

    final theme = pw.ThemeData.withFont(
      base: font,
      bold: boldFont,
    );

    // Load assets
    final logoImage = pw.MemoryImage(
      (await rootBundle.load('assets/logo_blue.png')).buffer.asUint8List(),
    );

    const primaryColor = PdfColor.fromInt(0xFF0D47A1);
    const accentColor = PdfColor.fromInt(0xFF1976D2);
    const orangeColor = PdfColor.fromInt(0xFFFFA500);
    const darkGrey = PdfColor.fromInt(0xFF333333);

    // Fetch shared settings
    final gymSettings = await _fetchGymSettings();

    // Calculate standard admission fee from the report summary data
    final double standardAdmissionFee =
        report.summary['admission_fee_portion'] ?? 0;
    // REMOVED: Unused variable totalNewAdmissionAmount
    // REMOVED: Unused variable newAdmissionCount

    // Create list of data for the table
    final tableData = report.payments.map((p) {
      final memberName = p['profiles']?['full_name'] ?? 'N/A';
      // Safely access nested member data - assumes 'members' might be null or empty list
      final membersList = p['profiles']?['members'] as List?;
      String serialNumber = 'N/A';
      if (membersList != null && membersList.isNotEmpty) {
        final memberData = membersList.first as Map<String, dynamic>?;
        serialNumber = memberData?['serial_number'] ?? 'N/A';
      }

      final paymentType = (p['payment_type'] as String?)
              ?.replaceAll('_', ' ')
              .split(' ')
              .map((e) => e[0].toUpperCase() + e.substring(1))
              .join(' ') ??
          'N/A';

      String notes = p['notes'] ?? '';
      // Only add breakdown notes for new admissions
      if (p['payment_type'] == 'new_admission') {
        final double paymentAmount = (p['amount'] as num?)?.toDouble() ?? 0.0;
        double actualAdmissionFee = 0;
        double advanceFee = 0;

        // Use the standard admission fee passed in the report summary for calculation
        if (standardAdmissionFee > 0 && report.newAdmissionCount > 0) {
          // Calculate the fee portion per admission for this report
          double feePortionPerAdmission =
              standardAdmissionFee / report.newAdmissionCount;
          if (paymentAmount >= feePortionPerAdmission) {
            actualAdmissionFee = feePortionPerAdmission;
            advanceFee = paymentAmount - feePortionPerAdmission;
          } else {
            // Discount case: Fee is the whole amount
            actualAdmissionFee = paymentAmount;
            advanceFee = 0;
          }
        } else {
          // If standard fee is 0 or no admissions, consider the whole amount as advance
          advanceFee = paymentAmount;
        }

        notes =
            '(Fee: ${NumberFormat('#,##0').format(actualAdmissionFee)}, Adv: ${NumberFormat('#,##0').format(advanceFee)})';
      }

      return [
        DateFormat('dd MMM').format(DateTime.parse(p['payment_date'])),
        '$memberName (S.No: $serialNumber)',
        'PKR ${NumberFormat('#,##0').format(p['amount'])}',
        paymentType,
        (p['payment_method'] as String?)?.toUpperCase() ?? 'N/A',
        notes,
      ];
    }).toList();

    // Build the PDF
    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        header: (context) => _buildHeader(logoImage, primaryColor, gymSettings),
        footer: (context) => _buildFooter(darkGrey, gymSettings, urduFont),
        build: (context) {
          return [
            pw.SizedBox(height: 20),
            _buildTitle(
                'Monthly Report - ${DateFormat.yMMMM().format(selectedDate)}',
                accentColor),
            pw.SizedBox(height: 20),
            // Page 1 Content: Summary (No Chart)
            _buildSummaryCard(
                report, primaryColor, orangeColor), // Use primaryColor
            pw.SizedBox(height: 20),
            // Multi-page Content: Table
            _buildPaymentTable(tableData, accentColor),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // --- PDF WIDGET HELPERS ---

  pw.Widget _buildHeader(pw.ImageProvider logo, PdfColor primaryColor,
      Map<String, String> settings) {
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
            pw.Text(
                settings['gym_address'] ?? 'Basement Iqra Mart Ikrampur Kharki',
                style: const pw.TextStyle(fontSize: 9)),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildFooter(
      PdfColor textColor, Map<String, String> settings, pw.Font urduFont) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300, height: 20),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('GYM TIMINGS',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                          color: textColor)),
                  pw.SizedBox(height: 4),
                  pw.Text('Sat - Thu: ${settings['timings_sat_thu'] ?? 'N/A'}',
                      style: pw.TextStyle(fontSize: 9, color: textColor)),
                  pw.Text('Friday: ${settings['timings_fri'] ?? 'N/A'}',
                      style: pw.TextStyle(fontSize: 9, color: textColor)),
                  pw.Text('Sunday: ${settings['timings_sun'] ?? 'N/A'}',
                      style: pw.TextStyle(fontSize: 9, color: textColor)),
                ]),
            pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('CONTACT US',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                          color: textColor)),
                  pw.SizedBox(height: 4),
                  pw.Text('${settings['contact_phone'] ?? 'N/A'}',
                      style: pw.TextStyle(fontSize: 9, color: textColor)),
                  pw.Text('${settings['contact_email'] ?? 'N/A'}',
                      style: pw.TextStyle(fontSize: 9, color: textColor)),
                ]),
            pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("DEVELOPED BY",
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 10,
                          color: textColor)),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    children: [
                      pw.Text(
                        'Developed by: ',
                        style: pw.TextStyle(fontSize: 9, color: textColor),
                      ),
                      pw.Directionality(
                        textDirection: pw.TextDirection.rtl,
                        child: pw.Text(
                          'ذکاء',
                          style: pw.TextStyle(
                              font: urduFont, fontSize: 10, color: textColor),
                        ),
                      ),
                    ],
                  ),
                ]),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          'Generated on: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
        ),
      ],
    );
  }

  pw.Widget _buildTitle(String title, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Center(
        child: pw.Text(
          title,
          style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white),
        ),
      ),
    );
  }

  // MODIFIED: Removed PieChart, uses Row for legend layout
  pw.Widget _buildSummaryCard(
      MonthlyReportData report, PdfColor primary, PdfColor orange) {
    final currencyFormat = NumberFormat('#,##0');
    final monthlyFee = report.summary['monthly_fee']!;
    final newAdmissionFee = report.summary['new_admission']!;

    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey200),
        borderRadius: pw.BorderRadius.circular(16),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'Total Revenue: PKR ${currencyFormat.format(report.total)}',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 20),
          // Use Row for legend instead of PieChart + Legend structure
          pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: _buildAdmissionLegend(primary, 'Monthly Fee Payments:',
                      'PKR ${currencyFormat.format(monthlyFee)}'),
                ),
                pw.SizedBox(width: 20), // Add spacing between legends
                pw.Expanded(
                    child: _buildAdmissionLegend(
                        orange,
                        'New Admission Payments (Total):',
                        'PKR ${currencyFormat.format(newAdmissionFee)}',
                        subItems: [
                      // MODIFIED: Replaced ↳ with >
                      '> Fee Portion: PKR ${currencyFormat.format(report.summary['admission_fee_portion'])}',
                      '> Monthly Portion: PKR ${currencyFormat.format(report.summary['advance_monthly_portion'])}',
                    ])),
              ]),
        ],
      ),
    );
  }

  pw.Widget _buildAdmissionLegend(PdfColor color, String title, String value,
      {List<String>? subItems}) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 16,
          height: 16,
          decoration: pw.BoxDecoration(shape: pw.BoxShape.circle, color: color),
          margin: const pw.EdgeInsets.only(top: 4),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
            // Allow text to wrap if needed
            child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Text(title, style: const pw.TextStyle(fontSize: 11)),
            pw.Text(value,
                style:
                    pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            if (subItems != null)
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 8.0, top: 4),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: subItems
                      .map((item) => pw.Text(item,
                          style: const pw.TextStyle(
                              fontSize: 10, color: PdfColors.grey700)))
                      .toList(),
                ),
              ),
          ],
        )),
      ],
    );
  }

  pw.Widget _buildPaymentTable(List<List<String>> data, PdfColor headerColor) {
    final headers = [
      'Date',
      'Member (S.No)',
      'Amount',
      'Type',
      'Method',
      'Notes'
    ];

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: null,
      headerStyle: pw.TextStyle(
          fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
      headerDecoration: pw.BoxDecoration(
        color: headerColor,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.center,
        4: pw.Alignment.center,
        5: pw.Alignment.centerLeft,
      },
      columnWidths: {
        0: const pw.FlexColumnWidth(1.2),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.8),
        4: const pw.FlexColumnWidth(1.2),
        5: const pw.FlexColumnWidth(2.5),
      },
      rowDecoration: pw.BoxDecoration(
        border: pw.Border(
            bottom: pw.BorderSide(color: PdfColors.grey300, width: 1.5)),
      ),
    );
  }

  // --- GENERAL UTILITIES ---

  Future<Map<String, String>> _fetchGymSettings() async {
    try {
      final response = await supabase.from('gym_settings').select();
      final settings = {
        for (var item in response) item['id'] as String: item['value'] as String
      };
      return settings;
    } catch (e) {
      // Return default values if fetching fails
      return {
        'timings_sat_thu': '6:00 AM - 11:00 PM',
        'timings_fri': 'Closed',
        'timings_sun': '8:00 AM - 8:00 PM',
        'contact_phone': '+92 123 4567890',
        'contact_email': 'info@luxurygym.com',
        'gym_address': '123 Fitness Avenue, Your City'
      };
    }
  }

  Future<void> shareReport(Uint8List pdfBytes, String fileName) async {
    final cleanName = fileName.replaceAll(' ', '_');
    if (kIsWeb) {
      final base64 = base64Encode(pdfBytes); // Use base64Encode here
      final url = 'data:application/pdf;base64,$base64';
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } else {
      await Printing.sharePdf(bytes: pdfBytes, filename: '${cleanName}.pdf');
    }
  }
}
