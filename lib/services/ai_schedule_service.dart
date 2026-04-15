import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task.dart';
import '../models/schedule_block.dart';

class AIScheduleService {
  static const String _baseUrl = 'https://api.anthropic.com/v1/messages';
  static const String _model = 'claude-opus-4-5';
  final String apiKey;

  AIScheduleService({required this.apiKey});

  /// Generate schedule from a free-form natural language prompt.
  /// E.g. "school day schedule", "weekly plan for a freelancer", etc.
  Future<GeneratedSchedule> generateFromPrompt({
    required String prompt,
    required String startTime,
    required String endTime,
    required int breakDuration,
  }) async {
    final breakText = breakDuration == 0
        ? 'No breaks needed'
        : '$breakDuration minute breaks between tasks';

    final systemPrompt = '''You are a world-class productivity and schedule optimization AI.
Generate a practical, detailed, and realistic schedule based on the user's request.

Working window: $startTime to $endTime
Break preference: $breakText

Rules:
1. Fill the time window with realistic, specific activities relevant to the request
2. High-priority tasks go during peak hours (morning/early afternoon)
3. Insert breaks per user preference after long focus blocks (45+ min)
4. Add a practical short note (max 12 words) for each block
5. Keep blocks between 15–120 minutes each
6. Calculate accurate stats

Respond with ONLY valid JSON, no markdown, no explanation:
{
  "title": "Descriptive schedule title",
  "blocks": [
    {
      "time": "9:00 AM",
      "endTime": "9:45 AM",
      "title": "Specific activity name",
      "type": "high",
      "note": "Brief actionable tip for this block"
    }
  ],
  "stats": {
    "totalWork": 285,
    "totalBreaks": 30,
    "tasksScheduled": 6
  },
  "insight": "One actionable insight about this schedule, max 20 words."
}

Valid type values: "high", "medium", "low", "break"
Times must use 12-hour format with AM/PM (e.g. "9:00 AM", "2:30 PM").''';

    return _callAPI(
      systemPrompt: systemPrompt,
      userMessage: 'Create a schedule for: $prompt',
      fallback: () => _generateFallbackFromPrompt(
        prompt: prompt,
        startTime: startTime,
        endTime: endTime,
        breakDuration: breakDuration,
      ),
    );
  }

  /// Generate schedule from existing task list.
  Future<GeneratedSchedule> generateSchedule({
    required List<Task> tasks,
    required String startTime,
    required String endTime,
    required int breakDuration,
  }) async {
    final taskList = tasks
        .map((t) =>
            '- "${t.name}" (${t.duration} min, ${t.priority} priority'
            '${t.deadline != null && t.deadline!.isNotEmpty ? ', deadline: ${t.deadline}' : ''}'
            '${t.notes != null && t.notes!.isNotEmpty ? ', notes: ${t.notes}' : ''})')
        .join('\n');

    final breakText = breakDuration == 0
        ? 'No breaks needed'
        : '$breakDuration minute breaks between tasks';

    final systemPrompt = '''You are a productivity and schedule optimization expert AI.
Generate a realistic, optimized daily schedule based on the following input.

Working hours: $startTime to $endTime
Break preference: $breakText
Tasks to schedule:
$taskList

Instructions:
1. Order tasks by priority (high first), but respect deadlines if given
2. Schedule high-priority tasks during peak morning hours when possible
3. Insert breaks strategically after long focus blocks (60+ min)
4. Avoid scheduling more work than available hours
5. Each block should have a practical productivity tip in "note"
6. Calculate accurate stats

Respond with ONLY valid JSON, no markdown, no explanation:
{
  "title": "Today's Optimized Schedule",
  "blocks": [
    {
      "time": "9:00 AM",
      "endTime": "9:45 AM",
      "title": "Task or break name",
      "type": "high",
      "note": "Brief productivity tip (max 12 words)"
    }
  ],
  "stats": {
    "totalWork": 285,
    "totalBreaks": 30,
    "tasksScheduled": 5
  },
  "insight": "One actionable insight about this specific schedule (max 20 words)."
}

Valid type values: "high", "medium", "low", "break"
Times must use 12-hour format with AM/PM.''';

    return _callAPI(
      systemPrompt: systemPrompt,
      userMessage: 'Generate my optimized schedule.',
      fallback: () => _generateFallbackSchedule(
        tasks: tasks,
        startTime: startTime,
        endTime: endTime,
        breakDuration: breakDuration,
      ),
    );
  }

