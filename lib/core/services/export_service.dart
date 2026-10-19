import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/haircut.dart';
import '../models/owner_payment.dart';

// Helper to load image assets for PDF (e.g., app logo)
Future<pw.ImageProvider> _loadPdfLogo() async {
  final data = await rootBundle.load('src/assets/logoapp.png');
  return pw.MemoryImage(data.buffer.asUint8List());
}

enum ExportFormat { pdf, csv, txt, print }

class ExportService {
  Future<pw.Font> _getArabicFont() async {
    final fontData = await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
    return pw.Font.ttf(fontData);
  }

  Future<pw.Font> _getArabicBoldFont() async {
    final fontData = await rootBundle.load('assets/fonts/Amiri-Bold.ttf');
    return pw.Font.ttf(fontData);
  }

  // ===================== PDF Export / Printing =====================

  Future<void> printOrExportPdf({
    required String title,
    required String dateInfo,
    required List<pw.Widget> content,
    bool isDirectPrint = false,
  }) async {
    final pdf = pw.Document();
    final font = await _getArabicFont();
    final boldFont = await _getArabicBoldFont();
    final logo = await _loadPdfLogo();

    // Optional cover page with logo and title
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        build: (context) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Center(child: pw.Image(logo, width: 120, height: 120)),
              pw.SizedBox(height: 24),
              pw.Text('صالون الحلاقة', style: pw.TextStyle(font: boldFont, fontSize: 28), textDirection: pw.TextDirection.rtl),
              pw.SizedBox(height: 16),
              pw.Text(title, style: pw.TextStyle(font: boldFont, fontSize: 22), textDirection: pw.TextDirection.rtl),
              pw.Text(dateInfo, style: pw.TextStyle(font: font, fontSize: 16), textDirection: pw.TextDirection.rtl),
            ],
          ),
        ),
      ),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        header: (context) => _buildPdfHeader(title, dateInfo, font, boldFont),
        footer: (context) => _buildPdfFooter(context, font),
        build: (context) => content,
      ),
    );

    if (isDirectPrint) {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: title,
      );
    } else {
      await Printing.sharePdf(bytes: await pdf.save(), filename: '$title.pdf');
    }
  }

  pw.Widget _buildPdfHeader(String title, String dateInfo, pw.Font font, pw.Font boldFont) {
    return pw.Directionality(
      textDirection: pw.TextDirection.rtl,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text('صالون الحلاقة', style: pw.TextStyle(font: boldFont, fontSize: 24), textDirection: pw.TextDirection.rtl),
          pw.SizedBox(height: 8),
          pw.Text(title, style: pw.TextStyle(font: boldFont, fontSize: 18), textDirection: pw.TextDirection.rtl),
          pw.Text(dateInfo, style: pw.TextStyle(font: font, fontSize: 14), textDirection: pw.TextDirection.rtl),
          pw.Divider(),
          pw.SizedBox(height: 16),
        ],
      ),
    );
  }

  pw.Widget _buildPdfFooter(pw.Context context, pw.Font font) {
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        'صفحة ${context.pageNumber} من ${context.pagesCount} - تم الإنشاء: ${DateTime.now().toString().substring(0, 16)}',
        style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey),
        textDirection: pw.TextDirection.rtl,
      ),
    );
  }

  // ===================== TXT Export =====================

  Future<void> exportTxt({required String title, required String content}) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$title.txt');
    await file.writeAsString(content);
    await Share.shareXFiles([XFile(file.path)], text: 'مرفق تقرير $title');
  }

  // ===================== CSV Export =====================

  Future<void> exportCsv({required String title, required String csvContent}) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$title.csv');
    
    // Add UTF-8 BOM so Excel opens it with correct Arabic encoding
    final bytes = [0xEF, 0xBB, 0xBF];
    bytes.addAll(csvContent.codeUnits);
    
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], text: 'مرفق تقرير $title');
  }

  // ===================== SPECIFIC REPORTS =====================

  Future<void> exportHaircutsReport(List<Haircut> haircuts, String dateInfo, ExportFormat format) async {
    final title = 'تقرير الحلاقات';
    
    if (format == ExportFormat.txt) {
      String txt = "--- $title ---\nتاريخ: $dateInfo\n\n";
      for (var h in haircuts) {
        txt += "عملية: ${h.operationNumber} | الوقت: ${h.time} | المستلم: ${h.amountReceived}\n";
      }
      await exportTxt(title: title, content: txt);
      return;
    }

    if (format == ExportFormat.csv) {
      // Escape commas and newlines for CSV compatibility
      String _escape(String s) => '"' + s.replaceAll('"', '""') + '"';
      String csv = "${_escape('العملية')},${_escape('الوقت')},${_escape('الخدمات')},${_escape('المستلم')}\n";
      for (var h in haircuts) {
        final servicesStr = h.services.map((s) => s.name).join(' - ');
        csv += "${_escape(h.operationNumber.toString())},${_escape(h.time)},${_escape(servicesStr)},${_escape(h.amountReceived.toString())}\n";
      }
      await exportCsv(title: title, csvContent: csv);
      return;
    }

    // PDF / Print
    final font = await _getArabicFont();
    final headers = ['العملية', 'الوقت', 'الخدمات', 'المستلم'];
    final data = haircuts.map((h) => [
      h.operationNumber,
      h.time,
      h.services.map((s) => s.name).join('، '),
      h.amountReceived.toString()
    ]).toList();

    final table = pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      cellStyle: pw.TextStyle(font: font, fontSize: 10),
      headerStyle: pw.TextStyle(font: font, fontSize: 12, fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellAlignment: pw.Alignment.center,
    );

    await printOrExportPdf(
      title: title,
      dateInfo: dateInfo,
      content: [table],
      isDirectPrint: format == ExportFormat.print,
    );
  }

  Future<void> exportDailyIncomeReport(String dateInfo, double totalIncome, double totalReceived, double expenses, double netIncome, double ownerShare, double ownerDelivered, List<OwnerPayment> ownerPayments, ExportFormat format) async {
    final title = 'تقرير الدخل اليومي';
    
    if (format == ExportFormat.txt) {
      String txt = "--- $title ---\nتاريخ: $dateInfo\n\n";
      txt += "إجمالي الدخل: $totalIncome\n";
      txt += "إجمالي المستلم: $totalReceived\n";
      txt += "الصرفة: $expenses\n";
      txt += "صافي الدخل: $netIncome\n";
      txt += "حصة صاحب المحل: $ownerShare\n";
      txt += "مخروجات صاحب المحل: $ownerDelivered\n";
      txt += "المبلغ المستحق لصاحب المحل: ${ownerShare - ownerDelivered}\n";
      txt += "حصة العامل: $ownerShare\n";
      if (ownerPayments.isNotEmpty) {
        txt += "\n--- تفاصيل مخروجات صاحب المحل ---\n";
        for (var p in ownerPayments) {
          txt += "الوقت: ${p.time} | المبلغ: ${p.amount} | السبب: ${p.note ?? ''}\n";
        }
      }
      await exportTxt(title: title, content: txt);
      return;
    }

    if (format == ExportFormat.csv) {
      String _escape(String s) => '"' + s.replaceAll('"', '""') + '"';
      String csv = "${_escape('إجمالي الدخل')},${_escape('إجمالي المستلم')},${_escape('الصرفة')},${_escape('صافي الدخل')},${_escape('حصة صاحب المحل')},${_escape('مخروجات صاحب المحل')},${_escape('المبلغ المستحق لصاحب المحل')}\n";
      csv += "${_escape(totalIncome.toString())},${_escape(totalReceived.toString())},${_escape(expenses.toString())},${_escape(netIncome.toString())},${_escape(ownerShare.toString())},${_escape(ownerDelivered.toString())},${_escape((ownerShare - ownerDelivered).toString())}\n";
      await exportCsv(title: title, csvContent: csv);
      return;
    }

    final font = await _getArabicFont();
    final boldFont = await _getArabicBoldFont();

    final content = [
      pw.Text('إجمالي الدخل: $totalIncome', style: pw.TextStyle(font: font, fontSize: 14), textDirection: pw.TextDirection.rtl),
      pw.Text('المستلم الفعلي: $totalReceived', style: pw.TextStyle(font: font, fontSize: 14), textDirection: pw.TextDirection.rtl),
      pw.Text('الصرفة: $expenses', style: pw.TextStyle(font: font, fontSize: 14), textDirection: pw.TextDirection.rtl),
      pw.Divider(),
      pw.Text('صافي الدخل: $netIncome', style: pw.TextStyle(font: boldFont, fontSize: 16), textDirection: pw.TextDirection.rtl),
      pw.SizedBox(height: 10),
      pw.Text('حصة صاحب المحل: $ownerShare', style: pw.TextStyle(font: font, fontSize: 14), textDirection: pw.TextDirection.rtl),
      pw.Text('مخروجات صاحب المحل: $ownerDelivered', style: pw.TextStyle(font: font, fontSize: 14), textDirection: pw.TextDirection.rtl),
      pw.Text('المبلغ المستحق لصاحب المحل: ${ownerShare - ownerDelivered}', style: pw.TextStyle(font: boldFont, fontSize: 14), textDirection: pw.TextDirection.rtl),
      pw.Text('حصة العامل: $ownerShare', style: pw.TextStyle(font: boldFont, fontSize: 14), textDirection: pw.TextDirection.rtl),
    ];

    if (ownerPayments.isNotEmpty) {
      content.add(pw.SizedBox(height: 20));
      content.add(pw.Text('تفاصيل مخروجات صاحب المحل:', style: pw.TextStyle(font: boldFont, fontSize: 16), textDirection: pw.TextDirection.rtl));
      content.add(pw.SizedBox(height: 8));
      
      final headers = ['المبلغ', 'الوقت', 'السبب'];
      final data = ownerPayments.map((p) => [
        p.amount.toString(),
        p.time,
        p.note ?? '',
      ]).toList();

      final table = pw.TableHelper.fromTextArray(
        headers: headers,
        data: data,
        cellStyle: pw.TextStyle(font: font, fontSize: 10),
        headerStyle: pw.TextStyle(font: font, fontSize: 12, fontWeight: pw.FontWeight.bold),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
        cellAlignment: pw.Alignment.center,
      );
      content.add(table);
    }

    await printOrExportPdf(
      title: title,
      dateInfo: dateInfo,
      content: content,
      isDirectPrint: format == ExportFormat.print,
    );
  }

  Future<void> exportWorkerAccountReport({
    required String dateInfo,
    required double openingBalance,
    required double totalDeposits,
    required double totalWithdrawals,
    required double currentBalance,
    required ExportFormat format,
  }) async {
    final title = 'تقرير حسابي (الدفتر اليدوي)';
    if (format == ExportFormat.txt) {
      String txt = "--- $title ---\nتاريخ: $dateInfo\n\n"
          "الرصيد الافتتاحي: $openingBalance\n"
          "إجمالي الإيداعات: $totalDeposits\n"
          "إجمالي السحوبات: $totalWithdrawals\n"
          "الرصيد الحالي: $currentBalance\n";
      await exportTxt(title: title, content: txt);
      return;
    }
    if (format == ExportFormat.csv) {
      String _escape(String s) => '"' + s.replaceAll('"', '""') + '"';
      String csv = "${_escape('الرصيد الافتتاحي')},${_escape('إجمالي الإيداعات')},${_escape('إجمالي السحوبات')},${_escape('الرصيد الحالي')}\n";
      csv += "${_escape(openingBalance.toString())},${_escape(totalDeposits.toString())},${_escape(totalWithdrawals.toString())},${_escape(currentBalance.toString())}\n";
      await exportCsv(title: title, csvContent: csv);
      return;
    }
    final font = await _getArabicFont();
    final boldFont = await _getArabicBoldFont();
    final content = [
      pw.Text('الرصيد الافتتاحي: $openingBalance', style: pw.TextStyle(font: font, fontSize: 14), textDirection: pw.TextDirection.rtl),
      pw.Text('إجمالي الإيداعات اليدوية: $totalDeposits', style: pw.TextStyle(font: font, fontSize: 14), textDirection: pw.TextDirection.rtl),
      pw.Text('إجمالي السحوبات اليدوية: $totalWithdrawals', style: pw.TextStyle(font: font, fontSize: 14), textDirection: pw.TextDirection.rtl),
      pw.Divider(),
      pw.Text('الرصيد الحالي: $currentBalance', style: pw.TextStyle(font: boldFont, fontSize: 16), textDirection: pw.TextDirection.rtl),
    ];
    await printOrExportPdf(title: title, dateInfo: dateInfo, content: content, isDirectPrint: format == ExportFormat.print);
  }

  Future<void> exportStatisticsReport({
    required String periodTitle,
    required double totalIncome,
    required int haircutsCount,
    required double totalExpenses,
    required double netIncome,
    required double ownerShare,
    required double workerShare,
    required double ownerExpenses,
    required double finalOwnerDue,
    required ExportFormat format,
  }) async {
    final title = 'تقرير إحصائيات العمل ($periodTitle)';
    if (format == ExportFormat.txt) {
      String txt = "--- $title ---\nالفترة: $periodTitle\n\n"
          "إجمالي الدخل: $totalIncome\n"
          "عدد الحلاقات: $haircutsCount\n"
          "الصرفة (المصروفات): $totalExpenses\n"
          "صافي الدخل: $netIncome\n"
          "حصة صاحب المحل: $ownerShare\n"
          "حصة العامل: $workerShare\n"
          "مخروجات صاحب المحل: $ownerExpenses\n"
          "المبلغ المستحق لصاحب المحل: $finalOwnerDue\n";
      await exportTxt(title: 'تقرير الإحصائيات', content: txt);
      return;
    }
    if (format == ExportFormat.csv) {
      String _escape(String s) => '"' + s.replaceAll('"', '""') + '"';
      String csv = "${_escape('الفترة')},${_escape('إجمالي الدخل')},${_escape('عدد الحلاقات')},${_escape('الصرفة')},${_escape('صافي الدخل')},${_escape('حصة صاحب المحل')},${_escape('حصة العامل')},${_escape('مخروجات صاحب المحل')},${_escape('مستحق صاحب المحل')}\n";
      csv += "${_escape(periodTitle)},${_escape(totalIncome.toString())},${_escape(haircutsCount.toString())},${_escape(totalExpenses.toString())},${_escape(netIncome.toString())},${_escape(ownerShare.toString())},${_escape(workerShare.toString())},${_escape(ownerExpenses.toString())},${_escape(finalOwnerDue.toString())}\n";
      await exportCsv(title: 'تقرير الإحصائيات', csvContent: csv);
      return;
    }
    final font = await _getArabicFont();
    final boldFont = await _getArabicBoldFont();
    final content = [
      pw.Text('الفترة المحددة: $periodTitle', style: pw.TextStyle(font: boldFont, fontSize: 14), textDirection: pw.TextDirection.rtl),
      pw.SizedBox(height: 8),
      pw.Text('إجمالي الدخل: $totalIncome', style: pw.TextStyle(font: font, fontSize: 13), textDirection: pw.TextDirection.rtl),
      pw.Text('عدد الحلاقات: $haircutsCount', style: pw.TextStyle(font: font, fontSize: 13), textDirection: pw.TextDirection.rtl),
      pw.Text('الصرفة (المصروفات): $totalExpenses', style: pw.TextStyle(font: font, fontSize: 13), textDirection: pw.TextDirection.rtl),
      pw.Divider(),
      pw.Text('صافي الدخل: $netIncome', style: pw.TextStyle(font: boldFont, fontSize: 15), textDirection: pw.TextDirection.rtl),
      pw.SizedBox(height: 6),
      pw.Text('حصة صاحب المحل: $ownerShare', style: pw.TextStyle(font: font, fontSize: 13), textDirection: pw.TextDirection.rtl),
      pw.Text('حصة العامل: $workerShare', style: pw.TextStyle(font: font, fontSize: 13), textDirection: pw.TextDirection.rtl),
      pw.Text('مخروجات صاحب المحل: $ownerExpenses', style: pw.TextStyle(font: font, fontSize: 13), textDirection: pw.TextDirection.rtl),
      pw.Text('المبلغ المستحق لصاحب المحل: $finalOwnerDue', style: pw.TextStyle(font: boldFont, fontSize: 14), textDirection: pw.TextDirection.rtl),
    ];
    await printOrExportPdf(title: 'تقرير الإحصائيات', dateInfo: periodTitle, content: content, isDirectPrint: format == ExportFormat.print);
  }
}
