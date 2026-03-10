import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  Future<ShareResult> shareText(String text, {String subject = 'Runner Scan Data'}) async {
    return await Share.share(
      text,
      subject: subject,
    );
  }

  Future<ShareResult> shareFile(String content, String fileName) async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(content);
      
      final result = await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Runner Scan Data',
      );
      
      // Clean up
      await file.delete();
      
      return result;
    } catch (e) {
      throw Exception('Failed to share file: $e');
    }
  }

  Future<ShareResult> exportScans(String csvData) async {
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
    final fileName = 'runner_scans_$timestamp.csv';
    return await shareFile(csvData, fileName);
  }
}
