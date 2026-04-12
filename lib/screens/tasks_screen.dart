import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../services/schedule_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/task_card.dart';
import 'add_task_screen.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScheduleProvider>();
    final tasks = provider.tasks;
    final stats = provider.taskStats;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppTheme.surface,
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Tasks',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${tasks.length} tasks · ${_formatDuration(provider.totalTaskDuration)} total',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            actions: [
              if (tasks.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined),
                  color: AppTheme.textSecondary,
                  onPressed: () => _showClearDialog(context, provider),
                ),
            ],
          ),

          if (tasks.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: _StatsRow(stats: stats),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final task = tasks[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TaskCard(
                        task: task,
                        onTap: () => _editTask(context, task),
                        onDelete: () => provider.removeTask(task.id),
                        onToggle: () => provider.toggleTaskComplete(task.id),
                      ),
                    );
                  },
                  childCount: tasks.length,
                ),
              ),
            ),
          ] else
            SliverFillRemaining(
              child: _EmptyState(
                onAddTask: () => _addTask(context),
              ),
            ),
        ],
      ),
      floatingActionButton: tasks.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _addTask(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Task'),
              backgroundColor: AppTheme.primary,
            )
          : null,
    );
  }

  void _addTask(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddTaskScreen()),
    );
  }

  void _editTask(BuildContext context, Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddTaskScreen(task: task)),
    );
  }

  void _showClearDialog(BuildContext context, ScheduleProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all tasks?'),
        content: const Text('This will remove all your tasks. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.clearTasks();
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes == 0) return '0m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}m';
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}

class _StatsRow extends StatelessWidget {
  final Map<String, int> stats;
  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatChip(
          label: 'High',
          count: stats['high'] ?? 0,
          color: AppTheme.highPriority,
          bgColor: AppTheme.highPriorityBg,
        ),
        const SizedBox(width: 8),
        _StatChip(
          label: 'Med',
          count: stats['medium'] ?? 0,
          color: AppTheme.medPriority,
          bgColor: AppTheme.medPriorityBg,
        ),
        const SizedBox(width: 8),
        _StatChip(
          label: 'Low',
          count: stats['low'] ?? 0,
          color: AppTheme.lowPriority,
          bgColor: AppTheme.lowPriorityBg,
        ),
        const Spacer(),
        if ((stats['completed'] ?? 0) > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0x1A6C5CE7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${stats['completed']} done',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final Color bgColor;

  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '$count $label',
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddTask;
  const _EmptyState({required this.onAddTask});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: const Color(0x146C5CE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.checklist_rounded,
                size: 48,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No tasks yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your tasks and let AI build\nan optimized schedule for you.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onAddTask,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Add your first task'),
            ),
          ],
        ),
      ),
    );
  }
}
