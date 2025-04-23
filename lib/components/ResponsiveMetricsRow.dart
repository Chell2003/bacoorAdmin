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
            return _minimalistCard(key, value);
          },
        );
      },
    );
  }

  // 🟢 Minimalist Card (Big Icon Left, Text Right)
  Widget _minimalistCard(String title, int value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          // Left-Aligned Big Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIconForMetric(title),
              size: 56, // Bigger icon
              color: Colors.black87,
            ),
          ),

          // Right-Aligned Text (Number & Label)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _animatedNumber(value, Colors.black87),
              SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🎯 Smooth Number Animation
  Widget _animatedNumber(int value, Color color) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: Duration(seconds: 1),
      builder: (context, animatedValue, child) {
        return Text(
          animatedValue.toString(),
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: color),
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
