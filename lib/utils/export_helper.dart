import 'package:flutter/material.dart';
import '../core/services/export_service.dart';

class ExportHelper {
  static void showExportMenu(BuildContext context, Function(ExportFormat) onExport) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('خيارات التصدير والطباعة', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('تصدير كـ PDF'),
              onTap: () {
                Navigator.pop(ctx);
                onExport(ExportFormat.pdf);
              },
            ),
            ListTile(
              leading: const Icon(Icons.print, color: Colors.blue),
              title: const Text('طباعة مباشرة'),
              onTap: () {
                Navigator.pop(ctx);
                onExport(ExportFormat.print);
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('تصدير كـ CSV (إكسل)'),
              onTap: () {
                Navigator.pop(ctx);
                onExport(ExportFormat.csv);
              },
            ),
            ListTile(
              leading: const Icon(Icons.text_snippet, color: Colors.grey),
              title: const Text('تصدير كـ TXT'),
              onTap: () {
                Navigator.pop(ctx);
                onExport(ExportFormat.txt);
              },
            ),
          ],
        ),
      ),
    );
  }
}
