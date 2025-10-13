enum RecommendationType { savings, investment, budgetAlert, goal, tip }

class Recommendation {
  final String title;
  final String description;
  final String actionLabel;
  final RecommendationType type;
  final String icon;

  const Recommendation({
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.type,
    this.icon = '💡',
  });
}