  Future<GeneratedSchedule> _callAPI({
    required String systemPrompt,
    required String userMessage,
    required GeneratedSchedule Function() fallback,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 1500,
          'system': systemPrompt,
          'messages': [
            {'role': 'user', 'content': userMessage}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = (data['content'] as List)
            .map((c) => c['text'] ?? '')
            .join('');

        String cleanJson = text.trim();
        if (cleanJson.contains('```json')) {
          cleanJson =
              cleanJson.split('```json')[1].split('```')[0].trim();
        } else if (cleanJson.contains('```')) {
          cleanJson = cleanJson.split('```')[1].split('```')[0].trim();
        }

        final scheduleJson = jsonDecode(cleanJson);
        return GeneratedSchedule.fromJson(scheduleJson);
      } else if (response.statusCode == 401) {
        throw Exception(
            'Invalid API key. Please check your Anthropic API key in Settings.');
      } else if (response.statusCode == 429) {
        throw Exception(
            'Rate limit reached. Please wait a moment and try again.');
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('Invalid API key') ||
          e.toString().contains('Rate limit')) {
        rethrow;
      }
      // Fallback to local generation if API fails
      return fallback();
    }
  }

  // ─── Fallback generators ──────────────────────────────────────────────────

  GeneratedSchedule _generateFallbackFromPrompt({
    required String prompt,
    required String startTime,
    required String endTime,
    required int breakDuration,
  }) {
    final lp = prompt.toLowerCase();
    List<Map<String, dynamic>> template;

    if (lp.contains('school') || lp.contains('student')) {
      template = _schoolTemplate();
    } else if (lp.contains('work') || lp.contains('office')) {
      template = _workTemplate();
    } else if (lp.contains('study') || lp.contains('exam')) {
      template = _studyTemplate();
    } else if (lp.contains('morning') || lp.contains('routine')) {
      template = _morningTemplate();
    } else if (lp.contains('week') || lp.contains('plan')) {
      template = _weeklyTemplate();
    } else {
      template = _workTemplate();
    }

    int currentMinutes = _timeToMinutes(startTime);
    final endMinutes = _timeToMinutes(endTime);
    final blocks = <ScheduleBlock>[];
    int totalWork = 0;
    int totalBreaks = 0;

    for (final item in template) {
      final dur = item['duration'] as int;
      if (currentMinutes + dur > endMinutes) break;

      final type = item['type'] as String;
      blocks.add(ScheduleBlock(
        time: _minutesToTime(currentMinutes),
        endTime: _minutesToTime(currentMinutes + dur),
        title: item['title'] as String,
        type: type,
        note: item['note'] as String,
      ));

      currentMinutes += dur;
      if (type == 'break') {
        totalBreaks += dur;
      } else {
        totalWork += dur;
      }

      if (breakDuration > 0 &&
          type != 'break' &&
          dur >= 45 &&
          currentMinutes + breakDuration <= endMinutes) {
        blocks.add(ScheduleBlock(
          time: _minutesToTime(currentMinutes),
          endTime: _minutesToTime(currentMinutes + breakDuration),
          title: 'Break',
          type: 'break',
          note: 'Step away, hydrate, and recharge.',
        ));
        currentMinutes += breakDuration;
        totalBreaks += breakDuration;
      }
    }

    return GeneratedSchedule(
      title: 'Your Schedule',
      blocks: blocks,
      stats: ScheduleStats(
        totalWork: totalWork,
        totalBreaks: totalBreaks,
        tasksScheduled: blocks.where((b) => !b.isBreak).length,
      ),
      insight:
          'Schedule generated offline. Add an API key for AI-powered optimization.',
    );
  }

