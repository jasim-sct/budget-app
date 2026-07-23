/// Financial Savings Goal Model.
class GoalModel {
  final String id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final int targetDateMilliseconds;
  final String category;
  final String? accountId;
  final bool isCompleted;

  const GoalModel({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.targetDateMilliseconds,
    required this.category,
    this.accountId,
    this.isCompleted = false,
  });

  double get progressPercentage => (currentAmount / targetAmount).clamp(0.0, 1.0);
  double get remainingAmount => (targetAmount - currentAmount).clamp(0.0, double.infinity);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'target_date': targetDateMilliseconds,
      'category': category,
      'account_id': accountId,
      'is_completed': isCompleted ? 1 : 0,
    };
  }

  factory GoalModel.fromMap(Map<String, dynamic> map) {
    return GoalModel(
      id: map['id'] as String,
      title: map['title'] as String,
      targetAmount: (map['target_amount'] as num?)?.toDouble() ?? 0.0,
      currentAmount: (map['current_amount'] as num?)?.toDouble() ?? 0.0,
      targetDateMilliseconds: map['target_date'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      category: map['category'] as String? ?? 'Savings',
      accountId: map['account_id'] as String?,
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
    );
  }
}
