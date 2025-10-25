import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const KPIDriveKanbanApp());
}

class KPIDriveKanbanApp extends StatelessWidget {
  const KPIDriveKanbanApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KPI-DRIVE Канбан',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        primaryColor: const Color(0xFF00FF00),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00FF00),
          secondary: Color(0xFFFFFF00),
          error: Color(0xFFFF0000),
          surface: Color(0xFF2A2A2A),
        ),
      ),
      home: const KanbanBoard(),
    );
  }
}

class Task {
  final int id;
  final int parentId;
  final String name;
  final int order;
  final TaskPriority priority;
  final String? description;
  final DateTime? dueDate;

  Task({
    required this.id,
    required this.parentId,
    required this.name,
    required this.order,
    this.priority = TaskPriority.normal,
    this.description,
    this.dueDate,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['indicator_to_mo_id'] ?? 0,
      parentId: json['parent_id'] ?? 0,
      name: json['name'] ?? '',
      order: json['order'] ?? 0,
      priority: TaskPriority.values[json['priority'] ?? 1],
      description: json['description'],
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'])
          : null,
    );
  }

  Task copyWith({
    int? parentId,
    int? order,
    String? name,
    TaskPriority? priority,
    String? description,
    DateTime? dueDate,
  }) {
    return Task(
      id: id,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      order: order ?? this.order,
      priority: priority ?? this.priority,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
    );
  }
}

enum TaskPriority {
  low(Colors.grey, 'Низкий', Icons.keyboard_arrow_down),
  normal(Color(0xFF0066FF), 'Обычный', Icons.remove),
  high(Color(0xFFFF9900), 'Высокий', Icons.keyboard_arrow_up),
  urgent(Color(0xFFFF0000), 'Срочный', Icons.priority_high);

  const TaskPriority(this.color, this.label, this.icon);
  final Color color;
  final String label;
  final IconData icon;
}

class KanbanColumn {
  final int id;
  final String name;
  final List<Task> tasks;
  final Color color;
  final IconData? icon;

  KanbanColumn({
    required this.id,
    required this.name,
    required this.tasks,
    required this.color,
    this.icon,
  });
}

class KanbanBoard extends StatefulWidget {
  const KanbanBoard({Key? key}) : super(key: key);

  @override
  State<KanbanBoard> createState() => _KanbanBoardState();
}

class _KanbanBoardState extends State<KanbanBoard> {
  List<KanbanColumn> columns = [];
  bool isLoading = false;
  String? errorMessage;
  bool useDemoData = true;
  final String bearerToken = '5c3964b8e3ee4755f2cc0febb851e2f8';

  @override
  void initState() {
    super.initState();
    loadDemoData();
  }