  GeneratedSchedule _generateFallbackSchedule({
    required List<Task> tasks,
    required String startTime,
    required String endTime,
    required int breakDuration,
  }) {
    final sorted = List<Task>.from(tasks)
      ..sort((a, b) {
        const order = {'high': 0, 'medium': 1, 'low': 2};
        return (order[a.priority] ?? 1).compareTo(order[b.priority] ?? 1);
      });

    final blocks = <ScheduleBlock>[];
    int currentMinutes = _timeToMinutes(startTime);
    final endMinutes = _timeToMinutes(endTime);
    int scheduledCount = 0;
    int totalWork = 0;
    int totalBreaks = 0;

    for (final task in sorted) {
      if (currentMinutes + task.duration > endMinutes) break;

      blocks.add(ScheduleBlock(
        time: _minutesToTime(currentMinutes),
        endTime: _minutesToTime(currentMinutes + task.duration),
        title: task.name,
        type: task.priority,
        note: _getTipForPriority(task.priority),
      ));

      currentMinutes += task.duration;
      totalWork += task.duration;
      scheduledCount++;

      if (breakDuration > 0 &&
          task.duration >= 45 &&
          currentMinutes + breakDuration <= endMinutes &&
          sorted.indexOf(task) < sorted.length - 1) {
        blocks.add(ScheduleBlock(
          time: _minutesToTime(currentMinutes),
          endTime: _minutesToTime(currentMinutes + breakDuration),
          title: 'Short break',
          type: 'break',
          note: 'Step away, hydrate, and recharge.',
        ));
        currentMinutes += breakDuration;
        totalBreaks += breakDuration;
      }
    }

    return GeneratedSchedule(
      title: 'Your Optimized Schedule',
      blocks: blocks,
      stats: ScheduleStats(
        totalWork: totalWork,
        totalBreaks: totalBreaks,
        tasksScheduled: scheduledCount,
      ),
      insight:
          'High-priority tasks are front-loaded for maximum focus and energy.',
    );
  }

  // ─── Template definitions ─────────────────────────────────────────────────

  List<Map<String, dynamic>> _schoolTemplate() => [
        {'title': 'Morning Preparation', 'duration': 30, 'type': 'medium', 'note': 'Pack your bag and review today\'s timetable.'},
        {'title': 'Math / Science Class', 'duration': 60, 'type': 'high', 'note': 'Stay focused and take notes actively.'},
        {'title': 'Break', 'duration': 15, 'type': 'break', 'note': 'Hydrate and move around.'},
        {'title': 'Language / History Class', 'duration': 60, 'type': 'high', 'note': 'Ask questions — participation boosts retention.'},
        {'title': 'Lunch', 'duration': 45, 'type': 'break', 'note': 'Eat well for sustained afternoon energy.'},
        {'title': 'Elective / PE Class', 'duration': 60, 'type': 'medium', 'note': 'Enjoy and be present.'},
        {'title': 'Homework — Priority Subjects', 'duration': 60, 'type': 'high', 'note': 'Tackle hardest subject first.'},
        {'title': 'Short Break', 'duration': 15, 'type': 'break', 'note': 'Quick rest before evening review.'},
        {'title': 'Review & Prepare for Tomorrow', 'duration': 30, 'type': 'medium', 'note': 'Read tomorrow\'s material briefly.'},
      ];

  List<Map<String, dynamic>> _workTemplate() => [
        {'title': 'Morning Planning & Email Triage', 'duration': 30, 'type': 'medium', 'note': 'Set priorities before diving into deep work.'},
        {'title': 'Deep Work — Top Priority Task', 'duration': 90, 'type': 'high', 'note': 'No notifications, maximum focus block.'},
        {'title': 'Break', 'duration': 15, 'type': 'break', 'note': 'Step away and stretch.'},
        {'title': 'Meetings / Collaboration', 'duration': 60, 'type': 'medium', 'note': 'Come prepared with agenda items.'},
        {'title': 'Lunch Break', 'duration': 45, 'type': 'break', 'note': 'Disconnect completely — real rest improves PM focus.'},
        {'title': 'Secondary Priority Tasks', 'duration': 90, 'type': 'medium', 'note': 'Batch similar tasks together for efficiency.'},
        {'title': 'Break', 'duration': 15, 'type': 'break', 'note': 'Quick recharge before end-of-day push.'},
        {'title': 'Admin & Low-Priority Tasks', 'duration': 45, 'type': 'low', 'note': 'Good time for emails, filing, and low-effort tasks.'},
        {'title': 'End of Day Review', 'duration': 20, 'type': 'low', 'note': 'Log progress and set tomorrow\'s top 3.'},
      ];

