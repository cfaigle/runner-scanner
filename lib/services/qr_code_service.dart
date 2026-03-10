import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../models/models.dart';

class QRCodeService {
  final Uuid _uuid = const Uuid();

  String generateRunnerQRCode(Runner runner) {
    final data = {
      'id': runner.id,
      'name': runner.name,
      'dob': _formatDate(runner.dateOfBirth),
    };
    return jsonEncode(data);
  }

  Runner parseRunnerQRCode(String qrData) {
    return Runner.fromJson(qrData);
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String generateRunnerId() {
    return _uuid.v4().substring(0, 8).toUpperCase();
  }
}
