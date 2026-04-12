import 'package:flutter/material.dart';
import '../models/schedule_block.dart';
import '../theme/app_theme.dart';

class ScheduleBlockCard extends StatelessWidget {
  final ScheduleBlock block;
  final VoidCallback onToggle;

  const ScheduleBlockCard({
    super.key,
    required this.block,
    required this.onToggle,
  });

  Color _fade(Color c) => Color.fromARGB(
    (c.alpha * 0.4).round(), c.red, c.green, c.blue);
  Color _fadeBg(Color c) => Color.fromARGB(
    (c.alpha * 0.5).round(), c.red, c.green, c.blue);

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.blockColor(block.type);
    final bgColor = AppTheme.blockBgColor(block.type);
    final effectiveColor = block.isCompleted ? _fade(color) : color;
    final effectiveBg = block.isCompleted ? _fadeBg(bgColor) : bgColor;

    return GestureDetector(
      onTap: block.isBreak ? null : onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: effectiveBg,
          borderRadius: BorderRadius.circular(14),
          border: Border(
            left: BorderSide(color: effectiveColor, width: 4),
            top: BorderSide(color: effectiveBg),
            right: BorderSide(color: effectiveBg),
            bottom: BorderSide(color: effectiveBg),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time
              SizedBox(
                width: 72,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(block.time,
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600, color: effectiveColor)),
                    Text(block.endTime,
                        style: TextStyle(
                            fontSize: 11,
                            color: block.isCompleted ? AppTheme.textMuted : AppTheme.textMuted)),
                    const SizedBox(height: 4),
                    Text(block.durationLabel,
                        style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w500, color: effectiveColor)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(
                          block.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: block.isCompleted ? AppTheme.textMuted : AppTheme.textPrimary,
                            decoration: block.isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      if (!block.isBreak) _TypeBadge(type: block.type),
                    ]),
                    if (block.note != null && block.note!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            block.isBreak ? Icons.coffee_outlined : Icons.lightbulb_outline_rounded,
                            size: 12,
                            color: block.isCompleted ? AppTheme.textMuted : AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              block.note!,
                              style: TextStyle(
                                fontSize: 12,
                                color: block.isCompleted ? AppTheme.textMuted : AppTheme.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (!block.isBreak) ...[
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: block.isCompleted ? color : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: block.isCompleted ? color : effectiveColor,
                      width: 2,
                    ),
                  ),
                  child: block.isCompleted
                      ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                      : null,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    if (type == 'break') return const SizedBox.shrink();
    final color = AppTheme.blockColor(type);
    final bg = AppTheme.blockBgColor(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        type[0].toUpperCase() + type.substring(1),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