  void loadDemoData() {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      final demoTasks = [
        // Новые задачи
        Task(id: 1001, parentId: 1, name: 'Договор Евроторг', order: 0),
        Task(id: 1002, parentId: 1, name: 'Договор для Водоканала', order: 1),
        Task(id: 1003, parentId: 1, name: 'Договор на ПО Шоро', order: 2),

        // В работе
        Task(
          id: 2001,
          parentId: 2,
          name: 'Договор и счет на аренду ПО для Инженеров',
          order: 0,
        ),
        Task(
          id: 2002,
          parentId: 2,
          name: 'Договор и счет на аренду программы Квелпир',
          order: 1,
        ),
        Task(
          id: 2003,
          parentId: 2,
          name: 'Документы участникам семинаров',
          order: 2,
        ),
        Task(id: 2004, parentId: 2, name: 'Орг.вопросы по семинарам', order: 3),

        // На проверке
        Task(
          id: 3001,
          parentId: 3,
          name: 'Открыть доступ к учебному курсу для Крепса',
          order: 0,
        ),
        Task(id: 3002, parentId: 3, name: 'Переписка с клиентами', order: 1),
        Task(id: 3003, parentId: 3, name: 'Получил/Техника', order: 2),

        // Выполнено
        Task(
          id: 4001,
          parentId: 4,
          name: 'Договор с поставщиком оборудования',
          order: 0,
        ),
        Task(id: 4002, parentId: 4, name: 'Презентация для клиента', order: 1),
        Task(id: 4003, parentId: 4, name: 'Отчет по проекту Q3', order: 2),
        Task(
          id: 4004,
          parentId: 4,
          name: 'Обучение новых сотрудников',
          order: 3,
        ),
      ];

      final Map<int, List<Task>> groupedTasks = {};

      for (var task in demoTasks) {
        if (!groupedTasks.containsKey(task.parentId)) {
          groupedTasks[task.parentId] = [];
        }
        groupedTasks[task.parentId]!.add(task);
      }

      final columnData = [
        {
          'id': 1,
          'name': 'Новые задачи',
          'color': const Color(0xFF0066FF),
          'icon': Icons.new_releases_outlined,
        },
        {
          'id': 2,
          'name': 'В работе',
          'color': const Color(0xFFFFFF00),
          'icon': Icons.work_outline,
        },
        {
          'id': 3,
          'name': 'На проверке',
          'color': const Color(0xFFFF9900),
          'icon': Icons.fact_check_outlined,
        },
        {
          'id': 4,
          'name': 'Выполнено',
          'color': const Color(0xFF00FF00),
          'icon': Icons.check_circle_outline,
        },
      ];

      final newColumns = columnData.map((data) {
        return KanbanColumn(
          id: data['id'] as int,
          name: data['name'] as String,
          tasks: groupedTasks[data['id']] ?? [],
          color: data['color'] as Color,
          icon: data['icon'] as IconData?,
        );
      }).toList();

      setState(() {
        columns = newColumns;
        isLoading = false;
      });
    });
  }

  Future<void> fetchTasks() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse(
          'https://api.dev.kpi-drive.ru/_api/indicators/get_mo_indicators',
        ),
        headers: {'Authorization': 'Bearer $bearerToken'},
        body: {
          'period_start': '2025-09-01',
          'period_end': '2025-09-30',
          'period_key': 'month',
          'requested_mo_id': '42',
          'behaviour_key': 'task,kpi_task',
          'with_result': 'false',
          'response_fields': 'name,indicator_to_mo_id,parent_id,order',
          'auth_user_id': '40',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is Map && data.containsKey('data')) {
          final items = data['data'] as List;
          final tasks = items.map((item) => Task.fromJson(item)).toList();

          final Map<int, List<Task>> groupedTasks = {};
          final Set<int> parentIds = {};

          for (var task in tasks) {
            parentIds.add(task.parentId);
            if (!groupedTasks.containsKey(task.parentId)) {
              groupedTasks[task.parentId] = [];
            }
            groupedTasks[task.parentId]!.add(task);
          }

          groupedTasks.forEach((key, value) {
            value.sort((a, b) => a.order.compareTo(b.order));
          });

          final colors = [
            const Color(0xFF0066FF),
            const Color(0xFFFFFF00),
            const Color(0xFFFF9900),
            const Color(0xFF00FF00),
            const Color(0xFFFF0000),
          ];

          final icons = [
            Icons.new_releases_outlined,
            Icons.work_outline,
            Icons.fact_check_outlined,
            Icons.check_circle_outline,
            Icons.priority_high_outlined,
          ];

          final columnNames = [
            'Новые задачи',
            'В работе',
            'На проверке',
            'Выполнено',
            'Приоритетные',
          ];

          final parentIdsList = parentIds.toList()..sort();
          final newColumns = parentIdsList.asMap().entries.map((entry) {
            final parentId = entry.value;
            final index = entry.key;
            return KanbanColumn(
              id: parentId,
              name: index < columnNames.length
                  ? columnNames[index]
                  : 'Папка $parentId',
              tasks: groupedTasks[parentId] ?? [],
              color: colors[index % colors.length],
              icon: icons[index % icons.length],
            );
          }).toList();

          setState(() {
            columns = newColumns;
            isLoading = false;
          });
        } else {
          throw Exception('Неверный формат данных');
        }
      } else if (response.statusCode == 403) {
        throw Exception('Ошибка доступа (403). Проверьте токен авторизации.');
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
        // Keep existing demo data if we had it
        if (columns.isEmpty) {
          columns = [];
        }
      });
    }
  }

  Future<bool> updateTask(int taskId, int newParentId, int newOrder) async {
    if (useDemoData) {
      await Future.delayed(const Duration(milliseconds: 300));
      return true;
    }

    try {
      final response = await http.post(
        Uri.parse(
          'https://api.dev.kpi-drive.ru/_api/indicators/save_indicator_instance_field',
        ),
        headers: {'Authorization': 'Bearer $bearerToken'},
        body: {
          'period_start': '2025-09-01',
          'period_end': '2025-09-30',
          'period_key': 'month',
          'indicator_to_mo_id': taskId.toString(),
          'field_name': 'parent_id',
          'field_value': newParentId.toString(),
          'auth_user_id': '40',
        },
      );

      if (response.statusCode == 200) {
        final orderResponse = await http.post(
          Uri.parse(
            'https://api.dev.kpi-drive.ru/_api/indicators/save_indicator_instance_field',
          ),
          headers: {'Authorization': 'Bearer $bearerToken'},
          body: {
            'period_start': '2025-09-01',
            'period_end': '2025-09-30',
            'period_key': 'month',
            'indicator_to_mo_id': taskId.toString(),
            'field_name': 'order',
            'field_value': newOrder.toString(),
            'auth_user_id': '40',
          },
        );

        return orderResponse.statusCode == 200;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void onTaskMoved(Task task, int newColumnId, int newIndex) async {
    final sourceColumn = columns.firstWhere((col) => col.id == task.parentId);
    final sourceIndex = sourceColumn.tasks.indexWhere((t) => t.id == task.id);

    if (sourceIndex == -1) return;

    final movedTask = sourceColumn.tasks.removeAt(sourceIndex);
    final destColumn = columns.firstWhere((col) => col.id == newColumnId);
    destColumn.tasks.insert(newIndex, movedTask);

    for (int i = 0; i < destColumn.tasks.length; i++) {
      destColumn.tasks[i] = destColumn.tasks[i].copyWith(
        parentId: newColumnId,
        order: i,
      );
    }

    if (sourceColumn.id != destColumn.id) {
      for (int i = 0; i < sourceColumn.tasks.length; i++) {
        sourceColumn.tasks[i] = sourceColumn.tasks[i].copyWith(order: i);
      }
    }

    setState(() {});

    final success = await updateTask(task.id, newColumnId, newIndex);

    if (!success && !useDemoData) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Не удалось сохранить изменения')),
            ],
          ),
          backgroundColor: const Color(0xFFFF0000),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      if (useDemoData) {
        loadDemoData();
      } else {
        fetchTasks();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.black26,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.black,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Задача успешно перемещена!',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      task.name.length > 30
                          ? '${task.name.substring(0, 30)}...'
                          : task.name,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF00FF00),
          duration: const Duration(milliseconds: 2000),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void addNewTask(int columnId) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddTaskDialog(
        columnColor: columns.firstWhere((col) => col.id == columnId).color,
      ),
    );

    if (result != null) {
      final column = columns.firstWhere((col) => col.id == columnId);
      final newTask = Task(
        id: DateTime.now().millisecondsSinceEpoch, // Generate unique ID
        parentId: columnId,
        name: result['name'],
        order: column.tasks.length,
        priority: result['priority'] ?? TaskPriority.normal,
        description: result['description'],
        dueDate: result['dueDate'],
      );

      setState(() {
        column.tasks.add(newTask);
      });

      _showSuccessMessage('Задача "${newTask.name}" добавлена!');
    }
  }

  void editTask(Task task) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => EditTaskDialog(
        task: task,
        columnColor: columns.firstWhere((col) => col.id == task.parentId).color,
      ),
    );

    if (result != null) {
      final column = columns.firstWhere((col) => col.id == task.parentId);
      final taskIndex = column.tasks.indexWhere((t) => t.id == task.id);

      if (taskIndex != -1) {
        setState(() {
          column.tasks[taskIndex] = task.copyWith(
            name: result['name'],
            priority: result['priority'],
            description: result['description'],
            dueDate: result['dueDate'],
          );
        });

        _showSuccessMessage('Задача обновлена!');
      }
    }
  }

  void deleteTask(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Удалить задачу?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Вы уверены, что хотите удалить задачу "${task.name}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Отмена',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF0000),
              foregroundColor: Colors.white,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final column = columns.firstWhere((col) => col.id == task.parentId);
      setState(() {
        column.tasks.removeWhere((t) => t.id == task.id);
        // Reorder remaining tasks
        for (int i = 0; i < column.tasks.length; i++) {
          column.tasks[i] = column.tasks[i].copyWith(order: i);
        }
      });

      _showSuccessMessage('Задача "${task.name}" удалена!');
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.black26,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.black,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF00FF00),
        duration: const Duration(milliseconds: 2000),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void toggleMode() {
    setState(() {
      useDemoData = !useDemoData;
    });

    if (useDemoData) {
      loadDemoData();
    } else {
      fetchTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF0000), Color(0xFFFF4444)],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'KPI',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Канбан-доска',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: useDemoData
                  ? const Color(0xFFFFFF00).withOpacity(0.2)
                  : const Color(0xFF0066FF).withOpacity(0.2),
              border: Border.all(
                color: useDemoData
                    ? const Color(0xFFFFFF00)
                    : const Color(0xFF0066FF),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  useDemoData ? Icons.science_outlined : Icons.cloud_outlined,
                  color: useDemoData
                      ? const Color(0xFFFFFF00)
                      : const Color(0xFF0066FF),
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  useDemoData ? 'ДЕМО' : 'API',
                  style: TextStyle(
                    color: useDemoData
                        ? const Color(0xFFFFFF00)
                        : const Color(0xFF0066FF),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              useDemoData ? Icons.cloud_outlined : Icons.science_outlined,
              color: const Color(0xFF00FF00),
            ),
            onPressed: toggleMode,
            tooltip: useDemoData ? 'Переключить на API' : 'Переключить на ДЕМО',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF00FF00)),
            onPressed: useDemoData ? loadDemoData : fetchTasks,
            tooltip: 'Обновить',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      color: const Color(0xFF00FF00),
                      strokeWidth: 5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    useDemoData
                        ? 'Загрузка демо данных...'
                        : 'Загрузка задач...',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            )
          : errorMessage != null
          ? Center(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFF0000), width: 2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF0000),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.error_outline_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Ошибка загрузки',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      errorMessage!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton.icon(
                          onPressed: useDemoData ? loadDemoData : fetchTasks,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Повторить'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00FF00),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              useDemoData = true;
                              errorMessage = null;
                            });
                            loadDemoData();
                          },
                          icon: const Icon(Icons.science_outlined),
                          label: const Text('Демо режим'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFFFF00),
                            side: const BorderSide(color: Color(0xFFFFFF00)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          : columns.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 80,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Нет задач',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(16),
              itemCount: columns.length,
              itemBuilder: (context, index) {
                return KanbanColumnWidget(
                  column: columns[index],
                  onTaskMoved: onTaskMoved,
                  onAddTask: () => addNewTask(columns[index].id),
                  onEditTask: editTask,
                  onDeleteTask: deleteTask,
                );
              },
            ),
    );
  }
}

