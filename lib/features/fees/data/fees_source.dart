import 'dart:convert';
import 'dart:typed_data';
import '../models/fee_record.dart';

abstract final class FeesSource {
  static final uri = Uri.parse(
    'https://igit.icrp.in/academic/Student-cp/Form_students_pay_fees.aspx',
  );
  static const _guard = '''
    if (location.origin !== 'https://igit.icrp.in' ||
        location.pathname.toLowerCase() !== '/academic/student-cp/form_students_pay_fees.aspx')
      return JSON.stringify({error: true});
  ''';
  static const script =
      '''
    (() => {
      $_guard
      const table = document.querySelector('table[id\$="_grd_inst_fee"]');
      if (table) return table.outerHTML;
      const content = document.querySelector('[id\$="_ContentPlaceHolder1"]');
      if (content && /no (fee |payment )?records? (found|available)/i.test(content.textContent))
        return '<div data-fees-empty></div>';
      return JSON.stringify({error: true});
    })();
  ''';
  static String? decodeMarkup(Object value) {
    if (value is! String) {
      throw const FormatException('ERP returned unreadable fees.');
    }
    final markup = value.startsWith('"') ? jsonDecode(value) : value;
    if (markup is! String || !markup.trimLeft().startsWith('<')) {
      throw const FormatException('ERP didn’t return your fee records.');
    }
    return markup;
  }

  static String receiptScript(FeeRecord record) {
    final identity = jsonEncode({
      'receipt': record.receiptNumber,
      'amount': record.amountLabel,
      'date': record.dateLabel,
    });
    return '''
      (() => {
        $_guard
        if (!window.__alcademyReceipt) {
          window.__alcademyReceipt = {pending: true};
          const wanted = $identity;
          (async () => {
            const table = document.querySelector('table[id\$="_grd_inst_fee"]');
            if (!table) throw new Error('Fee list unavailable');
            const rows = Array.from(table.rows);
            const field = (row, name) => (row.querySelector('[id\$="_' + name + '"]')?.textContent || '').trim();
            const row = rows.find(row => field(row, 'lbl_receipt_no') === wanted.receipt &&
              field(row, 'lbl_fee_type') === wanted.amount && field(row, 'lbl_pay_date') === wanted.date);
            const link = row?.querySelector('a[id\$="_lnk_print"]');
            const event = link?.getAttribute('href')?.match(/__doPostBack\\('([^']+\\\$lnk_print)'\\s*,\\s*''\\)/);
            if (!event || !/^ctl00\\\$ContentPlaceHolder1\\\$grd_inst_fee\\\$ctl[0-9]+\\\$lnk_print\$/.test(event[1]))
              throw new Error('Receipt unavailable');
            const form = document.getElementById('aspnetForm');
            if (!form) throw new Error('Receipt form unavailable');
            const fields = new URLSearchParams();
            // Hidden ASP.NET state only; payment inputs and buttons are excluded.
            form.querySelectorAll('input[type="hidden"][name]').forEach(input => fields.set(input.name, input.value));
            fields.set('__EVENTTARGET', event[1]);
            fields.set('__EVENTARGUMENT', '');
            const abort = new AbortController();
            const timer = setTimeout(() => abort.abort(), 30000);
            try {
              const response = await fetch(location.pathname, {
                method: 'POST', credentials: 'same-origin', signal: abort.signal,
                headers: {'Content-Type': 'application/x-www-form-urlencoded'}, body: fields.toString()
              });
              if (!response.ok || new URL(response.url).origin !== location.origin)
                throw new Error('Receipt request failed');
              const bytes = new Uint8Array(await response.arrayBuffer());
              if (bytes.length > 20 * 1024 * 1024 ||
                  String.fromCharCode(...bytes.subarray(0, 5)) !== '%PDF-')
                throw new Error('ERP did not return a PDF');
              let binary = '';
              for (let offset = 0; offset < bytes.length; offset += 8192)
                binary += String.fromCharCode(...bytes.subarray(offset, offset + 8192));
              window.__alcademyReceipt = {pdf: btoa(binary)};
            } finally { clearTimeout(timer); }
          })().catch(() => { window.__alcademyReceipt = {error: true}; });
        }
        return JSON.stringify(window.__alcademyReceipt);
      })();
    ''';
  }

  static String? decodeReceipt(Object value) {
    if (value is! String) {
      throw const FormatException('ERP returned unreadable receipt data.');
    }
    dynamic result = jsonDecode(value);
    if (result is String) result = jsonDecode(result);
    if (result is! Map || result['error'] == true) {
      throw const FormatException(
        'Couldn’t download this receipt. Refresh fees and try again.',
      );
    }
    if (result['pending'] == true) return null;
    if (result['pdf'] is! String) {
      throw const FormatException('ERP returned an incomplete receipt.');
    }
    return result['pdf'] as String;
  }

  static Uint8List parseReceipt(String encoded) {
    final bytes = base64Decode(encoded);
    if (bytes.length < 5 ||
        bytes.length > 20 * 1024 * 1024 ||
        ascii.decode(bytes.sublist(0, 5), allowInvalid: true) != '%PDF-') {
      throw const FormatException('ERP didn’t return a valid PDF receipt.');
    }
    return bytes;
  }

  static String fileName(FeeRecord record) =>
      'Alcademy-receipt-${record.receiptNumber.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}.pdf';
}
