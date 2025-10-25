import 'package:flutter/material.dart';
import 'package:kanban_board/kanban_board.dart';
import 'package:kpi_drive_test/service/api_service.dart';
import '../models/task.dart';

class KanbanViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Маппинг ID папок на человекопонятные названия (КРИТИЧНО)
  final Map<String, String> _folderNameMap = {
    '311841': 'К выполнению',
    '311842': 'В работе',
    '311843': 'На проверке',
    '311844': 'Выполнено',
    // Добавьте сюда ваши ID, если получите больше.
    // Если API вернет parent_id, которого нет в мапе, используйте его как название.
  };

  List<KanbanBoardGroup<String, Task>> _groups = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<KanbanBoardGroup<String, Task>> get groups => _groups;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchTasks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final List<Task> tasks = await _apiService.fetchTasks();
      _groupTasksIntoColumns(tasks);
    } catch (e) {
      _errorMessage =
          'Ошибка при загрузке задач из API. Показываем демо-данные.';
      print('Ошибка при загрузке задач: $e');

      // Показываем демо-данные для тестирования интерфейса
      _createDemoTasks();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _createDemoTasks() {
    final demoTasks = [
      Task(
        taskId: 'demo_1',
        parentId: '311841',
        name: 'Анализ конверсии сайта',
        order: 1,
        weight: 100,
        fact: 85,
        percent: 85,
      ),
      Task(
        taskId: 'demo_2',
        parentId: '311841',
        name: 'Настройка Google Analytics',
        order: 2,
        weight: 50,
        fact: 45,
        percent: 90,
      ),
      Task(
        taskId: 'demo_3',
        parentId: '311842',
        name: 'Разработка лендинга',
        order: 1,
        weight: 200,
        fact: 120,
        percent: 60,
      ),
      Task(
        taskId: 'demo_4',
        parentId: '311842',
        name: 'A/B тестирование кнопок',
        order: 2,
        weight: 80,
        fact: 60,
        percent: 75,
      ),
      Task(
        taskId: 'demo_5',
        parentId: '311843',
        name: 'Код-ревью API',
        order: 1,
        weight: 120,
        fact: 100,
        percent: 83,
      ),
      Task(
        taskId: 'demo_6',
        parentId: '311844',
        name: 'Запуск рекламной кампании',
        order: 1,
        weight: 300,
        fact: 320,
        percent: 107,
      ),
    ];

    _groupTasksIntoColumns(demoTasks);
  }

  void _groupTasksIntoColumns(List<Task> tasks) {
    // 1. Сгруппировать задачи по parentId
    final Map<String, List<Task>> grouped = {};
    for (var task in tasks) {
      if (!grouped.containsKey(task.parentId)) {
        grouped[task.parentId] = [];
      }
      grouped[task.parentId]!.add(task);
    }

    // 2. Отсортировать задачи внутри групп по 'order'
    grouped.forEach(
      (key, list) => list.sort((a, b) => a.order.compareTo(b.order)),
    );

    // 3. Создать список KanbanBoardGroup
    _groups = grouped.entries.map((entry) {
      final folderId = entry.key;
      final folderName = _folderNameMap[folderId] ?? 'Папка №$folderId';
      return KanbanBoardGroup<String, Task>(
        id: folderId,
        name: folderName,
        items: entry.value,
      );
    }).toList();

    notifyListeners();
  }

  /// Обработка перемещения задачи (как внутри колонки, так и между колонками)
  Future<void> onGroupItemMove(
    int oldGroupIndex,
    int oldItemIndex,
    int newGroupIndex,
    int newItemIndex,
  ) async {
    // Сохраняем состояние для отката
    final oldGroups = _groups
        .map(
          (g) => KanbanBoardGroup<String, Task>(
            id: g.id,
            name: g.name,
            items: List<Task>.from(g.items),
          ),
        )
        .toList();

    try {
      // 1. Выполняем изменение локально
      final movedTask = _groups[oldGroupIndex].items.removeAt(oldItemIndex);

      // Если задача перемещается в другую колонку, обновляем parent_id
      Task updatedTask = movedTask;
      if (oldGroupIndex != newGroupIndex) {
        updatedTask = movedTask.copyWith(parentId: _groups[newGroupIndex].id);
      }

      _groups[newGroupIndex].items.insert(newItemIndex, updatedTask);

      // 2. Пересчитываем order в затронутых колонках
      _recalculateGroupOrders(_groups[oldGroupIndex]);
      if (oldGroupIndex != newGroupIndex) {
        _recalculateGroupOrders(_groups[newGroupIndex]);
      }

      notifyListeners();

      // 3. Сохраняем изменения через API
      if (oldGroupIndex != newGroupIndex) {
        await _saveTaskField(
          updatedTask.taskId,
          'parent_id',
          updatedTask.parentId,
        );
      }

      // Сохраняем новый порядок
      await _saveTaskOrder(_groups[oldGroupIndex].items);
      if (oldGroupIndex != newGroupIndex) {
        await _saveTaskOrder(_groups[newGroupIndex].items);
      }

      _showSuccessMessage('Задача перемещена успешно');
    } catch (e) {
      // Откат изменений в случае ошибки
      print('Ошибка при перемещении задачи: $e');
      _groups = oldGroups;
      notifyListeners();

      _showErrorMessage('Не удалось переместить задачу: $e');
    }
  }

  /// Пересчитывает order для всех задач в группе
  void _recalculateGroupOrders(KanbanBoardGroup<String, Task> group) {
    for (int i = 0; i < group.items.length; i++) {
      final task = group.items[i];
      group.items[i] = task.copyWith(order: i + 1);
    }
  }

  /// Сохранение поля задачи через API
  Future<void> _saveTaskField(
    String taskId,
    String fieldName,
    String fieldValue,
  ) async {
    await _apiService.saveTaskField(
      indicatorToMoId: taskId,
      fieldName: fieldName,
      fieldValue: fieldValue,
    );
  }

  /// Сохранение порядка всех задач в группе
  Future<void> _saveTaskOrder(List<Task> tasks) async {
    for (final task in tasks) {
      await _saveTaskField(task.taskId, 'order', task.order.toString());
    }
  }

  /// Показать сообщение об ошибке
  void _showErrorMessage(String message) {
    _errorMessage = message;
    notifyListeners();

    // Автоматически скрыть сообщение через 5 секунд
    Future.delayed(const Duration(seconds: 5), () {
      if (_errorMessage == message) {
        _errorMessage = null;
        notifyListeners();
      }
    });
  }

  /// Показать сообщение об успехе
  void _showSuccessMessage(String message) {
    print('SUCCESS: $message');
    // Здесь можно добавить отображение success message в UI
  }

  /// Очистить сообщение об ошибке
  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }
}
