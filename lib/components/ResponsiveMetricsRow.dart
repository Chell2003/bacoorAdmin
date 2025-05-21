import 'package:flutter/material.dart';

class ResponsiveMetricsRow extends StatelessWidget {
  final Map<String, int> dashboardMetrics;

  const ResponsiveMetricsRow({
    Key? key,
    required this.dashboardMetrics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: constraints.maxWidth > 900 ? 4 : 2, // Responsive layout
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 3.2, // Adjust height for better alignment
          ),
          itemCount: dashboardMetrics.length,
          itemBuilder: (context, index) {
            String key = dashboardMetrics.keys.elementAt(index);
            int value = dashboardMetrics[key]!;
            return _minimalistCard(context, key, value); // Pass context
          },
        );
      },
    );
  }

  // 🟢 Minimalist Card (Big Icon Left, Text Right)
  Widget _minimalistCard(BuildContext context, String title, int value) { // Added BuildContext
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface, // Updated color
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor), // Updated border color
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          // Left-Aligned Big Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest, // Updated icon background
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIconForMetric(title),
              size: 56, // Bigger icon
              color: Theme.of(context).colorScheme.onSurfaceVariant, // Updated icon color
            ),
          ),

          // Right-Aligned Text (Number & Label)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _animatedNumber(context, value, Theme.of(context).colorScheme.onSurface), // Pass context and updated color
              SizedBox(height: 6),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant), // Updated text style
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🎯 Smooth Number Animation
  Widget _animatedNumber(BuildContext context, int value, Color color) { // Added BuildContext, color is now explicitly passed
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: Duration(seconds: 1),
      builder: (context, animatedValue, child) {
        return Text(
          animatedValue.toString(),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith( // Using a theme style for consistency
                fontWeight: FontWeight.bold, 
                color: color // Use passed color
              ),
        );
      },
    );
  }

  // 🎨 Get Icon for Metric
  IconData _getIconForMetric(String metric) {
    switch (metric) {
      case 'Users': return Icons.person_outline;
      // case 'Posts': return Icons.post_add_outlined;
      case 'Places': return Icons.place_outlined;
      case 'Approved': return Icons.check_circle_outline; // ✅ New
      case 'Rejected': return Icons.cancel_outlined;      // ✅ New
      case 'For Review': return Icons.hourglass_empty;    // ✅ New
      default: return Icons.info_outline;
    }
  }

}
