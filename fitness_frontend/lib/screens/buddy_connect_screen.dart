import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/workout_buddies_service.dart';

/// Screen for connecting with workout buddies via QR code
class BuddyConnectScreen extends StatefulWidget {
  const BuddyConnectScreen({super.key});

  @override
  State<BuddyConnectScreen> createState() => _BuddyConnectScreenState();
}

class _BuddyConnectScreenState extends State<BuddyConnectScreen> {
  final WorkoutBuddiesService _buddiesService = WorkoutBuddiesService();
  final TextEditingController _codeController = TextEditingController();

  bool _showScanner = false;
  bool _isLoading = true;
  String? _myConnectionCode;

  @override
  void initState() {
    super.initState();
    _generateConnectionCode();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _generateConnectionCode() async {
    setState(() => _isLoading = true);

    try {
      final code = _buddiesService.exportBuddyConnection();
      setState(() {
        _myConnectionCode = code;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating connection code: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _copyToClipboard() async {
    if (_myConnectionCode == null) return;

    try {
      await Clipboard.setData(ClipboardData(text: _myConnectionCode!));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connection code copied to clipboard!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error copying: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pasteFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text != null) {
        _codeController.text = clipboardData!.text!;
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error pasting: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _connectWithCode(String code) async {
    if (code.trim().isEmpty) return;

    try {
      final buddy = await _buddiesService.importBuddyConnection(code);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connected with ${buddy.displayName}!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      String errorMessage = 'Error connecting';
      if (e.toString().contains('buddy connection')) {
        errorMessage = 'Invalid connection code';
      } else if (e.toString().contains('profile')) {
        errorMessage = 'Invalid profile data';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$errorMessage: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleScanner() {
    setState(() => _showScanner = !_showScanner);
  }

  void _onQRCodeDetected(BarcodeCapture capture) {
    final String? code = capture.barcodes.firstOrNull?.rawValue;

    if (code != null && code.isNotEmpty) {
      setState(() => _showScanner = false);
      _connectWithCode(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Buddy'),
        actions: [
          IconButton(
            icon: Icon(_showScanner ? Icons.keyboard : Icons.qr_code_scanner),
            onPressed: _toggleScanner,
            tooltip: _showScanner ? 'Enter Code' : 'Scan QR Code',
          ),
        ],
      ),
      body: _showScanner ? _buildScanner() : _buildConnectionOptions(),
    );
  }

  Widget _buildScanner() {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              MobileScanner(
                onDetect: _onQRCodeDetected,
              ),
              Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).primaryColor,
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.black87,
          child: const Text(
            'Position the QR code within the frame',
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionOptions() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildShareSection(),
        const SizedBox(height: 24),
        _buildScanSection(),
        const SizedBox(height: 24),
        _buildInstructionsCard(),
      ],
    );
  }

  Widget _buildShareSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.share, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Share Your Code',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_myConnectionCode != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Center(
                  child: QrImageView(
                    data: _myConnectionCode!,
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Let your buddy scan this QR code',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _copyToClipboard,
                icon: const Icon(Icons.copy),
                label: const Text('Copy Connection Code'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScanSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.qr_code_scanner,
                    color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Connect with Buddy',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                hintText: 'Paste buddy\'s connection code here...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pasteFromClipboard,
                    icon: const Icon(Icons.paste),
                    label: const Text('Paste'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _toggleScanner,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan QR'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _connectWithCode(_codeController.text),
                icon: const Icon(Icons.person_add),
                label: const Text('Connect'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.help_outline, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'How to Connect',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInstructionStep(
              '1',
              'Share Your Code',
              'Show your QR code or send your connection code',
            ),
            const SizedBox(height: 8),
            _buildInstructionStep(
              '2',
              'Scan or Paste',
              'Scan your buddy\'s QR code or paste their connection code',
            ),
            const SizedBox(height: 8),
            _buildInstructionStep(
              '3',
              'Stay Connected',
              'Share progress updates and stay motivated together!',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep(
      String number, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
