import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/workout_program.dart';
import '../services/program_sharing_service.dart';
import 'program_detail_screen.dart';

/// Screen for importing a shared workout program
class ProgramImportScreen extends StatefulWidget {
  const ProgramImportScreen({super.key});

  @override
  State<ProgramImportScreen> createState() => _ProgramImportScreenState();
}

class _ProgramImportScreenState extends State<ProgramImportScreen> {
  final ProgramSharingService _sharingService = ProgramSharingService();
  final TextEditingController _dataController = TextEditingController();

  WorkoutProgram? _previewProgram;
  String? _validationError;
  bool _isValidating = false;
  bool _showScanner = false;

  @override
  void dispose() {
    _dataController.dispose();
    super.dispose();
  }

  Future<void> _validateAndPreview(String data) async {
    if (data.trim().isEmpty) {
      setState(() {
        _previewProgram = null;
        _validationError = null;
      });
      return;
    }

    setState(() {
      _isValidating = true;
      _validationError = null;
      _previewProgram = null;
    });

    try {
      final result = _sharingService.validateProgramData(data);

      setState(() {
        _isValidating = false;
        if (result.isValid) {
          _previewProgram = result.program;
          _validationError = null;
        } else {
          _previewProgram = null;
          _validationError = result.error;
        }
      });
    } catch (e) {
      setState(() {
        _isValidating = false;
        _validationError = 'Invalid program data';
        _previewProgram = null;
      });
    }
  }

  Future<void> _pasteFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text != null) {
        _dataController.text = clipboardData!.text!;
        _validateAndPreview(clipboardData.text!);
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

  Future<void> _importProgram() async {
    if (_previewProgram == null) return;

    try {
      final program =
          await _sharingService.importProgram(_dataController.text);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imported ${program.name}!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to program detail screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProgramDetailScreen(program: program),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error importing: $e'),
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
      _dataController.text = code;
      _validateAndPreview(code);
      setState(() => _showScanner = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Program'),
        actions: [
          IconButton(
            icon: Icon(_showScanner ? Icons.keyboard : Icons.qr_code_scanner),
            onPressed: _toggleScanner,
            tooltip: _showScanner ? 'Enter Code' : 'Scan QR Code',
          ),
        ],
      ),
      body: _showScanner ? _buildScanner() : _buildImportForm(),
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

  Widget _buildImportForm() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInputCard(),
        const SizedBox(height: 16),
        if (_isValidating) _buildValidatingCard(),
        if (_validationError != null) _buildErrorCard(),
        if (_previewProgram != null) ...[
          _buildPreviewCard(),
          const SizedBox(height: 16),
          _buildImportButton(),
        ],
        const SizedBox(height: 16),
        _buildInstructionsCard(),
      ],
    );
  }

  Widget _buildInputCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.input, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Program Data',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dataController,
              decoration: const InputDecoration(
                hintText: 'Paste program data here...',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              onChanged: _validateAndPreview,
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
                  child: OutlinedButton.icon(
                    onPressed: _toggleScanner,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan QR'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidatingCard() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Validating program data...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Invalid Data',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  Text(
                    _validationError ?? 'Unknown error',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    final program = _previewProgram!;

    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Valid Program Found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              program.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              program.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildInfoChip(
                    Icons.calendar_today, '${program.durationWeeks} weeks'),
                _buildInfoChip(
                    Icons.fitness_center, '${program.daysPerWeek} days/week'),
                _buildInfoChip(Icons.signal_cellular_alt, program.difficulty),
                _buildInfoChip(Icons.person, 'By ${program.author}'),
              ],
            ),
            if (program.goals.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: program.goals
                    .map((goal) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.green.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            goal,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImportButton() {
    return ElevatedButton.icon(
      onPressed: _importProgram,
      icon: const Icon(Icons.download),
      label: const Text('Import Program'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
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
                  'How to Import',
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
              'Get Program Data',
              'Ask someone to share their program via QR code or text',
            ),
            const SizedBox(height: 8),
            _buildInstructionStep(
              '2',
              'Scan or Paste',
              'Scan the QR code or paste the program data above',
            ),
            const SizedBox(height: 8),
            _buildInstructionStep(
              '3',
              'Review & Import',
              'Check the program details and tap Import',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep(String number, String title, String description) {
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

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade700),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
