import 'dart:convert';
// REMOVED: Unnecessary import
// import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'main.dart';

class ReportService {
  // UNCHANGED: This function already uses MultiPage for long reports.
  Future<Uint8List> generateMemberReport(
    Map<String, dynamic> memberData,
    List<Map<String, dynamic>> paymentHistory,
  ) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.poppinsRegular();
    final boldFont = await PdfGoogleFonts.poppinsBold();
    // ADDED: Load Arabic font for your name
    final urduFont = await PdfGoogleFonts.notoNaskhArabicRegular();

    final theme = pw.ThemeData.withFont(
      base: font,
      bold: boldFont,
    );

    final logoImage = pw.MemoryImage(
      (await rootBundle.load('assets/logo_blue.png')).buffer.asUint8List(),
    );

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

    const primaryColor = PdfColor.fromInt(0xFF0D47A1); // Darker Blue for titles
    const accentColor =
        PdfColor.fromInt(0xFF1976D2); // Brighter Blue for accents
    const lightGrey = PdfColor.fromInt(0xFFF5F5F5);
    const darkGrey = PdfColor.fromInt(0xFF333333);

    final gymSettings = await _fetchGymSettings();
    // REMOVED: Call to _loadSignatureSvg

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        header: (context) => _buildHeader(logoImage, primaryColor, gymSettings),
        // MODIFIED: Pass urduFont to footer
        footer: (context) => _buildFooter(darkGrey, gymSettings, urduFont),
        build: (context) {
          return [
            // MODIFIED: Added space between header and content
            pw.SizedBox(height: 20),
            _buildTitle('Member Financial Report', accentColor),
            pw.SizedBox(height: 15),
            _buildValidityBanner(memberData, accentColor),
            pw.SizedBox(height: 15),
            _buildMemberDetails(memberData, memberImage, lightGrey, darkGrey),
            pw.SizedBox(height: 20),
            pw.Text('Payment History',
                style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryColor)),
            pw.SizedBox(height: 10),
            _buildPaymentHistory(paymentHistory, accentColor, lightGrey),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // MODIFIED: This function also has spacing added
  Future<Uint8List> generateWelcomePdf(Map<String, dynamic> memberData) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.poppinsRegular();
    final boldFont = await PdfGoogleFonts.poppinsBold();
    // ADDED: Load Arabic font for your name
    final urduFont = await PdfGoogleFonts.notoNaskhArabicRegular();

    final theme = pw.ThemeData.withFont(base: font, bold: boldFont);

    final logoImage = pw.MemoryImage(
      (await rootBundle.load('assets/logo_blue.png')).buffer.asUint8List(),
    );

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

    const primaryColor = PdfColor.fromInt(0xFF0D47A1);
    const accentColor = PdfColor.fromInt(0xFF1976D2);
    const lightGrey = PdfColor.fromInt(0xFFF8F9FA);
    const darkGrey = PdfColor.fromInt(0xFF333333);

    final gymSettings = await _fetchGymSettings();
    // REMOVED: Call to _loadSignatureSvg

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        header: (context) => _buildHeader(logoImage, primaryColor, gymSettings),
        // MODIFIED: Pass urduFont to footer
        footer: (context) => _buildFooter(darkGrey, gymSettings, urduFont),
        build: (context) {
          return [
            // MODIFIED: Added space between header and content
            pw.SizedBox(height: 20),
            _buildTitle(
                'Welcome to the Club, ${memberData['name'] ?? 'Member'}!',
                accentColor),
            pw.SizedBox(height: 20),
            _buildMemberDetails(memberData, memberImage, lightGrey, darkGrey),
            pw.SizedBox(height: 20),
            // MODIFIED: Pass accentColor to be used for the blue line
            _buildWelcomeDetails(accentColor),
          ];
        },
      ),
    );

    return pdf.save();
  }

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

  // REMOVED: _loadSignatureSvg function is no longer needed
  // Future<String?> _loadSignatureSvg() async { ... }

  pw.Widget _buildHeader(pw.ImageProvider logo, PdfColor primaryColor,
      Map<String, String> settings) {
    // This header is built by pw.MultiPage on every page
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

  pw.Widget _buildValidityBanner(Map<String, dynamic> data, PdfColor color) {
    final dueDateString = data['fee_due_date'];
    String validityText = 'Membership Validity: Not Set';
    PdfColor bannerColor = PdfColors.grey600;

    if (dueDateString != null) {
      final dueDate = DateTime.parse(dueDateString);
      validityText =
          'Membership Valid Until: ${DateFormat('dd MMMM, yyyy').format(dueDate)}';
      bannerColor = color;
    }

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      decoration: pw.BoxDecoration(
        color: bannerColor,
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Center(
        child: pw.Text(
          validityText,
          style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 12),
        ),
      ),
    );
  }

  pw.Widget _buildMemberDetails(Map<String, dynamic> data,
      pw.ImageProvider? image, PdfColor bgColor, PdfColor textColor) {
    final joinedDate = data['created_at'] != null
        ? DateFormat('dd MMMM, yyyy').format(DateTime.parse(data['created_at']))
        : 'N/A';
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColors.grey300, width: 1),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                    'Serial #', data['serial_number']?.toString() ?? 'N/A'),
                _buildDetailRow('Name', data['name'] ?? 'N/A'),
                _buildDetailRow('Email', data['email'] ?? 'N/A'),
                _buildDetailRow('Phone', data['phone'] ?? 'N/A'),
                _buildDetailRow('Joined On', joinedDate),
              ],
            ),
          ),
          pw.SizedBox(width: 20),
          pw.Column(children: [
            pw.ClipRRect(
              horizontalRadius: 10,
              verticalRadius: 10,
              child: image != null
                  ? pw.Image(image,
                      width: 100, height: 100, fit: pw.BoxFit.cover)
                  : pw.Container(
                      width: 100,
                      height: 100,
                      color: PdfColors.grey300,
                      child: pw.Center(
                          child: pw.Text('No Photo',
                              style: const pw.TextStyle(
                                  color: PdfColors.grey700)))),
            ),
            pw.SizedBox(height: 10),
            pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: data['user_id'] ?? 'invalid-id',
              width: 80,
              height: 80,
            ),
            pw.Text('Member ID', style: const pw.TextStyle(fontSize: 8))
          ])
        ],
      ),
    );
  }

  // MODIFIED: This function now passes the color to the list item builder
  pw.Widget _buildWelcomeDetails(PdfColor accentColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF8F9FA),
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColors.grey200, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Your Fitness Journey Starts Now!',
              style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: accentColor)), // Use accentColor for title
          pw.SizedBox(height: 10),
          pw.Text(
            "We're thrilled to have you join the Luxury Gym family. Your commitment to fitness is the first step towards a healthier, stronger you. Here’s some helpful information to get you started:",
            style: const pw.TextStyle(color: PdfColors.grey800, height: 1.5),
          ),
          pw.SizedBox(height: 15),
          // MODIFIED: Pass the accentColor to the item builder
          _buildWelcomeListItem(accentColor, 'Getting Started:',
              'Feel free to ask our staff for an overview of the gym layout. Our trainer is available to help you create a workout plan and guide you on using the equipment safely.'),
          _buildWelcomeListItem(accentColor, 'Meet Your Trainer:',
              'Our trainer is passionate about helping you achieve your goals. Feel free to ask for guidance or discuss setting up an introductory session.'),
          _buildWelcomeListItem(accentColor, 'Membership Policy:',
              "Life happens! If you plan to leave the gym or need to pause your membership for a month or longer, it's important to inform the admin, Fahad, in advance. This allows us to discuss potential arrangements for your return and helps you avoid having to pay a re-admission fee later on. Communicating beforehand ensures a smoother process when you're ready to come back."),
          _buildWelcomeListItem(accentColor, 'Gym Etiquette:',
              'Please help us keep the gym clean and welcoming for everyone. Return weights to their racks after use, and dispose of any wrappers or personal items properly in the designated bins. Let\'s work together to maintain a tidy environment.'),
          _buildWelcomeListItem(accentColor, 'Stay Consistent:',
              "The key to achieving your fitness goals is consistency. Show up, put in the effort, and trust the process. We're here to support you every step of the way! Celebrate your progress, stay motivated, and enjoy the journey."),
          _buildWelcomeListItem(accentColor, 'Member App:',
              "A dedicated mobile app for members is currently under development. It will offer features like workout tracking and gym updates. We'll let you know as soon as it's available!"),
          pw.SizedBox(height: 10),
          pw.Text(
            'If you have any questions at all, please don\'t hesitate to ask our front desk staff or the trainer.',
            style: const pw.TextStyle(color: PdfColors.grey800, height: 1.5),
          ),
        ],
      ),
    );
  }

  // MODIFIED: This widget now builds the blue line instead of the '✓'
  pw.Widget _buildWelcomeListItem(
      PdfColor iconColor, String title, String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // This is the new blue line, matching the HTML preview
          pw.Container(
            width: 4,
            height: 16,
            margin: const pw.EdgeInsets.only(right: 10, top: 4),
            decoration: pw.BoxDecoration(
              color: iconColor, // Use the passed-in accent color
              borderRadius: pw.BorderRadius.circular(2),
            ),
          ),
          pw.Expanded(
            child: pw.RichText(
              text: pw.TextSpan(
                children: [
                  pw.TextSpan(
                      text: '$title ',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.TextSpan(
                      text: text,
                      style: const pw.TextStyle(color: PdfColors.grey800)),
                ],
              ),
            ),
          ),
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
            child: pw.Text(title,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
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
        DateFormat('dd MMM, yyyy')
            .format(DateTime.parse(payment['payment_date'])),
        'PKR ${NumberFormat('#,##0').format(payment['amount'])}',
        (payment['payment_type'] as String?)
                ?.replaceAll('_', ' ')
                .split(' ')
                .map((e) => e[0].toUpperCase() + e.substring(1))
                .join(' ') ??
            'N/A',
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
        border: pw.Border(
            bottom: pw.BorderSide(color: PdfColors.grey300, width: 1.5)),
      ),
    );
  }

  // MODIFIED: Changed signature to accept urduFont
  pw.Widget _buildFooter(
      PdfColor textColor, Map<String, String> settings, pw.Font urduFont) {
    // This footer is built by pw.MultiPage on every page
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
                  // MODIFIED: Replaced 'Zaka' text with this Row
                  pw.Row(
                    children: [
                      pw.Text(
                        'Developed by: ',
                        style: pw.TextStyle(fontSize: 9, color: textColor),
                      ),
                      // FIXED: Wrapped the Urdu text in Directionality
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
