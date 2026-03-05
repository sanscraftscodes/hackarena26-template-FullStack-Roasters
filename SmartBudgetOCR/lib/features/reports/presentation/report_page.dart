import 'package:flutter/material.dart';

/// Simple page with buttons to generate or download a report.
/// The actual API call is stubbed with TODOs.
class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  bool _loading = false;
  String? _message;

  Future<void> _generatePdf() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    // TODO: call GET /report and show success or error
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _loading = false;
      _message = 'Report generated (stub)';
    });
  }

  Future<void> _download() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    // TODO: handle actual download logic
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _loading = false;
      _message = 'Downloaded (stub)';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(_message!),
              ),
            ElevatedButton(
              onPressed: _loading ? null : _generatePdf,
              child: const Text('Generate PDF'),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _loading ? null : _download,
              child: const Text('Download Report'),
            ),
          ],
        ),
      ),
    );
  }
}
