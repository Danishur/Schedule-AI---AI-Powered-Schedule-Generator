class ScheduleBlock {
  final String time;
  final String endTime;
  final String title;
  final String type; // 'high', 'medium', 'low', 'break'
  final String? note;
  bool isCompleted;

  ScheduleBlock({
    required this.time,
    required this.endTime,
    required this.title,
    required this.type,
    this.note,
    this.isCompleted = false,
  });

  factory ScheduleBlock.fromJson(Map<String, dynamic> json) => ScheduleBlock(
        time: json['time'] ?? '',
        endTime: json['endTime'] ?? '',
        title: json['title'] ?? '',
        type: json['type'] ?? 'medium',
        note: json['note'],
      );

  Map<String, dynamic> toJson() => {
        'time': time,
        'endTime': endTime,
        'title': title,
        'type': type,
        'note': note,
        'isCompleted': isCompleted,
      };

  bool get isBreak => type == 'break';

  String get durationLabel {
    try {
      final start = _parseTime(time);
      final end = _parseTime(endTime);
      final diff = end.difference(start).inMinutes;
      if (diff < 60) return '${diff}m';
      final h = diff ~/ 60;
      final m = diff % 60;
      return m == 0 ? '${h}h' : '${h}h ${m}m';
    } catch (_) {
      return '';
    }
  }

  DateTime _parseTime(String t) {
    final parts = t.split(' ');
    final timeParts = parts[0].split(':');
    int hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    final isPm = parts.length > 1 && parts[1].toUpperCase() == 'PM';
    if (isPm && hour != 12) hour += 12;
    if (!isPm && hour == 12) hour = 0;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }
}

class GeneratedSchedule {
  final List<ScheduleBlock> blocks;
  final ScheduleStats stats;
  final String insight;
  final DateTime generatedAt;

  GeneratedSchedule({
    required this.blocks,
    required this.stats,
    required this.insight,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();

  factory GeneratedSchedule.fromJson(Map<String, dynamic> json) =>
      GeneratedSchedule(
        blocks: (json['blocks'] as List<dynamic>)
            .map((b) => ScheduleBlock.fromJson(b))
            .toList(),
        stats: ScheduleStats.fromJson(json['stats'] ?? {}),
        insight: json['insight'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'blocks': blocks.map((b) => b.toJson()).toList(),
        'stats': stats.toJson(),
        'insight': insight,
        'generatedAt': generatedAt.toIso8601String(),
      };
}

class ScheduleStats {
  final int totalWork;
  final int totalBreaks;
  final int tasksScheduled;

  ScheduleStats({
    required this.totalWork,
    required this.totalBreaks,
    required this.tasksScheduled,
  });

  factory ScheduleStats.fromJson(Map<String, dynamic> json) => ScheduleStats(
        totalWork: json['totalWork'] ?? 0,
        totalBreaks: json['totalBreaks'] ?? 0,
        tasksScheduled: json['tasksScheduled'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'totalWork': totalWork,
        'totalBreaks': totalBreaks,
        'tasksScheduled': tasksScheduled,
      };

  String get totalWorkLabel {
    final h = totalWork ~/ 60;
    final m = totalWork % 60;
    if (h == 0) return '${m}m';
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}
