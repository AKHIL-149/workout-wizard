import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/hybrid_recommender_service.dart';
import 'results_screen.dart';

class RecommendationFormScreen extends StatefulWidget {
  const RecommendationFormScreen({super.key});

  @override
  State<RecommendationFormScreen> createState() => _RecommendationFormScreenState();
}

class _RecommendationFormScreenState extends State<RecommendationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final HybridRecommenderService _recommenderService = HybridRecommenderService();
  
  // Form values
  String _fitnessLevel = 'Intermediate';
  final List<String> _selectedGoals = [];
  String _equipment = 'Full Gym';
  String? _duration;
  int? _frequency;
  String? _trainingStyle;
  
  bool _isLoading = false;

  Future<void> _getRecommendations() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedGoals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one fitness goal'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final profile = UserProfile(
        fitnessLevel: _fitnessLevel,
        goals: _selectedGoals,
        equipment: _equipment,
        preferredDuration: _duration,
        preferredFrequency: _frequency,
        preferredStyle: _trainingStyle,
      );

      // Use hybrid recommender (on-device primary, backend fallback)
      final result = await _recommenderService.getRecommendations(profile);

      if (!mounted) return;

      // Show info about recommendation source
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Text(result.sourceIcon),
              const SizedBox(width: 8),
              Expanded(child: Text(result.sourceDescription)),
            ],
          ),
          backgroundColor: result.isOffline ? Colors.orange : Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultsScreen(
            recommendations: result.recommendations,
            userProfile: profile,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Fitness Profile'),
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fitness Level
              Text(
                'Fitness Level',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _fitnessLevel,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.trending_up),
                ),
                items: Constants.fitnessLevels.map((level) {
                  return DropdownMenuItem(value: level, child: Text(level));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _fitnessLevel = value!;
                  });
                },
              ),
              
              const SizedBox(height: 24),
              
              // Goals
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Fitness Goals',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Select multiple',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: Constants.goalOptions.length,
                itemBuilder: (context, index) {
                  final goalOption = Constants.goalOptions[index];
                  final isSelected = _selectedGoals.contains(goalOption.name);

                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedGoals.remove(goalOption.name);
                        } else {
                          _selectedGoals.add(goalOption.name);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? goalOption.color : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? goalOption.color : Colors.grey[300]!,
                          width: 2,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: goalOption.color.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                Icon(
                                  goalOption.icon,
                                  color: isSelected ? Colors.white : goalOption.color,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    goalOption.name,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.black87,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check,
                                  size: 14,
                                  color: goalOption.color,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              // Equipment
              Text(
                'Available Equipment',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _equipment,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.fitness_center),
                ),
                items: Constants.equipment.map((eq) {
                  return DropdownMenuItem(value: eq, child: Text(eq));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _equipment = value!;
                  });
                },
              ),
              
              const SizedBox(height: 24),
              
              // Duration (Optional)
              Text(
                'Preferred Workout Duration (Optional)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _duration,
                hint: const Text('Select duration'),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.access_time),
                ),
                items: Constants.durations.map((dur) {
                  return DropdownMenuItem(value: dur, child: Text(dur));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _duration = value;
                  });
                },
              ),
              
              const SizedBox(height: 24),
              
              // Frequency (Optional)
              Text(
                'Workouts Per Week (Optional)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _frequency,
                hint: const Text('Select frequency'),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                items: List.generate(7, (i) => i + 1).map((freq) {
                  return DropdownMenuItem(
                    value: freq,
                    child: Text('$freq days/week'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _frequency = value;
                  });
                },
              ),
              
              const SizedBox(height: 24),
              
              // Training Style (Optional)
              Text(
                'Preferred Training Style (Optional)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _trainingStyle,
                hint: const Text('Select training style'),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.sports_gymnastics),
                ),
                items: Constants.trainingStyles.map((style) {
                  return DropdownMenuItem(value: style, child: Text(style));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _trainingStyle = value;
                  });
                },
              ),
              
              const SizedBox(height: 40),
              
              // Submit Button
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isLoading
                        ? [Colors.grey, Colors.grey.shade400]
                        : [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _isLoading
                      ? []
                      : [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isLoading ? null : _getRecommendations,
                    borderRadius: BorderRadius.circular(16),
                    child: Center(
                      child: _isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Analyzing your profile...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Get My Recommendations',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

