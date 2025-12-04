import 'package:flutter/material.dart';
import '../models/recommendation.dart';
import '../models/user_profile.dart';

class ResultsScreen extends StatefulWidget {
  final List<Recommendation> recommendations;
  final UserProfile userProfile;

  const ResultsScreen({
    super.key,
    required this.recommendations,
    required this.userProfile,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  String _selectedFilter = 'All Programs';

  List<Recommendation> get _filteredRecommendations {
    switch (_selectedFilter) {
      case 'Perfect Match':
        return widget.recommendations.where((r) => r.matchPercentage == 100).toList();
      case 'High Match':
        return widget.recommendations.where((r) => r.matchPercentage >= 80).toList();
      case 'Beginner Friendly':
        return widget.recommendations.where((r) => r.primaryLevel == 'Beginner').toList();
      default:
        return widget.recommendations;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Recommendations'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Navigator.pop(context);
            },
            tooltip: 'Try again',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced Profile Summary Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Your Profile Summary',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Based on your preferences',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _ProfileTag(
                            icon: Icons.trending_up,
                            label: widget.userProfile.fitnessLevel,
                            color: Colors.blue.shade100,
                          ),
                          ...widget.userProfile.goals.take(3).map((goal) {
                            final goalOption = Constants.goalOptions.firstWhere(
                              (g) => g.name == goal,
                              orElse: () => Constants.goalOptions.first,
                            );
                            return _ProfileTag(
                              icon: goalOption.icon,
                              label: goal,
                              color: Colors.purple.shade100,
                            );
                          }),
                          _ProfileTag(
                            icon: Icons.fitness_center,
                            label: widget.userProfile.equipment,
                            color: Colors.green.shade100,
                          ),
                          if (widget.userProfile.preferredDuration != null)
                            _ProfileTag(
                              icon: Icons.access_time,
                              label: widget.userProfile.preferredDuration!,
                              color: Colors.orange.shade100,
                            ),
                          if (widget.userProfile.preferredFrequency != null)
                            _ProfileTag(
                              icon: Icons.calendar_today,
                              label: '${widget.userProfile.preferredFrequency}x/week',
                              color: Colors.pink.shade100,
                            ),
                        ],
                      ),
                      if (widget.userProfile.goals.length > 3) ...[
                        const SizedBox(height: 8),
                        Text(
                          '+${widget.userProfile.goals.length - 3} more goals',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Results Header
            Text(
              'Found ${_filteredRecommendations.length} Programs',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All Programs',
                    isSelected: _selectedFilter == 'All Programs',
                    onTap: () => setState(() => _selectedFilter = 'All Programs'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Perfect Match',
                    isSelected: _selectedFilter == 'Perfect Match',
                    onTap: () => setState(() => _selectedFilter = 'Perfect Match'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'High Match',
                    isSelected: _selectedFilter == 'High Match',
                    onTap: () => setState(() => _selectedFilter = 'High Match'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Beginner Friendly',
                    isSelected: _selectedFilter == 'Beginner Friendly',
                    onTap: () => setState(() => _selectedFilter = 'Beginner Friendly'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Recommendations List
            ..._filteredRecommendations.asMap().entries.map((entry) {
              final index = entry.key;
              final rec = entry.value;
              return ProgramCard(
                recommendation: rec,
                rank: index + 1,
                isFeatured: index == 0, // First result is featured
              );
            }),
          ],
        ),
      ),
    );
  }
}

class ProgramCard extends StatelessWidget {
  final Recommendation recommendation;
  final int rank;
  final bool isFeatured;

  const ProgramCard({
    super.key,
    required this.recommendation,
    required this.rank,
    this.isFeatured = false,
  });

  Color _getMatchColor(int percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Card(
            elevation: isFeatured ? 8 : 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: isFeatured
                  ? BorderSide(color: Colors.orange.shade700, width: 2)
                  : BorderSide.none,
            ),
            child: InkWell(
              onTap: () {
                _showProgramDetails(context);
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Rank and Match Score Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.secondary,
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '$rank',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${recommendation.matchPercentage}%',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: _getMatchColor(recommendation.matchPercentage),
                              ),
                            ),
                            Text(
                              'match',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Title
                    Text(
                      recommendation.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Description (if available)
                    if (recommendation.description != null) ...[
                      Text(
                        recommendation.description!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Highlights (if available)
                    if (recommendation.highlights != null && recommendation.highlights!.isNotEmpty) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: recommendation.highlights!.map((highlight) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              highlight,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Rating and User Count (if available)
                    if (recommendation.rating != null || recommendation.userCount != null) ...[
                      Row(
                        children: [
                          if (recommendation.rating != null) ...[
                            Icon(Icons.star, color: Colors.amber, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              recommendation.rating!.toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                          if (recommendation.userCount != null) ...[
                            Icon(Icons.people, color: Colors.grey[600], size: 18),
                            const SizedBox(width: 4),
                            Text(
                              '${recommendation.userCount} users',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Details Grid
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 12,
                        children: [
                          _DetailItem(
                            icon: Icons.signal_cellular_alt,
                            label: recommendation.primaryLevel,
                          ),
                          _DetailItem(
                            icon: Icons.flag,
                            label: recommendation.primaryGoal,
                          ),
                          _DetailItem(
                            icon: Icons.fitness_center,
                            label: recommendation.equipment,
                          ),
                          _DetailItem(
                            icon: Icons.access_time,
                            label: '${recommendation.timePerWorkout} min',
                          ),
                          _DetailItem(
                            icon: Icons.calendar_today,
                            label: '${recommendation.workoutFrequency}x/week',
                          ),
                          _DetailItem(
                            icon: Icons.event,
                            label: '${recommendation.programLength} weeks',
                          ),
                        ],
                      ),
                    ),

                    if (recommendation.trainingStyle != null) ...[
                      const SizedBox(height: 12),
                      Chip(
                        label: Text(recommendation.trainingStyle!),
                        avatar: const Icon(Icons.sports_gymnastics, size: 16),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              // TODO: Implement start program
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Start Program'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _showProgramDetails(context);
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('View Details'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Featured Badge
          if (isFeatured)
            Positioned(
              top: -8,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade700, Colors.orange.shade400],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Best Match',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showProgramDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(recommendation.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _DetailRow('Match', '${recommendation.matchPercentage}%'),
              _DetailRow('Level', recommendation.primaryLevel),
              _DetailRow('Goal', recommendation.primaryGoal),
              _DetailRow('Equipment', recommendation.equipment),
              _DetailRow('Duration', '${recommendation.timePerWorkout} min/workout'),
              _DetailRow('Frequency', '${recommendation.workoutFrequency} workouts/week'),
              _DetailRow('Program Length', '${recommendation.programLength} weeks'),
              if (recommendation.trainingStyle != null)
                _DetailRow('Training Style', recommendation.trainingStyle!),
              _DetailRow('Program ID', recommendation.programId),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailItem({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}

class _ProfileTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ProfileTag({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.black87),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

