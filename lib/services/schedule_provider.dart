import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../models/schedule_block.dart';
import '../services/ai_schedule_service.dart';

enum ScheduleStatus { idle, loading, success, error }

class ScheduleProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  GeneratedSchedule? _currentSchedule;
  ScheduleStatus _status = ScheduleStatus.idle;
  String _errorMessage = '';
  String _startTime = '09:00 AM';
  String _endTime = '06:00 PM';
  int _breakDuration = 30;
  List<GeneratedSchedule> _history = [];
  String _apiKey = '';
  int _currentView = 0;

  // Getters
  List<Task> get tasks => _tasks;
  GeneratedSchedule? get currentSchedule => _currentSchedule;
  ScheduleStatus get status => _status;
  String get errorMessage => _errorMessage;
  String get startTime => _startTime;
  String get endTime => _endTime;
  int get breakDuration => _breakDuration;
  List<GeneratedSchedule> get history => _history;
  String get apiKey => _apiKey;
  int get currentView => _currentView;
  bool get isLoading => _status == ScheduleStatus.loading;

  ScheduleProvider() {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _apiKey = prefs.getString('api_key') ?? '';
      _startTime = prefs.getString('start_time') ?? '09:00 AM';
      _endTime = prefs.getString('end_time') ?? '06:00 PM';
      _breakDuration = prefs.getInt('break_duration') ?? 30;

      final tasksJson = prefs.getStringList('tasks') ?? [];
      _tasks = tasksJson.map((t) => Task.fromJson(jsonDecode(t))).toList();

      final historyJson = prefs.getStringList('history') ?? [];
      _history = historyJson
          .map((h) => GeneratedSchedule.fromJson(jsonDecode(h)))
          .toList();

      final scheduleJson = prefs.getString('current_schedule');
      if (scheduleJson != null) {
        _currentSchedule =
            GeneratedSchedule.fromJson(jsonDecode(scheduleJson));
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Load error: $e');
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('api_key', _apiKey);
      prefs.setString('start_time', _startTime);
      prefs.setString('end_time', _endTime);
      prefs.setInt('break_duration', _breakDuration);
      prefs.setStringList(
          'tasks', _tasks.map((t) => jsonEncode(t.toJson())).toList());
      if (_currentSchedule != null) {
        prefs.setString(
            'current_schedule', jsonEncode(_currentSchedule!.toJson()));
      }
      prefs.setStringList(
          'history',
          _history
              .take(20)
              .map((h) => jsonEncode(h.toJson()))
              .toList());
    } catch (e) {
      debugPrint('Save error: $e');
    }
  }

  // ─── Task management ───────────────────────────────────────────────────────

  void addTask(Task task) {
    _tasks.add(task);
    _saveToStorage();
    notifyListeners();
  }

  void updateTask(Task updatedTask) {
    final idx = _tasks.indexWhere((t) => t.id == updatedTask.id);
    if (idx != -1) {
      _tasks[idx] = updatedTask;
      _saveToStorage();
      notifyListeners();
    }
  }

  void removeTask(String id) {
    _tasks.removeWhere((t) => t.id == id);
    _saveToStorage();
    notifyListeners();
  }

  void reorderTasks(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    final task = _tasks.removeAt(oldIndex);
    _tasks.insert(newIndex, task);
    _saveToStorage();
    notifyListeners();
  }

  void toggleTaskComplete(String id) {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx != -1) {
      _tasks[idx] =
          _tasks[idx].copyWith(isCompleted: !_tasks[idx].isCompleted);
      _saveToStorage();
      notifyListeners();
    }
  }

  // ─── Settings ──────────────────────────────────────────────────────────────

  void setApiKey(String key) {
    _apiKey = key;
    _saveToStorage();
    notifyListeners();
  }

  void setStartTime(String time) {
    _startTime = time;
    _saveToStorage();
    notifyListeners();
  }

  void setEndTime(String time) {
    _endTime = time;
    _saveToStorage();
    notifyListeners();
  }

  void setBreakDuration(int mins) {
    _breakDuration = mins;
    _saveToStorage();
    notifyListeners();
  }

  void setCurrentView(int view) {
    _currentView = view;
    notifyListeners();
  }

  // ─── Generate from task list ───────────────────────────────────────────────

  Future<void> generateSchedule() async {
    if (_tasks.isEmpty) {
      _errorMessage = 'Please add at least one task first.';
      _status = ScheduleStatus.error;
      notifyListeners();
      return;
    }

    _status = ScheduleStatus.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final service = AIScheduleService(apiKey: _apiKey);
      final schedule = await service.generateSchedule(
        tasks: _tasks,
        startTime: _startTime,
        endTime: _endTime,
        breakDuration: _breakDuration,
      );

      _setSchedule(schedule);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _status = ScheduleStatus.error;
    }
    notifyListeners();
  }

  /// Generate schedule from a free-form natural language prompt.
  Future<void> generateFromPrompt({
    required String prompt,
    String? startTime,
    String? endTime,
    int? breakDuration,
  }) async {
    if (prompt.trim().isEmpty) {
      _errorMessage = 'Please enter a prompt to generate a schedule.';
      _status = ScheduleStatus.error;
      notifyListeners();
      return;
    }

    _status = ScheduleStatus.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final service = AIScheduleService(apiKey: _apiKey);
      final schedule = await service.generateFromPrompt(
        prompt: prompt,
        startTime: startTime ?? _startTime,
        endTime: endTime ?? _endTime,
        breakDuration: breakDuration ?? _breakDuration,
      );

      _setSchedule(schedule);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _status = ScheduleStatus.error;
    }
    notifyListeners();
  }

  void _setSchedule(GeneratedSchedule schedule) {
    _currentSchedule = schedule;
    _history.insert(0, schedule);
    if (_history.length > 20) _history = _history.take(20).toList();
    _status = ScheduleStatus.success;
    _currentView = 1;
    _saveToStorage();
  }

  void toggleBlockComplete(int index) {
    if (_currentSchedule != null) {
      _currentSchedule!.blocks[index].isCompleted =
          !_currentSchedule!.blocks[index].isCompleted;
      _saveToStorage();
      notifyListeners();
    }
  }

  void clearSchedule() {
    _currentSchedule = null;
    _status = ScheduleStatus.idle;
    _saveToStorage();
    notifyListeners();
  }

  void clearTasks() {
    _tasks = [];
    _saveToStorage();
    notifyListeners();
  }

  // ─── Stats ─────────────────────────────────────────────────────────────────

  Map<String, int> get taskStats {
    return {
      'total': _tasks.length,
      'high': _tasks.where((t) => t.priority == 'high').length,
      'medium': _tasks.where((t) => t.priority == 'medium').length,
      'low': _tasks.where((t) => t.priority == 'low').length,
      'completed': _tasks.where((t) => t.isCompleted).length,
    };
  }

  int get totalTaskDuration =>
      _tasks.fold(0, (sum, t) => sum + t.duration);
}