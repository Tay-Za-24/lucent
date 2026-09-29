import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/models.dart';
import '../data/store.dart';
import '../money.dart';
import '../theme.dart';

/// Gives every widget below it access to the [AppStore] and rebuilds
/// dependents when the store changes.
class StoreScope extends InheritedNotifier<AppStore> {
  const StoreScope({super.key, required AppStore store, required super.child})
    : super(notifier: store);

  static AppStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StoreScope>()!.notifier!;

  /// Access without subscribing to changes (for callbacks).
  static AppStore read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<StoreScope>()!.notifier!;
}

/// Amount with the currency symbol rendered at ~60% size in the secondary color.
class MoneyText extends StatelessWidget {
  const MoneyText(
    this.minor, {
    super.key,
    required this.style,
    this.plus = false,
    this.color,
    this.textAlign,
  });

  final int minor;
  final TextStyle style;
  final bool plus;
  final Color? color;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context);
    final c = context.colors;
    final base = style.copyWith(color: color ?? style.color);
    final big = (style.fontSize ?? 16) >= 28;
    final sign = minor < 0 ? minus : (plus ? '+' : '');
    final sym = s.currency;
    return Text.rich(
      TextSpan(
        children: [
          if (sign.isNotEmpty) TextSpan(text: sign),
          if (sym.isNotEmpty)
            TextSpan(
              text: '$sym${big ? '\u2009' : ' '}',
              style: big
                  ? base.copyWith(
                      fontSize: (style.fontSize ?? 16) * 0.6,
                      color: color ?? c.textSecondary,
                      letterSpacing: 0,
                    )
                  : null,
            ),
          TextSpan(text: formatNumber(minor, s.decimals)),
        ],
      ),
      style: base,
      textAlign: textAlign,
      maxLines: 1,
      softWrap: false,
      semanticsLabel: formatMoney(minor, sym, s.decimals, plus: plus),
    );
  }
}

/// Static month title, e.g. "September 2026".
class MonthTitle extends StatelessWidget {
  const MonthTitle({super.key, this.month});

  /// Defaults to the store's current month.
  final DateTime? month;

  @override
  Widget build(BuildContext context) {
    final m = month ?? StoreScope.of(context).month;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(DateFormat('MMMM yyyy').format(m), style: context.text.label),
    );
  }
}

/// 4pt flat progress bar: accent, caution at >=80%, "over" above 100%.
class BudgetBar extends StatelessWidget {
  const BudgetBar({super.key, required this.spent, required this.limit});
  final int spent;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ratio = limit <= 0 ? (spent > 0 ? 1.0 : 0.0) : spent / limit;
    final color = ratio > 1 ? c.over : (ratio >= 0.8 ? c.caution : c.accent);
    final reduce = MediaQuery.of(context).disableAnimations;
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        height: 4,
        child: ColoredBox(
          color: c.track,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: ratio.clamp(0.0, 1.0)),
            duration: reduce ? Duration.zero : const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            builder: (_, v, _) => FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: v,
              child: ColoredBox(color: color),
            ),
          ),
        ),
      ),
    );
  }
}

/// One budget: name and "spent of limit" on the left; "left / over" on the
/// right with a thin progress bar directly below it (unless [showBar] is off).
class BudgetRow extends StatelessWidget {
  const BudgetRow({super.key, required this.line, this.onTap, this.showBar = true});
  final BudgetLine line;
  final VoidCallback? onTap;
  final bool showBar;

  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context);
    final c = context.colors;
    final t = context.text;
    final limit = line.limit;
    String fmt(int v) => formatMoney(v, s.currency, s.decimals);
    final String? caption = limit != null
        ? '${fmt(line.spent)} of ${fmt(limit)} spent'
        : (line.spent > 0 ? '${fmt(line.spent)} spent' : null);
    final Widget status;
    if (limit == null) {
      status = Text('No limit', style: t.caption);
    } else {
      final over = line.left < 0;
      final label = over ? 'Over by ${fmt(-line.left)}' : '${fmt(line.left)} left';
      final style = over ? t.bodyAmount.copyWith(color: c.over) : t.bodyAmount;
      // The bar is exactly as wide as the "left" text above it.
      final width = (TextPainter(
        text: TextSpan(text: label, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout()).width;
      status = Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(label, style: style, maxLines: 1),
          if (showBar) ...[
            const SizedBox(height: 6),
            SizedBox(
              width: width,
              child: BudgetBar(spent: line.spent, limit: limit),
            ),
          ],
        ],
      );
    }
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.only(top: 7), child: CategoryDot(line.category)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(line.category.name, style: t.body),
                  if (caption != null) ...[
                    const SizedBox(height: 2),
                    Text(caption, style: t.caption),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            status,
          ],
        ),
      ),
    );
  }
}

class CategoryDot extends StatelessWidget {
  const CategoryDot(this.category, {super.key, this.size = 10});
  final Category? category;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: category == null
          ? context.colors.textTertiary
          : context.colors.category(category!.color),
      shape: BoxShape.circle,
    ),
  );
}

/// Hairline divider inset 16 from the leading edge.
class Hairline extends StatelessWidget {
  const Hairline({super.key, this.indent = 16});
  final double indent;
  @override
  Widget build(BuildContext context) => Divider(indent: indent, height: 1);
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 8, 8),
    child: Row(
      children: [
        Expanded(child: Text(text, style: context.text.title)),
        ?trailing,
      ],
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState(this.message, {super.key});
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
    child: Text(
      message,
      textAlign: TextAlign.center,
      style: context.text.body.copyWith(color: context.colors.textSecondary),
    ),
  );
}

/// Centers content at max 720 wide on large screens.
class MaxWidth extends StatelessWidget {
  const MaxWidth({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: child),
  );
}