  List<Map<String, dynamic>> _studyTemplate() => [
        {'title': 'Review Session Goals', 'duration': 15, 'type': 'medium', 'note': 'Write down what you want to achieve today.'},
        {'title': 'Subject 1 — Active Recall', 'duration': 50, 'type': 'high', 'note': 'Test yourself without looking at notes.'},
        {'title': 'Break', 'duration': 10, 'type': 'break', 'note': 'Pomodoro rest — brief but complete.'},
        {'title': 'Subject 1 — Practice Problems', 'duration': 50, 'type': 'high', 'note': 'Apply what you just reviewed.'},
        {'title': 'Lunch / Rest', 'duration': 40, 'type': 'break', 'note': 'Your brain consolidates memory during rest.'},
        {'title': 'Subject 2 — Read & Summarize', 'duration': 50, 'type': 'high', 'note': 'Summarize each section in your own words.'},
        {'title': 'Break', 'duration': 10, 'type': 'break', 'note': 'Walk briefly to boost alertness.'},
        {'title': 'Subject 2 — Flashcards & Review', 'duration': 50, 'type': 'medium', 'note': 'Space repetition: review yesterday\'s cards too.'},
        {'title': 'Mock Quiz / Past Papers', 'duration': 45, 'type': 'high', 'note': 'Timed practice builds exam confidence.'},
        {'title': 'Evening Review & Plan', 'duration': 20, 'type': 'low', 'note': 'Note gaps and plan tomorrow\'s focus.'},
      ];

  List<Map<String, dynamic>> _morningTemplate() => [
        {'title': 'Wake Up & Hydrate', 'duration': 10, 'type': 'low', 'note': 'Drink a full glass of water immediately.'},
        {'title': 'Stretching / Light Exercise', 'duration': 20, 'type': 'medium', 'note': 'Movement wakes the body and mind.'},
        {'title': 'Mindfulness / Journaling', 'duration': 15, 'type': 'low', 'note': 'Write 3 things you\'re grateful for.'},
        {'title': 'Shower & Personal Care', 'duration': 20, 'type': 'medium', 'note': 'A consistent routine reduces decision fatigue.'},
        {'title': 'Healthy Breakfast', 'duration': 20, 'type': 'medium', 'note': 'Protein-rich meals sustain focus longer.'},
        {'title': 'Daily Planning Session', 'duration': 15, 'type': 'high', 'note': 'Set your top 3 priorities for the day.'},
        {'title': 'Learning / Reading', 'duration': 30, 'type': 'medium', 'note': 'Feed your mind before reactive work begins.'},
      ];

  List<Map<String, dynamic>> _weeklyTemplate() => [
        {'title': 'Weekly Review (Previous Week)', 'duration': 45, 'type': 'high', 'note': 'What worked? What didn\'t? Adjust accordingly.'},
        {'title': 'Goal Setting & Prioritization', 'duration': 30, 'type': 'high', 'note': 'Align tasks with your top quarterly goal.'},
        {'title': 'Break', 'duration': 15, 'type': 'break', 'note': 'Clear your head between planning phases.'},
        {'title': 'Deep Work Block — Main Project', 'duration': 90, 'type': 'high', 'note': 'Advance your most important project.'},
        {'title': 'Lunch', 'duration': 45, 'type': 'break', 'note': 'Proper rest improves afternoon productivity.'},
        {'title': 'Admin & Communications', 'duration': 60, 'type': 'medium', 'note': 'Batch emails and messages — twice a day max.'},
        {'title': 'Break', 'duration': 15, 'type': 'break', 'note': 'Recharge before the afternoon session.'},
        {'title': 'Secondary Projects / Learning', 'duration': 60, 'type': 'medium', 'note': 'Invest in skills that compound over time.'},
        {'title': 'End-of-Day Shutdown Ritual', 'duration': 15, 'type': 'low', 'note': 'Close loops and set tomorrow\'s priority.'},
      ];

  // ─── Helpers ──────────────────────────────────────────────────────────────

  int _timeToMinutes(String time) {
    try {
      final parts = time.split(':');
      int h = int.parse(parts[0]);
      int m = int.parse(parts[1].replaceAll(RegExp(r'[^0-9]'), ''));
      final isAfternoon = time.toUpperCase().contains('PM') && h != 12;
      final isMidnight = time.toUpperCase().contains('AM') && h == 12;
      if (isAfternoon) h += 12;
      if (isMidnight) h = 0;
      return h * 60 + m;
    } catch (_) {
      return 9 * 60;
    }
  }

  String _minutesToTime(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    final ampm = h >= 12 ? 'PM' : 'AM';
    final displayH = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$displayH:${m.toString().padLeft(2, '0')} $ampm';
  }

  String _getTipForPriority(String priority) {
    switch (priority) {
      case 'high':
        return 'Tackle this with full focus. No distractions.';
      case 'medium':
        return 'Stay consistent. Progress beats perfection.';
      case 'low':
        return 'Good time to batch similar tasks together.';
      default:
        return 'Stay on track and keep momentum going.';
    }
  }
}