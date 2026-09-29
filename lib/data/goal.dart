/// The book's monthly savings goal and how it is measured.
library;

enum GoalKind { amount, percent }

/// A monthly savings goal: a fixed amount (minor units) or a whole-number
/// percentage of the month's total income.
class SavingsGoal {
  const SavingsGoal(this.kind, this.value);
  final GoalKind kind;

  /// Minor units for [GoalKind.amount]; 1-100 for [GoalKind.percent].
  final int value;

  /// Target in minor units for a month with [income] (minor units).
  /// A percentage goal is rounded to the nearest minor unit, so it always
  /// matches the currency's decimal places. Zero income gives a zero target.
  int target(int income) => switch (kind) {
    GoalKind.amount => value,
    GoalKind.percent => income <= 0 ? 0 : (income * value + 50) ~/ 100,
  };

  @override
  bool operator ==(Object other) =>
      other is SavingsGoal && other.kind == kind && other.value == value;
  @override
  int get hashCode => Object.hash(kind, value);
}

/// Where a month stands against its goal. "Saved" is the month's net
/// (money in minus money out); it can be negative.
class GoalProgress {
  GoalProgress(this.goal, this.income, this.saved);
  final SavingsGoal goal;
  final int income;
  final int saved;

  int get target => goal.target(income);

  /// A percentage goal can't be worked out until some income is entered.
  bool get needsIncome => goal.kind == GoalKind.percent && income <= 0;
  bool get reached => !needsIncome && target > 0 && saved >= target;

  /// Still needed to reach the goal (0 when reached).
  int get toGo => needsIncome ? 0 : (target - saved).clamp(0, 1 << 62);

  /// 0..1 for the progress bar; a negative saved amount shows as empty.
  double get fraction {
    if (needsIncome || target <= 0) return 0;
    return (saved / target).clamp(0.0, 1.0);
  }
}
