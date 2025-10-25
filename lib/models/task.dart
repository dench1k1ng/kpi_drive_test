import 'package:kanban_board/kanban_board.dart';

class Task extends KanbanBoardGroupItem {
  final String taskId; // indicator_to_mo_id
  final String parentId; // parent_id - ID папки/колонки
  final String name;
  final int order;
  // Добавляем поля для демонстрации стиля KPI
  final int weight;
  final int fact;
  final int percent; // Рассчитаем для примера

  Task({
    required this.taskId,
    required this.parentId,
    required this.name,
    required this.order,
    required this.weight,
    required this.fact,
    required this.percent,
  });

  @override
  String get id => taskId;

  factory Task.fromJson(Map<String, dynamic> json) {
    // В API поля могут приходить как int, так и String, приводим к String
    final taskId = json['indicator_to_mo_id']?.toString() ?? '0';
    final parentId = json['parent_id']?.toString() ?? '0';
    final name = json['name'] as String? ?? 'Нет названия';
    final order = (json['order'] as int?) ?? 0;

    // Вставляем фейковые данные для демонстрации KPI в карточке
    final weight = taskId.length * 10;
    final fact = taskId.length * 15;
    final percent = (fact / weight * 100).toInt();

    return Task(
      taskId: taskId,
      parentId: parentId,
      name: name,
      order: order,
      weight: weight,
      fact: fact,
      percent: percent,
    );
  }

  // Метод для создания копии с обновленными полями
  Task copyWith({
    String? taskId,
    String? parentId,
    String? name,
    int? order,
    int? weight,
    int? fact,
    int? percent,
  }) {
    return Task(
      taskId: taskId ?? this.taskId,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      order: order ?? this.order,
      weight: weight ?? this.weight,
      fact: fact ?? this.fact,
      percent: percent ?? this.percent,
    );
  }
}
