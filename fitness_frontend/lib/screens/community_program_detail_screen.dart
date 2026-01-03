import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/program_rating.dart';
import '../models/workout_program.dart';
import '../services/community_library_service.dart';
import '../services/custom_program_service.dart';
import 'program_rating_screen.dart';
import 'program_detail_screen.dart';

/// Screen for viewing community program details with ratings
class CommunityProgramDetailScreen extends StatefulWidget {
  final WorkoutProgram program;
  final CommunityProgramMeta meta;

  const CommunityProgramDetailScreen({
    super.key,
    required this.program,
    required this.meta,
  });

  @override
  State<CommunityProgramDetailScreen> createState() =>
      _CommunityProgramDetailScreenState();
}

class _CommunityProgramDetailScreenState
    extends State<CommunityProgramDetailScreen> {
  final CommunityLibraryService _communityService = CommunityLibraryService();
  final CustomProgramService _customService = CustomProgramService();

  List<ProgramRating> _ratings = [];
  ProgramRating? _userRating;

  @override
  void initState() {
    super.initState();
    _loadRatings();
  }

  void _loadRatings() {
    setState(() {
      _ratings = _communityService.getRatingsForProgram(widget.program.id);
      _userRating = _communityService.getUserRating(widget.program.id);
    });
  }

  Future<void> _rateProgram() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProgramRatingScreen(
          program: widget.program,
          existingRating: _userRating,
        ),
      ),
    );

    if (result == true) {
      _loadRatings();
      Navigator.pop(context, true); // Refresh parent
    }
  }

  Future<void> _downloadProgram() async {
    try {
      // Clone as custom program
      final cloned = await _customService.cloneProgram(
        widget.program,
        customName: '${widget.program.name} (Community)',
      );

      // Increment download count
      await _communityService.incrementDownloadCount(widget.program.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloaded ${widget.program.name}!'),
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

  void _viewFullProgram() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProgramDetailScreen(program: widget.program),
      ),
    );
  }

  Future<void> _markRatingHelpful(ProgramRating rating) async {
    await _communityService.markRatingHelpful(rating.id);
    _loadRatings();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Marked as helpful!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Program Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _viewFullProgram,
            tooltip: 'View Full Details',
          ),
        ],
      ),
      body: ListView(
        children: [
          _buildProgramHeader(),
          const SizedBox(height: 8),
          _buildStatsCard(),
          const SizedBox(height: 16),
          _buildRatingsSection(),
          const SizedBox(height: 80),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildProgramHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.1),
            Theme.of(context).primaryColor.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.program.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (widget.meta.isFeatured)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 16, color: Colors.amber),
                      SizedBox(width: 4),
                      Text(
                        'Featured',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'by ${widget.meta.addedBy}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.program.description,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildInfoChip(
                  Icons.calendar_today, '${widget.program.durationWeeks} weeks'),
              _buildInfoChip(
                  Icons.fitness_center, '${widget.program.daysPerWeek} days/week'),
              _buildInfoChip(Icons.signal_cellular_alt, widget.program.difficulty),
            ],
          ),
          if (widget.program.goals.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.program.goals
                  .map((goal) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .primaryColor
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          goal,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                Icons.star,
                widget.meta.ratingCount > 0
                    ? widget.meta.averageRating.toStringAsFixed(1)
                    : 'N/A',
                '${widget.meta.ratingCount} ratings',
                Colors.amber,
              ),
              _buildStatItem(
                Icons.download,
                '${widget.meta.downloadCount}',
                'downloads',
                Colors.blue,
              ),
              _buildStatItem(
                Icons.calendar_today,
                DateFormat('MMM d').format(widget.meta.addedAt),
                'added',
                Colors.green,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
      IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Ratings & Reviews',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _rateProgram,
                icon: Icon(_userRating != null ? Icons.edit : Icons.add),
                label: Text(_userRating != null ? 'Edit Rating' : 'Add Rating'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_ratings.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.rate_review_outlined,
                      size: 64,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No reviews yet',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Be the first to review this program!',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._ratings.map((rating) => _buildRatingCard(rating)),
        ],
      ),
    );
  }

  Widget _buildRatingCard(ProgramRating rating) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rating.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            return Icon(
                              index < rating.rating
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 16,
                              color: Colors.amber,
                            );
                          }),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('MMM d, y').format(rating.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (rating.review != null && rating.review!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                rating.review!,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
            if (rating.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: rating.tags
                    .map((tag) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _markRatingHelpful(rating),
                  icon: const Icon(Icons.thumb_up_outlined, size: 16),
                  label: Text('Helpful (${rating.helpfulCount})'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            OutlinedButton.icon(
              onPressed: _rateProgram,
              icon: const Icon(Icons.star_border),
              label: const Text('Rate'),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _downloadProgram,
                icon: const Icon(Icons.download),
                label: const Text('Download Program'),
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
}