class KanbanColumnWidget extends StatelessWidget {
  final KanbanColumn column;
  final Function(Task, int, int) onTaskMoved;
  final VoidCallback onAddTask;
  final Function(Task) onEditTask;
  final Function(Task) onDeleteTask;

  const KanbanColumnWidget({
    Key? key,
    required this.column,
    required this.onTaskMoved,
    required this.onAddTask,
    required this.onEditTask,
    required this.onDeleteTask,
  }) : super(key: key);

  IconData _getColumnIcon() {
    return column.icon ?? Icons.folder_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  column.color.withOpacity(0.3),
                  column.color.withOpacity(0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: column.color, width: 2),
              boxShadow: [
                BoxShadow(
                  color: column.color.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: column.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: column.color.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Icon(_getColumnIcon(), color: column.color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        column.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        column.tasks.isEmpty
                            ? 'Нет задач'
                            : '${column.tasks.length} ${_getTasksWord(column.tasks.length)}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: column.color,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: column.color.withOpacity(0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '${column.tasks.length}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: DragTarget<Task>(
              onWillAccept: (task) => task != null,
              onAccept: (task) {
                if (task.parentId != column.id) {
                  onTaskMoved(task, column.id, column.tasks.length);
                }
              },
              builder: (context, candidateData, rejectedData) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    gradient: candidateData.isNotEmpty
                        ? LinearGradient(
                            colors: [
                              column.color.withOpacity(0.2),
                              column.color.withOpacity(0.05),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          )
                        : LinearGradient(
                            colors: [
                              const Color(0xFF2A2A2A).withOpacity(0.5),
                              const Color(0xFF1F1F1F).withOpacity(0.3),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: candidateData.isNotEmpty
                          ? column.color
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: column.tasks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_task_outlined,
                                color: Colors.white.withOpacity(0.3),
                                size: 56,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Перетащите задачу сюда',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'или создайте новую',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.25),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: onAddTask,
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Добавить задачу'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: column.color,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: column.tasks.length,
                                itemBuilder: (context, index) {
                                  return TaskCard(
                                    task: column.tasks[index],
                                    columnId: column.id,
                                    index: index,
                                    onTaskMoved: onTaskMoved,
                                    columnColor: column.color,
                                    onEditTask: onEditTask,
                                    onDeleteTask: onDeleteTask,
                                  );
                                },
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.all(16),
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: onAddTask,
                                icon: Icon(
                                  Icons.add,
                                  color: column.color,
                                  size: 18,
                                ),
                                label: Text(
                                  'Добавить задачу',
                                  style: TextStyle(color: column.color),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: column.color.withOpacity(0.5),
                                  ),
                                  backgroundColor: column.color.withOpacity(
                                    0.05,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getTasksWord(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return 'задача';
    } else if ((count % 10 >= 2 && count % 10 <= 4) &&
        !(count % 100 >= 12 && count % 100 <= 14)) {
      return 'задачи';
    } else {
      return 'задач';
    }
  }
}

class TaskCard extends StatelessWidget {
  final Task task;
  final int columnId;
  final int index;
  final Function(Task, int, int) onTaskMoved;
  final Color columnColor;
  final Function(Task) onEditTask;
  final Function(Task) onDeleteTask;

  const TaskCard({
    Key? key,
    required this.task,
    required this.columnId,
    required this.index,
    required this.onTaskMoved,
    required this.columnColor,
    required this.onEditTask,
    required this.onDeleteTask,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DragTarget<Task>(
      onWillAccept: (draggedTask) =>
          draggedTask != null && draggedTask.id != task.id,
      onAccept: (draggedTask) {
        onTaskMoved(draggedTask, columnId, index);
      },
      builder: (context, candidateData, rejectedData) {
        return LongPressDraggable<Task>(
          data: task,
          dragAnchorStrategy: pointerDragAnchorStrategy,
          feedback: Material(
            elevation: 15,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [columnColor, columnColor.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: columnColor.withOpacity(0.6),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: task.priority.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      task.name,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.drag_indicator,
                    color: Colors.black.withOpacity(0.7),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          childWhenDragging: Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 80,
            decoration: BoxDecoration(
              color: columnColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: columnColor.withOpacity(0.3),
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: Center(
              child: Text(
                'Перемещение...',
                style: TextStyle(
                  color: columnColor.withOpacity(0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          child: candidateData.isNotEmpty
              ? Column(
                  children: [
                    Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: columnColor,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: columnColor.withOpacity(0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    _buildCard(context),
                  ],
                )
              : _buildCard(context),
        );
      },
    );
  }

  Widget _buildCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF3A3A3A), const Color(0xFF2F2F2F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: columnColor.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: columnColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showTaskDetails(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: task.priority.color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: task.priority.color.withOpacity(0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        task.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: Colors.white.withOpacity(0.6),
                        size: 16,
                      ),
                      color: const Color(0xFF2A2A2A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            onEditTask(task);
                            break;
                          case 'delete':
                            onDeleteTask(task);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: columnColor, size: 16),
                              const SizedBox(width: 8),
                              const Text(
                                'Редактировать',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: const Row(
                            children: [
                              Icon(
                                Icons.delete,
                                color: Color(0xFFFF0000),
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Удалить',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (task.description != null &&
                    task.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    task.description!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildTag('№${task.order + 1}', columnColor),
                    const SizedBox(width: 8),
                    _buildTag(task.priority.label, task.priority.color),
                    const Spacer(),
                    if (task.dueDate != null) _buildDateTag(task.dueDate!),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTaskDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF2A2A2A), const Color(0xFF1F1F1F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: columnColor.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: columnColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.task_alt_rounded,
                      color: columnColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Детали задачи',
                          style: TextStyle(
                            color: columnColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'ID: ${task.id}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF3A3A3A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: columnColor.withOpacity(0.3)),
                ),
                child: Text(
                  task.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      'Позиция',
                      '${task.order + 1}',
                      Icons.reorder_rounded,
                      columnColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDetailItem(
                      'Колонка',
                      '${task.parentId}',
                      Icons.folder_rounded,
                      const Color(0xFF0066FF),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color == const Color(0xFF666666) ? Colors.white70 : color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDateTag(DateTime date) {
    final now = DateTime.now();
    final isOverdue = date.isBefore(now);
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;

    Color color = const Color(0xFF0066FF);
    if (isOverdue) {
      color = const Color(0xFFFF0000);
    } else if (isToday) {
      color = const Color(0xFFFF9900);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today, color: color, size: 10),
          const SizedBox(width: 4),
          Text(
            '${date.day}/${date.month}',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Dialog widgets
class AddTaskDialog extends StatefulWidget {
  final Color columnColor;

  const AddTaskDialog({Key? key, required this.columnColor}) : super(key: key);

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  TaskPriority _priority = TaskPriority.normal;
  DateTime? _dueDate;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.columnColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.add_task,
                    color: widget.columnColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Новая задача',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Название задачи',
                labelStyle: const TextStyle(color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: widget.columnColor.withOpacity(0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: widget.columnColor),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Описание (необязательно)',
                labelStyle: const TextStyle(color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: widget.columnColor.withOpacity(0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: widget.columnColor),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Приоритет',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<TaskPriority>(
                        value: _priority,
                        dropdownColor: const Color(0xFF2A2A2A),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: widget.columnColor.withOpacity(0.5),
                            ),
                          ),
                        ),
                        items: TaskPriority.values
                            .map(
                              (priority) => DropdownMenuItem(
                                value: priority,
                                child: Row(
                                  children: [
                                    Icon(
                                      priority.icon,
                                      color: priority.color,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(priority.label),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _priority = value!),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Срок выполнения',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          setState(() => _dueDate = date);
                        },
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          _dueDate == null
                              ? 'Выбрать'
                              : '${_dueDate!.day}/${_dueDate!.month}',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: BorderSide(
                            color: widget.columnColor.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Отмена',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _nameController.text.trim().isEmpty
                      ? null
                      : () {
                          Navigator.of(context).pop({
                            'name': _nameController.text.trim(),
                            'description':
                                _descriptionController.text.trim().isEmpty
                                ? null
                                : _descriptionController.text.trim(),
                            'priority': _priority,
                            'dueDate': _dueDate,
                          });
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.columnColor,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Создать'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class EditTaskDialog extends StatefulWidget {
  final Task task;
  final Color columnColor;

  const EditTaskDialog({
    Key? key,
    required this.task,
    required this.columnColor,
  }) : super(key: key);

  @override
  State<EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<EditTaskDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late TaskPriority _priority;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.task.name);
    _descriptionController = TextEditingController(
      text: widget.task.description ?? '',
    );
    _priority = widget.task.priority;
    _dueDate = widget.task.dueDate;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.columnColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.edit, color: widget.columnColor, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Редактировать задачу',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Название задачи',
                labelStyle: const TextStyle(color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: widget.columnColor.withOpacity(0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: widget.columnColor),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Описание (необязательно)',
                labelStyle: const TextStyle(color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: widget.columnColor.withOpacity(0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: widget.columnColor),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Приоритет',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<TaskPriority>(
                        value: _priority,
                        dropdownColor: const Color(0xFF2A2A2A),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: widget.columnColor.withOpacity(0.5),
                            ),
                          ),
                        ),
                        items: TaskPriority.values
                            .map(
                              (priority) => DropdownMenuItem(
                                value: priority,
                                child: Row(
                                  children: [
                                    Icon(
                                      priority.icon,
                                      color: priority.color,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(priority.label),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _priority = value!),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Срок выполнения',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _dueDate ?? DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 365),
                                  ),
                                );
                                setState(() => _dueDate = date);
                              },
                              icon: const Icon(Icons.calendar_today, size: 16),
                              label: Text(
                                _dueDate == null
                                    ? 'Выбрать'
                                    : '${_dueDate!.day}/${_dueDate!.month}',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white70,
                                side: BorderSide(
                                  color: widget.columnColor.withOpacity(0.5),
                                ),
                              ),
                            ),
                          ),
                          if (_dueDate != null) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => setState(() => _dueDate = null),
                              icon: const Icon(Icons.clear, size: 16),
                              style: IconButton.styleFrom(
                                foregroundColor: Colors.white70,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Отмена',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _nameController.text.trim().isEmpty
                      ? null
                      : () {
                          Navigator.of(context).pop({
                            'name': _nameController.text.trim(),
                            'description':
                                _descriptionController.text.trim().isEmpty
                                ? null
                                : _descriptionController.text.trim(),
                            'priority': _priority,
                            'dueDate': _dueDate,
                          });
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.columnColor,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Сохранить'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
