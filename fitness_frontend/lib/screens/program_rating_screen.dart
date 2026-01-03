import 'package:flutter/material.dart';
import '../models/program_rating.dart';
import '../models/workout_program.dart';
import '../services/community_library_service.dart';

/// Screen for rating and reviewing a workout program
class ProgramRatingScreen extends StatefulWidget {
  final WorkoutProgram program;
  final ProgramRating? existingRating;

  const ProgramRatingScreen({
    super.key,
    required this.program,
    this.existingRating,
  });

  @override
  State<ProgramRatingScreen> createState() => _ProgramRatingScreenState();
}

class _ProgramRatingScreenState extends State<ProgramRatingScreen> {
  final CommunityLibraryService _communityService = CommunityLibraryService();
  final TextEditingController _reviewController = TextEditingController();

  int _rating = 0;
  final Set<String> _selectedTags = {};

  final List<String> _availableTags = [
    'Effective',
    'Challenging',
    'Beginner Friendly',
    'Well Structured',
    'Great Results',
    'Easy to Follow',
    'Intense',
    'Good Progression',
    'Flexible Schedule',
    'Fun',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingRating != null) {
      _rating = widget.existingRating!.rating;
      _reviewController.text = widget.existingRating!.review ?? '';
      _selectedTags.addAll(widget.existingRating!.tags);
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await _communityService.rateProgram(
        programId: widget.program.id,
        programName: widget.program.name,
        rating: _rating,
        review: _reviewController.text.trim().isEmpty
            ? null
            : _reviewController.text.trim(),
        tags: _selectedTags.toList(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.existingRating != null
              ? 'Rating updated!'
              : 'Rating submitted!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingRating != null
            ? 'Edit Rating'
            : 'Rate Program'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProgramInfo(),
          const SizedBox(height: 24),
          _buildRatingSection(),
          const SizedBox(height: 24),
          _buildReviewSection(),
          const SizedBox(height: 24),
          _buildTagsSection(),
          const SizedBox(height: 24),
          _buildSubmitButton(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildProgramInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.program.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.program.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Your Rating',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starValue = index + 1;
                  return GestureDetector(
                    onTap: () => setState(() => _rating = starValue),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        _rating >= starValue ? Icons.star : Icons.star_border,
                        size: 48,
                        color: Colors.amber,
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                _getRatingText(_rating),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return 'Tap to rate';
    }
  }

  Widget _buildReviewSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.rate_review, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Your Review (Optional)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reviewController,
              decoration: const InputDecoration(
                hintText:
                    'Share your experience with this program...\n\nWhat did you like? What results did you see?',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              maxLength: 500,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.label, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Tags (Optional)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Select tags that describe this program',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableTags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                  selectedColor:
                      Theme.of(context).primaryColor.withValues(alpha: 0.3),
                  checkmarkColor: Theme.of(context).primaryColor,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton.icon(
      onPressed: _submitRating,
      icon: const Icon(Icons.send),
      label: Text(
          widget.existingRating != null ? 'Update Rating' : 'Submit Rating'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    );
  }
}
