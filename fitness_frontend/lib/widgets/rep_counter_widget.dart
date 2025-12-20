import 'package:flutter/material.dart';

/// Animated widget that displays current rep count
class RepCounterWidget extends StatefulWidget {
  final int repCount;
  final int? targetReps;
  final bool isActive;

  const RepCounterWidget({
    super.key,
    required this.repCount,
    this.targetReps,
    this.isActive = true,
  });

  @override
  State<RepCounterWidget> createState() => _RepCounterWidgetState();
}

class _RepCounterWidgetState extends State<RepCounterWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  int _previousRepCount = 0;

  @override
  void initState() {
    super.initState();
    _previousRepCount = widget.repCount;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(RepCounterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Trigger animation when rep count increases
    if (widget.repCount > _previousRepCount) {
      _controller.forward().then((_) => _controller.reverse());
      _previousRepCount = widget.repCount;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.targetReps != null
        ? (widget.repCount / widget.targetReps!).clamp(0.0, 1.0)
        : 0.0;

    final semanticsLabel = widget.targetReps != null
        ? '${widget.repCount} reps of ${widget.targetReps}'
        : '${widget.repCount} reps';

    return Semantics(
      label: semanticsLabel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.isActive
                      ? Colors.blue.withOpacity(0.9)
                      : Colors.grey.withOpacity(0.7),
                  widget.isActive
                      ? Colors.blue[700]!.withOpacity(0.9)
                      : Colors.grey[700]!.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Icon(
                  Icons.fitness_center,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 8),

                // Rep count
                Text(
                  '${widget.repCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                ),

                // Target reps
                if (widget.targetReps != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'of ${widget.targetReps}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress >= 1.0 ? Colors.green : Colors.white,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 4),
                  Text(
                    'REPS',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
      ),
    );
  }
}
