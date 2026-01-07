import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/export_config.dart';
import '../services/export_service.dart';
import 'export_history_screen.dart';

/// Screen for configuring and exporting workout data
class ExportSettingsScreen extends StatefulWidget {
  const ExportSettingsScreen({super.key});

  @override
  State<ExportSettingsScreen> createState() => _ExportSettingsScreenState();
}

class _ExportSettingsScreenState extends State<ExportSettingsScreen> {
  final ExportService _exportService = ExportService();
  final Uuid _uuid = const Uuid();

  String _exportType = 'csv';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _includeCharts = true;
  bool _includeStatistics = true;
  bool _isExporting = false;

  final Map<String, bool> _includedFields = {
    'date': true,
    'exercise': true,
    'sets': true,
    'reps': true,
    'weight': true,
    'volume': true,
    'duration': true,
    'calories': true,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Workout Data'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ExportHistoryScreen(),
                ),
              );
            },
            tooltip: 'Export history',
          ),
        ],
      ),
      body: _isExporting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 24),
                  Text('Generating export...'),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Export format
                Text(
                  'Export Format',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        title: const Text('CSV'),
                        subtitle: const Text('Spreadsheet format (Excel, Google Sheets)'),
                        value: 'csv',
                        groupValue: _exportType,
                        onChanged: (value) {
                          setState(() {
                            _exportType = value!;
                          });
                        },
                        secondary: const Icon(Icons.table_chart),
                      ),
                      const Divider(height: 1),
                      RadioListTile<String>(
                        title: const Text('PDF'),
                        subtitle: const Text('Printable report with charts and statistics'),
                        value: 'pdf',
                        groupValue: _exportType,
                        onChanged: (value) {
                          setState(() {
                            _exportType = value!;
                          });
                        },
                        secondary: const Icon(Icons.picture_as_pdf),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Date range
                Text(
                  'Date Range',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.calendar_today),
                        title: const Text('Start Date'),
                        subtitle: Text(DateFormat('MMM d, y').format(_startDate)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _selectStartDate(),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.event),
                        title: const Text('End Date'),
                        subtitle: Text(DateFormat('MMM d, y').format(_endDate)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _selectEndDate(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Quick date range buttons
                Wrap(
                  spacing: 8,
                  children: [
                    _buildDateRangeChip('Last 7 days', 7),
                    _buildDateRangeChip('Last 30 days', 30),
                    _buildDateRangeChip('Last 90 days', 90),
                    _buildDateRangeChip('All time', null),
                  ],
                ),
                const SizedBox(height: 24),

                // Included fields
                Text(
                  'Included Fields',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: _includedFields.keys.map((field) {
                      return CheckboxListTile(
                        title: Text(_getFieldLabel(field)),
                        value: _includedFields[field],
                        onChanged: (value) {
                          setState(() {
                            _includedFields[field] = value!;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // PDF options
                if (_exportType == 'pdf') ...[
                  Text(
                    'PDF Options',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Include Charts'),
                          subtitle: const Text('Add visual charts to the report'),
                          value: _includeCharts,
                          onChanged: (value) {
                            setState(() {
                              _includeCharts = value;
                            });
                          },
                          secondary: const Icon(Icons.bar_chart),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Include Statistics'),
                          subtitle: const Text('Add summary statistics page'),
                          value: _includeStatistics,
                          onChanged: (value) {
                            setState(() {
                              _includeStatistics = value;
                            });
                          },
                          secondary: const Icon(Icons.analytics),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Export button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _performExport,
                    icon: const Icon(Icons.download),
                    label: Text('Export as ${_exportType.toUpperCase()}'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDateRangeChip(String label, int? days) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        setState(() {
          _endDate = DateTime.now();
          if (days != null) {
            _startDate = _endDate.subtract(Duration(days: days));
          } else {
            // All time - get first workout date or default to 1 year ago
            _startDate = DateTime.now().subtract(const Duration(days: 365));
          }
        });
      },
    );
  }

  String _getFieldLabel(String field) {
    switch (field) {
      case 'date':
        return 'Date';
      case 'exercise':
        return 'Exercise Name';
      case 'sets':
        return 'Set Number';
      case 'reps':
        return 'Repetitions';
      case 'weight':
        return 'Weight';
      case 'volume':
        return 'Volume';
      case 'duration':
        return 'Duration';
      case 'calories':
        return 'Calories';
      default:
        return field;
    }
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: _endDate,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _performExport() async {
    setState(() {
      _isExporting = true;
    });

    try {
      // Build export config
      final config = ExportConfig(
        id: _uuid.v4(),
        exportType: _exportType,
        startDate: _startDate,
        endDate: _endDate,
        includedFields: _includedFields.entries
            .where((e) => e.value)
            .map((e) => e.key)
            .toList(),
        includeCharts: _includeCharts,
        includeStatistics: _includeStatistics,
        createdAt: DateTime.now(),
      );

      // Perform export
      String? filePath;
      if (_exportType == 'csv') {
        filePath = await _exportService.exportToCSV(config);
      } else {
        filePath = await _exportService.exportToPDF(config);
      }

      if (!mounted) return;

      if (filePath != null) {
        // Show success dialog with share option
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 12),
                Text('Export Successful'),
              ],
            ),
            content: Text(
              'Your workout data has been exported to ${_exportType.toUpperCase()}.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await _exportService.shareExport(filePath);
                },
                icon: const Icon(Icons.share),
                label: const Text('Share'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 12),
              Text('Export Failed'),
            ],
          ),
          content: Text('Error: $e'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }
}
