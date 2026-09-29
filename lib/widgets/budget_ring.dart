import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/store.dart';
import '../money.dart';
import '../theme.dart';
import 'common.dart';

/// Doughnut chart of this month's spending: one flat segment per expense
/// category (in its color), total spent in the hollow center, and a legend.
class BudgetRing extends StatelessWidget {
  const BudgetRing({super.key, required this.lines, required this.totalLimit});
  final List<BudgetLine> lines;

  /// Sum of limits set this month (0 = no limits).
  final int totalLimit;

  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context);
    final c = context.colors;
    final t = context.text;
    final spent = lines.where((l) => l.spent > 0).toList()
      ..sort((a, b) => b.spent.compareTo(a.spent));
    final total = spent.fold<int>(0, (a, l) => a + l.spent);
    String fmt(int v) => formatMoney(v, s.currency, s.decimals);
    final segments = [
      for (final l in spent) _Segment(l.spent / total, c.category(l.category.color)),
    ];
    final left = totalLimit - total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          Semantics(
            label:
                'Spent ${fmt(total)} this month'
                '${totalLimit > 0 ? ' of ${fmt(totalLimit)} budget' : ''}',
            child: SizedBox.square(
              dimension: 220,
              child: CustomPaint(
                painter: _RingPainter(segments, c.track),
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: ExcludeSemantics(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Spent', style: t.caption),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: MoneyText(total, style: t.headlineAmount),
                        ),
                        if (totalLimit > 0)
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              left >= 0 ? '${fmt(left)} left' : 'Over by ${fmt(-left)}',
                              style: t.caption.copyWith(color: left < 0 ? c.over : null),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (totalLimit > 0) ...[
            const SizedBox(height: 8),
            Text('of ${fmt(totalLimit)} budget', style: t.caption),
          ],
          const SizedBox(height: 16),
          if (spent.isEmpty)
            Text('Nothing spent yet this month.', style: t.caption)
          else
            for (final l in spent)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    CategoryDot(l.category),
                    const SizedBox(width: 8),
                    Expanded(child: Text(l.category.name, style: t.body)),
                    Text('${(l.spent * 100 / total).round()}%', style: t.caption),
                    const SizedBox(width: 12),
                    Text(fmt(l.spent), style: t.bodyAmount),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _Segment {
  const _Segment(this.fraction, this.color);
  final double fraction;
  final Color color;
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.segments, this.track);
  final List<_Segment> segments;
  final Color track;
  static const _stroke = 22.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.shortestSide / 2 - _stroke / 2,
    );
    Paint p(Color color) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..color = color;
    if (segments.isEmpty) {
      canvas.drawArc(rect, 0, 2 * math.pi, false, p(track));
      return;
    }
    // Small gap between segments so neighbours stay distinct.
    final gap = segments.length > 1 ? 0.03 : 0.0;
    var start = -math.pi / 2;
    for (final s in segments) {
      final sweep = s.fraction * 2 * math.pi;
      final visible = math.max(sweep - gap, 0.005);
      canvas.drawArc(rect, start + gap / 2, visible, false, p(s.color));
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.track != track ||
      old.segments.length != segments.length ||
      [
        for (var i = 0; i < segments.length; i++)
          old.segments[i].fraction != segments[i].fraction ||
              old.segments[i].color != segments[i].color,
      ].any((x) => x);
}
