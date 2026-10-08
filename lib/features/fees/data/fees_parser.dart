import 'package:html/parser.dart' as html;
import 'package:intl/intl.dart';
import '../models/fee_record.dart';

abstract final class FeesParser {
  static List<FeeRecord> parse(String markup) {
    final document = html.parse(markup);
    final table = document.querySelector('table[id\$="_grd_inst_fee"]');
    if (table == null) {
      final message = document.querySelector('[data-fees-empty]');
      if (message != null) return const [];
      throw const FormatException('ERP didn’t return your fee records.');
    }
    final records = <FeeRecord>[];
    for (final row in table.querySelectorAll('tr')) {
      // Ignore the nested fee-head tables and the grid's heading row.
      if (row.parent != table && row.parent?.parent != table) continue;
      if (row.querySelector('[id\$="_lbl_fee_type"]') == null) continue;
      String field(String suffix) =>
          (row.querySelector('[id\$="_$suffix"]')?.text ?? '').trim();
      final amount = field('lbl_fee_type');
      final digits = amount.replaceAll(',', '');
      if (!RegExp(r'^\d+(?:\.\d{1,2})?$').hasMatch(digits)) {
        throw const FormatException('ERP returned an invalid fee amount.');
      }
      final parts = digits.split('.');
      final paise =
          int.parse(parts.first) * 100 +
          int.parse(parts.length == 1 ? '0' : parts.last.padRight(2, '0'));
      final date = field('lbl_pay_date');
      final receipt = field('lbl_receipt_no');
      if (receipt.isEmpty) {
        throw const FormatException('ERP returned an incomplete fee record.');
      }
      final items = <FeeItem>[];
      final amountId = row.querySelector('[id\$="_lbl_fee_type"]')!.id;
      // ERP places the breakdown in a separate hidden row of the same grid.
      final child = document.getElementById(
        amountId.replaceFirst(RegExp(r'_lbl_fee_type$'), '_grd_child'),
      );
      if (child != null) {
        for (final item in child.querySelectorAll('tr')) {
          final cells = item.children
              .where((cell) => cell.localName == 'td')
              .toList();
          if (cells.length >= 3) {
            items.add(
              FeeItem(
                head: cells[0].text.trim(),
                type: cells[1].text.trim(),
                amount: cells[2].text.trim(),
              ),
            );
          }
        }
      }
      records.add(
        FeeRecord(
          amountPaise: paise,
          amountLabel: amount,
          paymentType: field('lbl_pay_type'),
          accountHead: field('lbl_account_head'),
          dateLabel: date,
          paidAt: DateFormat('dd/MM/yyyy').parseStrict(date),
          receiptNumber: receipt,
          orderId: field('lbl_bank_acc'),
          trackingId: field('lbl_bank_tran'),
          status: field('lbl_status'),
          canDownload: row.querySelector('a[id\$="_lnk_print"]') != null,
          items: List.unmodifiable(items),
        ),
      );
    }
    if (records.isEmpty && !table.text.toLowerCase().contains('no record')) {
      throw const FormatException('ERP returned an incomplete fee list.');
    }
    records.sort((a, b) => b.paidAt.compareTo(a.paidAt));
    return List.unmodifiable(records);
  }
}
