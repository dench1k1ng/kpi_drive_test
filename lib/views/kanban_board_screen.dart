// import 'package:flutter/material.dart';
// import 'package:kanban_board/kanban_board.dart';
// import 'package:provider/provider.dart';

// import '../view_model.dart';
// import '../models/task.dart';
// import '../core/theme/colors.dart';
// import 'kpi_task_card.dart';

// class KanbanBoardScreen extends StatefulWidget {
//   const KanbanBoardScreen({super.key});

//   @override
//   State<KanbanBoardScreen> createState() => _KanbanBoardScreenState();
// }

// class _KanbanBoardScreenState extends State<KanbanBoardScreen> {
//   final KanbanBoardController _controller = KanbanBoardController();

//   @override
//   void initState() {
//     super.initState();
//     // Начинаем загрузку данных при инициализации
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       Provider.of<KanbanViewModel>(context, listen: false).fetchTasks();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'КАНБАН-ДОСКА (KPI-DRIVE)',
//           style: TextStyle(color: Colors.white),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh, color: Colors.green),
//             onPressed: () => Provider.of<KanbanViewModel>(
//               context,
//               listen: false,
//             ).fetchTasks(),
//           ),
//         ],
//       ),
//       // Используем Row для создания Sidebar + KanbanBoard
//       body: Row(
//         children: [
//           // 1. Sidebar (Обязательная деталь дизайна KPI-DRIVE)
//           _buildSidebar(),

//           // 2. Kanban Board (основной контент)
//           Expanded(
//             child: Consumer<KanbanViewModel>(
//               builder: (context, viewModel, child) {
//                 // Показываем ошибку если есть
//                 if (viewModel.errorMessage != null) {
//                   return Column(
//                     children: [
//                       Container(
//                         width: double.infinity,
//                         padding: const EdgeInsets.all(16),
//                         color: Colors.red.shade900,
//                         child: Row(
//                           children: [
//                             const Icon(Icons.error, color: Colors.white),
//                             const SizedBox(width: 8),
//                             Expanded(
//                               child: Text(
//                                 viewModel.errorMessage!,
//                                 style: const TextStyle(color: Colors.white),
//                               ),
//                             ),
//                             IconButton(
//                               icon: const Icon(
//                                 Icons.close,
//                                 color: Colors.white,
//                               ),
//                               onPressed: viewModel.clearErrorMessage,
//                             ),
//                           ],
//                         ),
//                       ),
//                       Expanded(child: _buildKanbanContent(viewModel)),
//                     ],
//                   );
//                 }

//                 return _buildKanbanContent(viewModel);
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildKanbanContent(KanbanViewModel viewModel) {
//     if (viewModel.isLoading && viewModel.groups.isEmpty) {
//       return const Center(child: CircularProgressIndicator(color: Colors.blue));
//     }

//     if (viewModel.groups.isEmpty) {
//       return const Center(
//         child: Text("Задач не найдено.", style: TextStyle(color: Colors.grey)),
//       );
//     }

//     return Container(
//       color: KpiColors.background,
//       child: KanbanBoard(
//         controller: _controller,
//         groups: viewModel.groups,
//         groupItemBuilder: _buildTaskCard,
//         onGroupItemMove:
//             (oldGroupIndex, oldItemIndex, newGroupIndex, newItemIndex) {
//               if (oldGroupIndex != null &&
//                   oldItemIndex != null &&
//                   newGroupIndex != null &&
//                   newItemIndex != null) {
//                 viewModel.onGroupItemMove(
//                   oldGroupIndex,
//                   oldItemIndex,
//                   newGroupIndex,
//                   newItemIndex,
//                 );
//               }
//             },
//         onGroupMove: (oldGroupIndex, newGroupIndex) {
//           // Обработка перемещения групп (колонок) - не требуется для ТЗ
//           print('Group moved from $oldGroupIndex to $newGroupIndex');
//         },
//         groupConstraints: const BoxConstraints(minWidth: 300, maxWidth: 300),
//       ),
//     );
//   }

//   // Билдер для карточки задачи
//   Widget _buildTaskCard(BuildContext context, String groupId, int itemIndex) {
//     final group = context.read<KanbanViewModel>().groups.firstWhere(
//       (g) => g.id == groupId,
//     );
//     final task = group.items[itemIndex];

//     return KpiTaskCard(task: task);
//   }

//   // Вспомогательный метод для Sidebar
//   Widget _buildSidebar() {
//     // Стиль Sidebar (темный, с узкими цветными полосками)
//     return Container(
//       width: 50, // Узкая ширина
//       color: const Color(0xFF2C2C2C),
//       padding: const EdgeInsets.only(top: 10),
//       child: Column(
//         children: [
//           _buildSidebarItem('KPI', KpiColors.blue),
//           _buildSidebarItem('ПЛАН', KpiColors.green),
//           _buildSidebarItem('ФАКТ', KpiColors.yellow),
//           _buildSidebarItem('РИСК', KpiColors.red),
//         ],
//       ),
//     );
//   }

//   // Вспомогательный метод для элемента Sidebar
//   Widget _buildSidebarItem(String text, Color color) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 10),
//       padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
//       decoration: BoxDecoration(
//         border: Border(left: BorderSide(color: color, width: 4)),
//       ),
//       child: RotatedBox(
//         quarterTurns: 3, // Поворот текста на 90 градусов
//         child: Text(
//           text,
//           style: TextStyle(
//             color: color,
//             fontSize: 10,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ),
//     );
//   }
// }
