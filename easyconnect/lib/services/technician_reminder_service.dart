import 'dart:convert';
import 'package:easyconnect/Models/technician_reminder_model.dart';
import 'package:easyconnect/utils/app_config.dart';
import 'package:easyconnect/services/api_service.dart';
import 'package:easyconnect/utils/auth_error_handler.dart';
import 'package:easyconnect/services/http_interceptor.dart';

class TechnicianReminderService {
  String get _baseUrl => AppConfig.baseUrl;

  Future<List<TechnicianReminder>> getList({
    String? status,
    int page = 1,
    int perPage = 50,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    if (status != null && status.isNotEmpty) params['status'] = status;
    final uri = Uri.parse('$_baseUrl/technician-reminders-list').replace(queryParameters: params);
    final response = await HttpInterceptor.get(uri, headers: await ApiService.headersAsync());
    await AuthErrorHandler.handleHttpResponse(response);
    if (response.statusCode != 200) throw Exception('Erreur ${response.statusCode}');
    final data = jsonDecode(response.body);
    final list = data['data'] as List<dynamic>? ?? [];
    return list.map((e) => TechnicianReminder.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<TechnicianReminder> getOne(int id) async {
    final response = await HttpInterceptor.get(
      Uri.parse('$_baseUrl/technician-reminders-show/$id'),
      headers: await ApiService.headersAsync(),
    );
    await AuthErrorHandler.handleHttpResponse(response);
    if (response.statusCode != 200) throw Exception('Rappel introuvable');
    final data = jsonDecode(response.body);
    return TechnicianReminder.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<TechnicianReminder> create({
    required String title,
    String? notes,
    int? clientId,
    String? companyName,
    required DateTime dueDate,
    required int remindDaysBefore,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'due_date': dueDate.toIso8601String().split('T').first,
      'remind_days_before': remindDaysBefore,
    };
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;
    if (clientId != null) body['client_id'] = clientId;
    if (companyName != null && companyName.isNotEmpty) body['company_name'] = companyName;

    final response = await HttpInterceptor.post(
      Uri.parse('$_baseUrl/technician-reminders-create'),
      headers: await ApiService.headersAsync(),
      body: jsonEncode(body),
    );
    await AuthErrorHandler.handleHttpResponse(response);
    if (response.statusCode != 201) {
      final msg = (jsonDecode(response.body) as Map?)?['message'] ?? response.body;
      throw Exception(msg);
    }
    final data = jsonDecode(response.body);
    return TechnicianReminder.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<TechnicianReminder> update(int id, {String? title, String? notes, int? clientId, String? companyName, DateTime? dueDate, int? remindDaysBefore, String? status}) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (notes != null) body['notes'] = notes;
    if (clientId != null) body['client_id'] = clientId;
    if (companyName != null) body['company_name'] = companyName;
    if (dueDate != null) body['due_date'] = dueDate.toIso8601String().split('T').first;
    if (remindDaysBefore != null) body['remind_days_before'] = remindDaysBefore;
    if (status != null) body['status'] = status;

    final response = await HttpInterceptor.put(
      Uri.parse('$_baseUrl/technician-reminders-update/$id'),
      headers: await ApiService.headersAsync(),
      body: jsonEncode(body),
    );
    await AuthErrorHandler.handleHttpResponse(response);
    if (response.statusCode != 200) throw Exception('Erreur lors de la mise à jour');
    final data = jsonDecode(response.body);
    return TechnicianReminder.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> delete(int id) async {
    final response = await HttpInterceptor.delete(
      Uri.parse('$_baseUrl/technician-reminders-destroy/$id'),
      headers: await ApiService.headersAsync(),
    );
    await AuthErrorHandler.handleHttpResponse(response);
    if (response.statusCode != 200) throw Exception('Erreur lors de la suppression');
  }

  Future<TechnicianReminder> markDone(int id) async {
    final response = await HttpInterceptor.post(
      Uri.parse('$_baseUrl/technician-reminders-mark-done/$id'),
      headers: await ApiService.headersAsync(),
      body: jsonEncode({}),
    );
    await AuthErrorHandler.handleHttpResponse(response);
    if (response.statusCode != 200) throw Exception('Erreur');
    final data = jsonDecode(response.body);
    return TechnicianReminder.fromJson(data['data'] as Map<String, dynamic>);
  }
}
