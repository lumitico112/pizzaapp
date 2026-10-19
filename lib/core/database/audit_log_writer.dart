import 'package:sqflite_sqlcipher/sqflite.dart';

/// Writes audit events through the same transaction as the business change.
class AuditLogWriter {
  const AuditLogWriter._();

  static Future<void> record(
    DatabaseExecutor executor, {
    required String action,
    required String detail,
    int? userId,
  }) async {
    await executor.insert('LogAuditoria', {
      'usuario_id': userId,
      'accion': action,
      'detalle': detail,
      'fecha': DateTime.now().toIso8601String(),
    });
  }
}
