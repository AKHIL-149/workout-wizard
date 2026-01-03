import 'package:flutter/material.dart';
import '../models/program_rating.dart';
import '../models/workout_program.dart';
import '../services/community_library_service.dart';
import '../services/custom_program_service.dart';
import '../services/program_library_service.dart';
import 'community_program_detail_screen.dart';
import 'program_rating_screen.dart';

/// Screen for browsing community-shared workout programs
class CommunityLibraryScreen extends StatefulWidget {
  const CommunityLibraryScreen({super.key});

  @override
  State<CommunityLibraryScreen> createState() => _CommunityLibraryScreenState();
}

class _CommunityLibraryScreenState extends State<CommunityLibraryScreen>
    with SingleTickerProviderStateMixin {
  final CommunityLibraryService _communityService = CommunityLibraryService();
  final CustomProgramService _customService = CustomProgramService();
  final ProgramLibraryService _libraryService = ProgramLibraryService();

  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<CommunityProgramMeta> _allPrograms = [];
  List<CommunityProgramMeta> _filteredPrograms = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadPrograms();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadPrograms() {
    setState(() {
      _allPrograms = _communityService.getAllCommunityPrograms();
      _applyFilters();
    });
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _applyFilters();
    });
  }

  void _applyFilters() {
    if (_searchQuery.isEmpty) {
      _filteredPrograms = List.from(_allPrograms);
    } else {
      _filteredPrograms = _communityService.searchPrograms(_searchQuery);
    }
  }

  WorkoutProgram? _getProgramById(String programId) {
    // Check custom programs first
    final customPrograms = _customService.getAllCustomPrograms();
    final custom = customPrograms.where((p) => p.id == programId).firstOrNull;
    if (custom != null) return custom;

    // Check library programs
    final libraryPrograms = _libraryService.getAllPrograms();
    return libraryPrograms.where((p) => p.id == programId).firstOrNull;
  }

  Future<void> _viewProgramDetail(CommunityProgramMeta meta) async {
    final program = _getProgramById(meta.programId);

    if (program == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Program not found. It may have been deleted.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommunityProgramDetailScreen(
          program: program,
          meta: meta,
        ),
      ),
    );

    if (result == true) {
      _loadPrograms();
    }
  }

  Future<void> _shareToLibrary() async {
    // Show dialog to select program to share
    final allPrograms = [
      ..._libraryService.getAllPrograms(),
      ..._customService.getAllCustomPrograms(),
    ];

    if (allPrograms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No programs available to share'),
        ),
      );
      return;
    }

    final selected = await showDialog<WorkoutProgram>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share to Community'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: allPrograms.length,
            itemBuilder: (context, index) {
              final program = allPrograms[index];
              return ListTile(
                title: Text(program.name),
                subtitle: Text(program.author),
                onTap: () => Navigator.pop(context, program),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selected == null || !mounted) return;

    try {
      await _communityService.addToCommunityLibrary(selected);
      _loadPrograms();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${selected.name} shared to community!'),
          backgroundColor: Colors.green,
        ),
      );
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
        title: const Text('Community Library'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Top Rated'),
            Tab(text: 'Popular'),
            Tab(text: 'Featured'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildStats(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProgramList(_filteredPrograms),
                _buildProgramList(_communityService.getTopRatedPrograms()),
                _buildProgramList(_communityService.getMostDownloadedPrograms()),
                _buildProgramList(_communityService.getFeaturedPrograms()),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _shareToLibrary,
        icon: const Icon(Icons.share),
        label: const Text('Share Program'),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search programs...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildStats() {
    final stats = _communityService.getCommunityStats();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatChip(
            Icons.fitness_center,
            '${stats['totalPrograms']} Programs',
          ),
          _buildStatChip(
            Icons.download,
            '${stats['totalDownloads']} Downloads',
          ),
          _buildStatChip(
            Icons.star,
            '${stats['averageRating'].toStringAsFixed(1)} Avg',
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).primaryColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramList(List<CommunityProgramMeta> programs) {
    if (programs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.folder_open,
                size: 80,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 24),
              Text(
                'No Programs Found',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Share your programs to get started!',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: programs.length,
      itemBuilder: (context, index) {
        final meta = programs[index];
        return _buildProgramCard(meta);
      },
    );
  }

  Widget _buildProgramCard(CommunityProgramMeta meta) {
    final program = _getProgramById(meta.programId);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _viewProgramDetail(meta),
        borderRadius: BorderRadius.circular(12),
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
                          meta.programName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'by ${meta.addedBy}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (meta.isFeatured)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 14, color: Colors.amber),
                          SizedBox(width: 4),
                          Text(
                            'Featured',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              if (program != null) ...[
                const SizedBox(height: 12),
                Text(
                  program.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildMetricChip(
                    Icons.star,
                    meta.ratingCount > 0
                        ? '${meta.averageRating.toStringAsFixed(1)} (${meta.ratingCount})'
                        : 'No ratings',
                    Colors.amber,
                  ),
                  _buildMetricChip(
                    Icons.download,
                    '${meta.downloadCount}',
                    Colors.blue,
                  ),
                  ...meta.topTags.map((tag) => _buildTagChip(tag)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
    );
  }
}
