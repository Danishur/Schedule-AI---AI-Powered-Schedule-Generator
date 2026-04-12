import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../services/schedule_provider.dart';
import '../theme/app_theme.dart';

class AddTaskScreen extends StatefulWidget {
  final Task? task;
  const AddTaskScreen({super.key, this.task});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _durationCtrl;
  late final TextEditingController _deadlineCtrl;
  late final TextEditingController _notesCtrl;
  late String _priority;
  late int _durationSlider;

  bool get isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.task?.name ?? '');
    _durationCtrl = TextEditingController(
        text: (widget.task?.duration ?? 60).toString());
    _deadlineCtrl = TextEditingController(text: widget.task?.deadline ?? '');
    _notesCtrl = TextEditingController(text: widget.task?.notes ?? '');
    _priority = widget.task?.priority ?? 'medium';
    _durationSlider = widget.task?.duration ?? 60;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _durationCtrl.dispose();
    _deadlineCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<ScheduleProvider>();
    final duration = int.tryParse(_durationCtrl.text) ?? 60;

    if (isEditing) {
      provider.updateTask(widget.task!.copyWith(
        name: _nameCtrl.text.trim(),
        duration: duration,
        priority: _priority,
        deadline: _deadlineCtrl.text.trim().isEmpty
            ? null
            : _deadlineCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      ));
    } else {
      provider.addTask(Task(
        name: _nameCtrl.text.trim(),
        duration: duration,
        priority: _priority,
        deadline: _deadlineCtrl.text.trim().isEmpty
            ? null
            : _deadlineCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      ));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Task' : 'New Task'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              isEditing ? 'Save' : 'Add',
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Task name
            _SectionLabel(label: 'Task name'),
            TextFormField(
              controller: _nameCtrl,
              autofocus: !isEditing,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'e.g., Write project proposal',
                prefixIcon: Icon(Icons.task_alt_rounded, color: AppTheme.primary),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Please enter a task name' : null,
            ),
            const SizedBox(height: 24),

            // Duration
            _SectionLabel(label: 'Duration'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined,
                          color: AppTheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _formatDuration(_durationSlider),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 72,
                        child: TextFormField(
                          controller: _durationCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            suffixText: 'min',
                            isDense: true,
                          ),
                          onChanged: (v) {
                            final val = int.tryParse(v) ?? 60;
                            setState(() {
                              _durationSlider = val.clamp(5, 480);
                            });
                          },
                          validator: (v) {
                            final val = int.tryParse(v ?? '');
                            if (val == null || val < 5) return 'Min 5min';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _durationSlider.toDouble(),
                    min: 5,
                    max: 480,
                    divisions: 95,
                    activeColor: AppTheme.primary,
                    inactiveColor: AppTheme.borderColor,
                    onChanged: (v) {
                      setState(() {
                        _durationSlider = v.round();
                        _durationCtrl.text = _durationSlider.toString();
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('5m', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                      Text('1h', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                      Text('2h', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                      Text('4h', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                      Text('8h', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Priority
            _SectionLabel(label: 'Priority'),
            _PrioritySelector(
              selected: _priority,
              onChanged: (p) => setState(() => _priority = p),
            ),
            const SizedBox(height: 24),

            // Deadline (optional)
            _SectionLabel(label: 'Deadline (optional)'),
            TextFormField(
              controller: _deadlineCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g., 3:00 PM or End of day',
                prefixIcon:
                    Icon(Icons.schedule_rounded, color: AppTheme.primary),
              ),
            ),
            const SizedBox(height: 24),

            // Notes
            _SectionLabel(label: 'Notes (optional)'),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Any extra context or details...',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child: Icon(Icons.notes_rounded, color: AppTheme.primary),
                ),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _save,
              child: Text(isEditing ? 'Save changes' : 'Add task'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '${minutes} min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '$h hour${h > 1 ? 's' : ''}' : '$h h $m min';
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _PrioritySelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _PrioritySelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PriorityOption(
          label: 'High',
          value: 'high',
          selected: selected,
          icon: Icons.keyboard_double_arrow_up_rounded,
          color: AppTheme.highPriority,
          bgColor: AppTheme.highPriorityBg,
          onTap: onChanged,
        ),
        const SizedBox(width: 10),
        _PriorityOption(
          label: 'Medium',
          value: 'medium',
          selected: selected,
          icon: Icons.drag_handle_rounded,
          color: AppTheme.medPriority,
          bgColor: AppTheme.medPriorityBg,
          onTap: onChanged,
        ),
        const SizedBox(width: 10),
        _PriorityOption(
          label: 'Low',
          value: 'low',
          selected: selected,
          icon: Icons.keyboard_double_arrow_down_rounded,
          color: AppTheme.lowPriority,
          bgColor: AppTheme.lowPriorityBg,
          onTap: onChanged,
        ),
      ],
    );
  }
}

class _PriorityOption extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final ValueChanged<String> onTap;

  const _PriorityOption({
    required this.label,
    required this.value,
    required this.selected,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : AppTheme.borderColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : color,
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
