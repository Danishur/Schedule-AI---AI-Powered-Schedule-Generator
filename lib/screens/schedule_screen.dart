import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/schedule_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/schedule_block_card.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScheduleProvider>();

    if (provider.isLoading) {
      return const _LoadingView();
    }

    if (provider.status == ScheduleStatus.error) {
      return _ErrorView(message: provider.errorMessage);
    }

    if (provider.currentSchedule == null) {
      return _EmptyScheduleView(
        onGenerate: () => provider.generateSchedule(),
        taskCount: provider.tasks.length,
      );
    }

    final schedule = provider.currentSchedule!;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: AppTheme.surface,
            expandedHeight: 130,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Today\'s Schedule',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      _AiBadge(),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(schedule.generatedAt),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                color: AppTheme.primary,
                onPressed: () => provider.generateSchedule(),
                tooltip: 'Regenerate',
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: _StatsCards(schedule: schedule),
            ),
          ),

          if (schedule.insight.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: _InsightCard(insight: schedule.insight),
              ),
            ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final block = schedule.blocks[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ScheduleBlockCard(
                      block: block,
                      onToggle: () => provider.toggleBlockComplete(index),
                    ),
                  );
                },
                childCount: schedule.blocks.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    final days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    final dow = days[dt.weekday - 1];
    return '$dow, ${months[dt.month - 1]} ${dt.day}';
  }
}

class _AiBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 10),
          SizedBox(width: 4),
          Text(
            'AI Generated',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsCards extends StatelessWidget {
  final schedule;
  const _StatsCards({required this.schedule});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
          label: 'Work time',
          value: schedule.stats.totalWorkLabel,
          icon: Icons.work_outline_rounded,
          color: AppTheme.primary,
        ),
        const SizedBox(width: 10),
        _StatCard(
          label: 'Tasks',
          value: '${schedule.stats.tasksScheduled}',
          icon: Icons.check_circle_outline_rounded,
          color: AppTheme.secondary,
        ),
        const SizedBox(width: 10),
        _StatCard(
          label: 'Breaks',
          value: '${schedule.stats.totalBreaks}m',
          icon: Icons.coffee_outlined,
          color: AppTheme.warning,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String insight;
  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x0F6C5CE7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x266C5CE7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            color: AppTheme.primary,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              insight,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.primaryDark,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatefulWidget {
  const _LoadingView();

  @override
  State<_LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<_LoadingView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _stepIndex = 0;
  final List<String> _steps = [
    'Analyzing your tasks...',
    'Optimizing priority order...',
    'Balancing workload...',
    'Scheduling breaks...',
    'Finalizing your schedule...',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _runSteps();
  }

  void _runSteps() async {
    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) setState(() => _stepIndex = i);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0x1A6C5CE7),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                    strokeWidth: 3,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Building your schedule',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Text(
                  _steps[_stepIndex],
                  key: ValueKey(_stepIndex),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              ...List.generate(
                _steps.length,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        i <= _stepIndex
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 16,
                        color: i <= _stepIndex
                            ? AppTheme.secondary
                            : AppTheme.textMuted,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _steps[i],
                        style: TextStyle(
                          fontSize: 13,
                          color: i <= _stepIndex
                              ? AppTheme.textPrimary
                              : AppTheme.textMuted,
                          fontWeight: i == _stepIndex
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0x1AE24B4A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 36,
                  color: AppTheme.danger,
                ),
              ),
              const SizedBox(height: 20),
              Text('Something went wrong',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyScheduleView extends StatelessWidget {
  final VoidCallback onGenerate;
  final int taskCount;
  const _EmptyScheduleView({required this.onGenerate, required this.taskCount});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Center(
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
                  Icons.auto_awesome_rounded,
                  size: 48,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Ready to generate',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                taskCount == 0
                    ? 'Add some tasks first, then tap the AI button to generate your optimized schedule.'
                    : 'You have $taskCount task${taskCount > 1 ? 's' : ''} ready. Tap the button below to generate your AI-optimized schedule.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 28),
              if (taskCount > 0)
                ElevatedButton.icon(
                  onPressed: onGenerate,
                  icon: const Icon(Icons.auto_awesome_rounded, size: 20),
                  label: const Text('Generate schedule'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
