import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'order_storage.dart';
import 'dart:typed_data';
import 'package:new_amst_flutter/Model/products_data.dart';

class DailyReportPdfService {
  static const PdfColor _blue = PdfColor.fromInt(0xFF00C6FF);
  static const PdfColor _purple = PdfColor.fromInt(0xFF7F53FD);

  static const PdfColor _bg = PdfColor.fromInt(0xFFF6F7FA);
  static const PdfColor _card = PdfColor.fromInt(0xFFFFFFFF);

  static const PdfColor _textDark = PdfColor.fromInt(0xFF1F2937);
  static const PdfColor _textDim = PdfColor.fromInt(0xFF6A6F7B);

  static const PdfColor _border = PdfColor.fromInt(0xFFE5E7EB);
  static const PdfColor _thead = PdfColor.fromInt(0xFFEFF2F8);

  Future<Uint8List> generateDailyReportPdf(
    DateTime day, {
    Uint8List? logoBytes,
  }) async {
    final sheet = OrdersStorage().dailySheetFor(day);
    final pdf = pw.Document();

    if (sheet == null || sheet.rows.isEmpty) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (_) => pw.Center(
            child: pw.Text('No sales recorded for this day.'),
          ),
        ),
      );
      return Uint8List.fromList(await pdf.save());
    }

    final pw.ImageProvider? logo =
        (logoBytes != null && logoBytes.isNotEmpty) ? pw.MemoryImage(logoBytes) : null;

    final prettyDate = _prettyDay(sheet.day);

    // ---- per_kg_ltr lookup ----
    final perKgById = <String, double>{};
    final perKgByNameBrand = <String, double>{};

    for (final p in kTeaProducts) {
      final id = (p['id'] ?? '').toString().trim();
      final name = (p['name'] ?? p['item_name'] ?? '').toString().trim();
      final brand = (p['brand'] ?? '').toString().trim();
      final per = _toDouble(p['per_kg_ltr']);
      if (per <= 0) continue;
      if (id.isNotEmpty) perKgById[id] = per;
      perKgByNameBrand['$name|$brand'] = per;
    }

    // Map row => itemId (from saved order lines)
    final rowItemIdMap = <String, String>{};
    for (final o in sheet.orders) {
      for (final line in o.lines) {
        final name = (line['name'] ?? '').toString().trim();
        final brand = (line['brand'] ?? '').toString().trim();
        final itemId =
            (line['itemId'] ?? line['skuId'] ?? line['id'] ?? '').toString().trim();
        final key = '$name|$brand';
        if (!rowItemIdMap.containsKey(key) && itemId.isNotEmpty) {
          rowItemIdMap[key] = itemId;
        }
      }
    }

    double resolvePerKg({String? itemId, required String name, required String brand}) {
      final id = (itemId ?? '').trim();
      if (id.isNotEmpty && perKgById.containsKey(id)) return perKgById[id]!;
      return perKgByNameBrand['${name.trim()}|${brand.trim()}'] ?? 0.0;
    }

    // ---- table ----
    final tableRows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _thead),
        children: [
          _cell('#', bold: true),
          _cell('Product', bold: true),
          _cell('Brand', bold: true),
          _cellRight('Qty', bold: true),
          _cellRight('Weight (KG)', bold: true),
        ],
      ),
    ];

    int idx = 1;
    for (final r in sheet.rows) {
      final name = r.name.trim();
      final brand = r.brand.trim();
      final qty = r.qty;

      final key = '$name|$brand';
      final itemId = rowItemIdMap[key];

      final perKg = resolvePerKg(itemId: itemId, name: name, brand: brand);
      final rowWeight = perKg * qty;

      tableRows.add(
        pw.TableRow(
          children: [
            _cell('$idx'),
            _cell(r.name),
            _cell(r.brand),
            _cellRight('$qty'),
            _cellRight(rowWeight == 0 ? '-' : rowWeight.toStringAsFixed(2)),
          ],
        ),
      );

      idx++;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(22, 22, 22, 22),
        build: (ctx) => [
          pw.Container(
            decoration: pw.BoxDecoration(
              color: _card,
              borderRadius: pw.BorderRadius.circular(14),
              border: pw.Border.all(color: _border, width: 0.8),
            ),
            child: pw.Column(
              children: [
                // Header gradient
                pw.Container(
                  padding: const pw.EdgeInsets.fromLTRB(16, 14, 16, 14),
                  decoration: pw.BoxDecoration(
                    gradient: const pw.LinearGradient(
                      colors: [_blue, _purple],
                      begin: pw.Alignment.centerLeft,
                      end: pw.Alignment.centerRight,
                    ),
                    borderRadius: const pw.BorderRadius.only(
                      topLeft: pw.Radius.circular(14),
                      topRight: pw.Radius.circular(14),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      // ✅ ONLY LOGO (NO SKUs/Qty/Orders text)
                      if (logo != null)
                        pw.Center(
                          child: pw.Container(
                            width: 170,
                            height: 60,
                            padding: const pw.EdgeInsets.all(8),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.white,
                              borderRadius: pw.BorderRadius.circular(10),
                              border: pw.Border.all(color: PdfColors.white, width: 0.8),
                            ),
                            child: pw.Center(
                              child: pw.Image(logo, fit: pw.BoxFit.contain),
                            ),
                          ),
                        ),

                      // If you want EVEN title/date removed, delete below two blocks too.
                      pw.SizedBox(height: 10),
                      pw.Center(
                        child: pw.Text(
                          'Daily Sales Report',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      // pw.SizedBox(height: 4),
                      // pw.Center(
                      //   child: pw.Text(
                      //     prettyDate,
                      //     style: const pw.TextStyle(color: PdfColors.white, fontSize: 11),
                      //   ),
                      //),
                    ],
                  ),
                ),

                // Body
                pw.Container(
                  color: _bg,
                  padding: const pw.EdgeInsets.all(14),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      pw.Row(
                        children: [
                          pw.Container(
                            width: 4,
                            height: 18,
                            decoration: pw.BoxDecoration(
                              gradient: const pw.LinearGradient(
                                colors: [_blue, _purple],
                                begin: pw.Alignment.topCenter,
                                end: pw.Alignment.bottomCenter,
                              ),
                              borderRadius: pw.BorderRadius.circular(99),
                            ),
                          ),
                          pw.SizedBox(width: 8),
                          pw.Text(
                            'Sales Report $prettyDate',
                            style: pw.TextStyle(
                              color: _textDark,
                              fontSize: 12.5,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 10),

                      pw.Container(
                        decoration: pw.BoxDecoration(
                          color: _card,
                          borderRadius: pw.BorderRadius.circular(12),
                          border: pw.Border.all(color: _border, width: 0.8),
                        ),
                        child: pw.Table(
                          border: pw.TableBorder.all(color: _border, width: 0.6),
                          defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
                          columnWidths: const {
                            0: pw.FixedColumnWidth(26),
                            1: pw.FlexColumnWidth(3.6),
                            2: pw.FlexColumnWidth(2.0),
                            3: pw.FixedColumnWidth(42),
                            4: pw.FixedColumnWidth(64),
                          },
                          children: tableRows,
                        ),
                      ),

                      pw.SizedBox(height: 10),
                      pw.Divider(color: _border),
                      pw.SizedBox(height: 6),
                      pw.Center(
                        child: pw.Text(
                          'Auto Generated Report',
                          style: pw.TextStyle(color: _textDim, fontSize: 9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Uint8List.fromList(await pdf.save());
  }

  String _prettyDay(DateTime d) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    return '${d.day} ${months[d.month - 1]}, ${d.year}';
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.trim()) ?? 0.0;
    return 0.0;
  }
}

// ---------- PDF cell helpers ----------
pw.Widget _cell(String text, {bool bold = false}) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9.5,
          color: DailyReportPdfService._textDark,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );

pw.Widget _cellRight(String text, {bool bold = false}) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 9.5,
            color: DailyReportPdfService._textDark,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ),
    );
