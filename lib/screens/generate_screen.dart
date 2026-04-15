import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/schedule_provider.dart';
import '../theme/app_theme.dart';

class GenerateSheet extends StatefulWidget {
  final VoidCallback onGenerated;
  const GenerateSheet({super.key, required this.onGenerated});

  @override
  State<GenerateSheet> createState() => _GenerateSheetState();
}

class _GenerateSheetState extends State<GenerateSheet> {
  final _promptCtrl = TextEditingController();
  String _startTime = '09:00 AM';
  String _endTime = '06:00 PM';
  int _breakDuration = 30;
  bool _useTaskList = false;

  static const _suggestions = [
    ('Daily work schedule', Icons.work_outline_rounded),
    ('Student study plan', Icons.school_outlined),
    ('School day schedule', Icons.class_outlined),
    ('Morning routine', Icons.wb_sunny_outlined),
    ('Exam week study', Icons.menu_book_outlined),
    ('Weekend activities', Icons.weekend_outlined),
    ('Weekly planner', Icons.date_range_outlined),
    ('Freelancer workday', Icons.laptop_outlined),
  ];

  @override
  void initState() {
    super.initState();
    final provider = context.read<ScheduleProvider>();
    _startTime = provider.startTime;
    _endTime = provider.endTime;
    _breakDuration = provider.breakDuration;
    _useTaskList = provider.tasks.isNotEmpty;
  }

  @override
  void dispose() {
    _promptCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final provider = context.read<ScheduleProvider>();
    if (_useTaskList && provider.tasks.isNotEmpty) {
      await provider.generateSchedule();
    } else {
      final prompt = _promptCtrl.text.trim();
      if (prompt.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please enter a prompt or select a suggestion')),
        );
        return;
      }
      await provider.generateFromPrompt(
        prompt: prompt,
        startTime: _startTime,
        endTime: _endTime,
        breakDuration: _breakDuration,
      );
    }

    if (!mounted) return;
    if (provider.status == ScheduleStatus.success) {
      Navigator.pop(context);
      widget.onGenerated();
    } else if (provider.status == ScheduleStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScheduleProvider>();
    final hasTasks = provider.tasks.isNotEmpty;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Schedule Generator',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Describe your day, AI builds your schedule',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  // Mode selector (if user has tasks)
                  if (hasTasks) ...[
                    _ModeSelector(
                      useTaskList: _useTaskList,
                      onChanged: (v) => setState(() => _useTaskList = v),
                      taskCount: provider.tasks.length,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Prompt input (shown when NOT using task list)
                  if (!_useTaskList || !hasTasks) ...[
                    // Suggestions
                    const Text(
                      'QUICK SUGGESTIONS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _suggestions.map((s) {
                        return _SuggestionChip(
                          label: s.$1,
                          icon: s.$2,
                          onTap: () =>
                              setState(() => _promptCtrl.text = s.$1),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Prompt field
                    const Text(
                      'OR DESCRIBE YOUR SCHEDULE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: TextField(
                        controller: _promptCtrl,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'e.g. "Study schedule for final exams this week" or "Work day with deep focus blocks"',
                          hintStyle: const TextStyle(
                              fontSize: 13, color: AppTheme.textMuted),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(
                                left: 14, right: 10, top: 14),
                            child: Icon(Icons.edit_outlined,
                                color: AppTheme.primary, size: 18),
                          ),
                          prefixIconConstraints:
                              const BoxConstraints(minWidth: 0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Time settings
                  const Text(
                    'TIME WINDOW',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Start time',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary)),
                              const SizedBox(height: 6),
                              _TimeButton(
                                time: _startTime,
                                onChanged: (t) =>
                                    setState(() => _startTime = t),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.arrow_forward_rounded,
                            color: AppTheme.textMuted, size: 16),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('End time',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary)),
                              const SizedBox(height: 6),
                              _TimeButton(
                                time: _endTime,
                                onChanged: (t) =>
                                    setState(() => _endTime = t),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Break preference
                  const Text(
                    'BREAK PREFERENCE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _BreakSelector(
                    selected: _breakDuration,
                    onChanged: (v) => setState(() => _breakDuration = v),
                  ),
                  const SizedBox(height: 28),

                  // Generate button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: provider.isLoading ? null : _generate,
                      icon: provider.isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white)),
                            )
                          : const Icon(Icons.auto_awesome_rounded, size: 18),
                      label: Text(provider.isLoading
                          ? 'Generating...'
                          : 'Generate Schedule'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),

                  if (!provider.apiKey.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0x1AEF9F27),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded,
                              color: AppTheme.warning, size: 14),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No API key set — using offline templates. Add your Anthropic key in Settings for AI-powered schedules.',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  final bool useTaskList;
  final ValueChanged<bool> onChanged;
  final int taskCount;

  const _ModeSelector({
    required this.useTaskList,
    required this.onChanged,
    required this.taskCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.borderColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _ModeOption(
            label: 'From prompt',
            icon: Icons.edit_outlined,
            selected: !useTaskList,
            onTap: () => onChanged(false),
          ),
          _ModeOption(
            label: 'From tasks ($taskCount)',
            icon: Icons.checklist_rounded,
            selected: useTaskList,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 14,
                  color: selected
                      ? AppTheme.primary
                      : AppTheme.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? AppTheme.primary
                      : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SuggestionChip(
      {required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppTheme.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  final String time;
  final ValueChanged<String> onChanged;
  const _TimeButton({required this.time, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final parts = time.split(' ');
        final tp = parts[0].split(':');
        int h = int.parse(tp[0]);
        final m = int.parse(tp[1]);
        final isPm = parts.length > 1 && parts[1] == 'PM';
        if (isPm && h != 12) h += 12;
        if (!isPm && h == 12) h = 0;
        final result = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: h, minute: m),
        );
        if (result != null) {
          final hh =
              result.hourOfPeriod == 0 ? 12 : result.hourOfPeriod;
          final ampm =
              result.period == DayPeriod.am ? 'AM' : 'PM';
          onChanged(
              '$hh:${result.minute.toString().padLeft(2, '0')} $ampm');
        }
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0x106C5CE7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0x336C5CE7)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(time,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary)),
            const Icon(Icons.edit_rounded,
                size: 14, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }
}

class _BreakSelector extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;
  const _BreakSelector(
      {required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final options = [
      (0, 'No breaks'),
      (10, '10 min'),
      (15, '15 min'),
      (30, '30 min'),
    ];
    return Row(
      children: options.map((o) {
        final isSelected = o.$1 == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(o.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: EdgeInsets.only(
                  right: o.$1 == 30 ? 0 : 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primary
                    : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primary
                      : AppTheme.borderColor,
                ),
              ),
              child: Text(
                o.$2,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : AppTheme.textSecondary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}