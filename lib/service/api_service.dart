import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task.dart';

class ApiService {
  final String _baseUrl = 'https://api.dev.kpi-drive.ru/_api/indicators';
  final String _token = '5c3964b8e3ee4755f2cc0febb851e2f8'; // Ваш Bearer Token
  final String _authUserId = '40';

  // 1. Заголовки для авторизации
  Map<String, String> get _headers => {
    // Добавляем заголовок Authorization с типом Bearer
    'Authorization': 'Bearer $_token',
    // Content-Type: multipart/form-data устанавливается автоматически
    // при использовании http.MultipartRequest, но можно добавить его явно,
    // если в будущем будете использовать другой тип запроса.
  };

  // Фиксированные параметры запроса (для тела form-data)
  Map<String, String> get _baseFields => {
    'period_start': '2025-09-01',
    'period_end': '2025-09-30',
    'period_key': 'month',
    'auth_user_id': _authUserId,
  };

  /// Запрос на получение задач (POST)
  Future<List<Task>> fetchTasks() async {
    final uri = Uri.parse('$_baseUrl/get_mo_indicators');

    // 2. Формируем тело для form-data
    var fields = {
      ..._baseFields,
      'requested_mo_id': '42',
      'behaviour_key': 'task,kpi_task',
      'with_result': 'false',
      'response_fields': 'name,indicator_to_mo_id,parent_id,order',
    };

    // 3. Используем MultipartRequest для отправки form-data
    var request = http.MultipartRequest('POST', uri);

    // Добавляем заголовки (включая токен)
    request.headers.addAll(_headers);

    // Добавляем поля form-data
    request.fields.addAll(fields);

    // 4. Отправляем и обрабатываем ответ
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(responseBody);
      // Предполагаем, что данные находятся в ключе 'data'
      final List<dynamic> rawList = jsonResponse['data'] ?? [];
      return rawList.map((json) => Task.fromJson(json)).toList();
    } else {
      // Бросаем ошибку для обработки во ViewModel
      throw Exception(
        'Ошибка загрузки задач. Код: ${response.statusCode}. Ответ: $responseBody',
      );
    }
  }

  /// 2. Запрос на сохранение полей задачи (POST)
  Future<void> saveTaskField({
    required String indicatorToMoId,
    required String fieldName,
    required String fieldValue,
  }) async {
    final uri = Uri.parse('$_baseUrl/save_indicator_instance_field');

    var fields = {
      ..._baseFields,
      'indicator_to_mo_id': indicatorToMoId,
      'field_name': fieldName,
      'field_value': fieldValue,
    };

    var request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_headers);
    request.fields.addAll(fields);

    final response = await request.send();

    if (response.statusCode != 200) {
      final responseBody = await response.stream.bytesToString();
      // Бросаем ошибку, чтобы ViewModel мог откатить изменения
      throw Exception(
        'Ошибка сохранения $fieldName: ${response.statusCode} - $responseBody',
      );
    }
  }
}
