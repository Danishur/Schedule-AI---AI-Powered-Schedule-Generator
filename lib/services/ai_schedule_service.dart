import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task.dart';
import '../models/schedule_block.dart';

class AIScheduleService {
  static const String _baseUrl = 'https://api.anthropic.com/v1/messages';
  static const String _model = 'claude-opus-4-5';
  final String apiKey;

  AIScheduleService({required this.apiKey});

  Future<GeneratedSchedule> generateSchedule({
    required List<Task> tasks,
    required String startTime,
    required String endTime,
    required int breakDuration,
  }) async {
    final taskList = tasks
        .map((t) =>
            '- "${t.name}" (${t.duration} min, ${t.priority} priority${t.deadline != null && t.deadline!.isNotEmpty ? ', deadline: ${t.deadline}' : ''}${t.notes != null && t.notes!.isNotEmpty ? ', notes: ${t.notes}' : ''})')
        .join('\n');

    final breakText = breakDuration == 0
        ? 'No breaks needed'
        : '$breakDuration minute breaks between tasks';

    final prompt = '''You are a productivity and schedule optimization expert AI.
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
  "blocks": [
    {
      "time": "9:00 AM",
      "endTime": "9:45 AM",
      "title": "Task or break name",
      "type": "high",
      "note": "Brief productivity tip (max 10 words)"
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
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = (data['content'] as List)
            .map((c) => c['text'] ?? '')
            .join('');
        
        // Clean JSON from response
        String cleanJson = text.trim();
        if (cleanJson.contains('```json')) {
          cleanJson = cleanJson.split('```json')[1].split('```')[0].trim();
        } else if (cleanJson.contains('```')) {
          cleanJson = cleanJson.split('```')[1].split('```')[0].trim();
        }

        final scheduleJson = jsonDecode(cleanJson);
        return GeneratedSchedule.fromJson(scheduleJson);
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API key. Please check your Anthropic API key.');
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('Invalid API key')) rethrow;
      // Fallback to local generation if API fails
      return _generateFallbackSchedule(
        tasks: tasks,
        startTime: startTime,
        endTime: endTime,
        breakDuration: breakDuration,
      );
    }
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

      // Add break after long tasks
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
      return 9 * 60; // default 9 AM
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
