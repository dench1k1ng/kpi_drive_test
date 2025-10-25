import 'package:flutter/material.dart';
import '../models/task.dart';
import '../core/theme/colors.dart';

class KpiTaskCard extends StatelessWidget {
  final Task task;

  const KpiTaskCard({Key? key, required this.task}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: KpiColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade700, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок задачи
            Text(
              task.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // KPI показатели
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildKpiIndicator(
                  'Вес',
                  task.weight.toString(),
                  KpiColors.blue,
                ),
                _buildKpiIndicator(
                  'Факт',
                  task.fact.toString(),
                  KpiColors.green,
                ),
                _buildKpiIndicator(
                  '${task.percent}%',
                  '',
                  _getPercentColor(task.percent),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Прогресс-бар
            LinearProgressIndicator(
              value: task.percent / 100,
              backgroundColor: Colors.grey.shade700,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getPercentColor(task.percent),
              ),
            ),

            const SizedBox(height: 4),

            // ID задачи (для отладки)
            Text(
              'ID: ${task.taskId}',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiIndicator(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (value.isNotEmpty)
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  Color _getPercentColor(int percent) {
    if (percent >= 80) return KpiColors.green;
    if (percent >= 50) return KpiColors.yellow;
    return KpiColors.red;
  }
}
