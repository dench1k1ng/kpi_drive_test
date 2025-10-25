import 'package:flutter/material.dart';
import 'package:kpi_drive_test/views/kanban_board_screen_clean.dart';
import 'package:kpi_drive_test/views/kanban_board_screen_new.dart';
import 'package:provider/provider.dart';
import 'view_model.dart';
import 'views/kanban_board_screen.dart';

void main() {
  runApp(const KanbanApp());
}

class KanbanApp extends StatelessWidget {
  const KanbanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => KanbanViewModel())],
      child: MaterialApp(
        title: 'KPI Kanban',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          // Темный фон, как в KPI-DRIVE
          scaffoldBackgroundColor: const Color(0xFF1B1B1B),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF2C2C2C),
            elevation: 0,
          ),
          textTheme: TextTheme(
            bodyLarge: TextStyle(color: Colors.grey[200]),
            bodyMedium: TextStyle(color: Colors.grey[400]),
            titleLarge: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF1E88E5), // Синий KPI
            secondary: Color(0xFFD32F2F), // Красный KPI
            surface: Color(0xFF2C2C2C), // Фон для карточек и колонок
          ),
          useMaterial3:
              false, // Используем Material 2 для простоты стилизации под скриншот
        ),
        home: const KanbanBoardScreen(),
      ),
    );
  }
}
