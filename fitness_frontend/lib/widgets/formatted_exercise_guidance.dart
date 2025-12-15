import 'package:flutter/material.dart';

/// Widget to display exercise guidance with proper formatting
class FormattedExerciseGuidance extends StatelessWidget {
  final String markdownText;

  const FormattedExerciseGuidance({
    super.key,
    required this.markdownText,
  });

  @override
  Widget build(BuildContext context) {
    if (markdownText.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'No specific exercise guidance available for this program. Follow the general workout structure and focus on proper form.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
      );
    }

    final sections = _parseMarkdown(markdownText);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections.map((section) => _buildSection(context, section)).toList(),
    );
  }

  List<_MarkdownSection> _parseMarkdown(String text) {
    final sections = <_MarkdownSection>[];
    final lines = text.split('\n');

    _MarkdownSection? currentSection;
    final List<String> currentItems = [];

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      // H2 header (## Title)
      if (line.startsWith('## ')) {
        // Save previous section
        if (currentSection != null) {
          currentSection.items.addAll(currentItems);
          sections.add(currentSection);
          currentItems.clear();
        }
        currentSection = _MarkdownSection(
          title: line.substring(3).trim(),
          level: 2,
          items: [],
        );
      }
      // H3 header (### Title)
      else if (line.startsWith('### ')) {
        // Save previous section
        if (currentSection != null) {
          currentSection.items.addAll(currentItems);
          sections.add(currentSection);
          currentItems.clear();
        }
        currentSection = _MarkdownSection(
          title: line.substring(4).trim(),
          level: 3,
          items: [],
        );
      }
      // H4 header (#### Title)
      else if (line.startsWith('#### ')) {
        // Save previous section
        if (currentSection != null) {
          currentSection.items.addAll(currentItems);
          sections.add(currentSection);
          currentItems.clear();
        }
        currentSection = _MarkdownSection(
          title: line.substring(5).trim(),
          level: 4,
          items: [],
        );
      }
      // List item (- Item or * Item)
      else if (line.startsWith('- ') || line.startsWith('* ')) {
        currentItems.add(line.substring(2).trim());
      }
      // Bold text (**text**)
      else if (line.startsWith('**') && line.endsWith('**')) {
        currentItems.add(line.substring(2, line.length - 2));
      }
      // Regular text
      else {
        currentItems.add(line);
      }
    }

    // Add last section
    if (currentSection != null) {
      currentSection.items.addAll(currentItems);
      sections.add(currentSection);
    }

    return sections;
  }

  Widget _buildSection(BuildContext context, _MarkdownSection section) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          _buildSectionHeader(context, section),
          const SizedBox(height: 8),

          // Section items
          ...section.items.map((item) => _buildListItem(item)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, _MarkdownSection section) {
    Color backgroundColor;
    Color textColor;
    double fontSize;
    IconData icon;

    switch (section.level) {
      case 2:
        backgroundColor = Theme.of(context).colorScheme.primary.withValues(alpha: 0.1);
        textColor = Theme.of(context).colorScheme.primary;
        fontSize = 18;
        icon = Icons.fitness_center;
        break;
      case 3:
        backgroundColor = Colors.orange.shade50;
        textColor = Colors.orange.shade900;
        fontSize = 16;
        icon = Icons.arrow_forward;
        break;
      case 4:
        backgroundColor = Colors.blue.shade50;
        textColor = Colors.blue.shade900;
        fontSize = 14;
        icon = Icons.subdirectory_arrow_right;
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.black87;
        fontSize = 14;
        icon = Icons.label;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: textColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: fontSize, color: textColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              section.title,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(String item) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 6, top: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: 8),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.green.shade600,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              item,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarkdownSection {
  final String title;
  final int level;
  final List<String> items;

  _MarkdownSection({
    required this.title,
    required this.level,
    required this.items,
  });
}
