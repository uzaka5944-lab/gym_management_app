import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'main.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _isProcessing = false;

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
    });

    final String? memberId = capture.barcodes.first.rawValue;

    if (memberId == null || memberId.isEmpty) {
      _showFeedback('Invalid QR Code.', isError: true);
      return;
    }

    try {
      final memberProfile = await supabase
          .from('profiles')
          .select('id, full_name')
          .eq('id', memberId)
          .maybeSingle();

      if (memberProfile == null) {
        throw Exception('Member not found.');
      }

      await supabase.from('check_ins').insert({'member_id': memberId});

      final memberName = memberProfile['full_name'] ?? 'Member';
      _showFeedback('Welcome, $memberName! Check-in successful.',
          isError: false);
    } catch (e) {
      _showFeedback('Error: ${e.toString()}', isError: true);
    }
  }

  void _showFeedback(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Theme.of(context).colorScheme.error : Colors.green,
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Member QR Code')),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: _handleBarcode,
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border:
                    Border.all(color: Theme.of(context).primaryColor, width: 4),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (_isProcessing)
            Center(
                child: CircularProgressIndicator(
                    color: Theme.of(context).primaryColor)),
        ],
      ),
    );
  }
}
