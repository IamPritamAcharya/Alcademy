import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;
import '../models/timetable.dart';

class TimetableParser {
  static const dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  static String _clean(String text) =>
      text.replaceAll(RegExp(r'\s+'), ' ').trim();
  // Element.text concatenates across <br>, turning SE<br>BA-202 into SEBA-202.
  static String _lines(Node node) {
    if (node is Text) return node.data;
    if (node is Element && node.localName == 'br') return '\n';
    return node.nodes.map(_lines).join();
  }

  static String _label(Element node) => _lines(
    node,
  ).split('\n').map(_clean).where((line) => line.isNotEmpty).join('\n');
  static List<Element> _cells(Element row) => row.children
      .where((cell) => cell.localName == 'td' || cell.localName == 'th')
      .toList();
  static Element? _tableAncestor(Element? node) {
    while (node != null) {
      if (node.localName == 'table') return node;
      node = node.parent;
    }
    return null;
  }

  // Nested legend tables must not accidentally become rows in the timetable.
  static List<Element> _rows(Element table) => table
      .querySelectorAll('tr')
      .where((row) => _tableAncestor(row.parent) == table)
      .toList();

  Timetable parse(String source, {DateTime? fetchedAt}) {
    final document = html.parse(source);
    final table = document.querySelector('[id\$="_tbl_time_table"]');
    if (table == null) {
      throw const FormatException(
        'ERP has not published a timetable for this account.',
      );
    }
    final rows = _rows(table);
    final headerIndex = rows.indexWhere(
      (row) => _cells(
        row,
      ).any((cell) => _clean(cell.text).toUpperCase() == 'MONDAY'),
    );
    if (headerIndex < 0) {
      throw const FormatException('The ERP timetable layout has changed.');
    }
    final headers = _cells(
      rows[headerIndex],
    ).skip(1).map((cell) => _clean(cell.text).toLowerCase()).toList();
    final days = headers
        .map(
          (header) =>
              dayNames.indexWhere((day) => day.toLowerCase() == header) + 1,
        )
        .toList();
    if (days.isEmpty || days.any((day) => day == 0)) {
      throw const FormatException(
        'The ERP timetable has unrecognised day columns.',
      );
    }
    final subjects = <String, String>{};
    final faculty = <String, String>{};
    for (final legend in document.querySelectorAll('table')) {
      final legendRows = _rows(legend);
      if (legendRows.isEmpty) continue;
      // Match direct header cells, not a container that holds both legends.
      final headings = _cells(
        legendRows.first,
      ).map((cell) => _clean(cell.text));
      final Map<String, String> entries;
      if (headings.contains('Subject Full Name')) {
        entries = subjects;
      } else if (headings.contains('Faculty Full Name')) {
        entries = faculty;
      } else {
        continue;
      }
      for (final row in legendRows.skip(1)) {
        final cells = _cells(row);
        if (cells.length == 3 && _clean(cells[1].text) == '►') {
          final code = _clean(cells[0].text);
          final name = _clean(cells[2].text);
          if (code.isNotEmpty && name.isNotEmpty) entries[code] = name;
        }
      }
    }
    final dataRows = rows.skip(headerIndex + 1).toList();
    final times = dataRows
        .map((row) => _range(_cells(row).firstOrNull?.text ?? ''))
        .toList();
    final occupiedUntil = <int, int>{};
    final lessons = <TimetableLesson>[];
    final breaks = <TimetableBreak>[];
    for (var rowIndex = 0; rowIndex < dataRows.length; rowIndex++) {
      final cells = _cells(dataRows[rowIndex]);
      final time = times[rowIndex];
      if (time == null) {
        final label = _clean(dataRows[rowIndex].text);
        if (label.toUpperCase().contains('RECESS') &&
            rowIndex > 0 &&
            rowIndex + 1 < times.length) {
          final before = times[rowIndex - 1];
          final after = times[rowIndex + 1];
          if (before != null && after != null && after.$1 > before.$2) {
            breaks.add(
              TimetableBreak(
                startMinute: before.$2,
                endMinute: after.$1,
                label: label,
              ),
            );
          }
        }
        continue;
      }
      var column = 0;
      for (final cell in cells.skip(1)) {
        while ((occupiedUntil[column] ?? -1) >= rowIndex) {
          column++;
        }
        final rowSpan = int.tryParse(cell.attributes['rowspan'] ?? '1') ?? 1;
        final colSpan = int.tryParse(cell.attributes['colspan'] ?? '1') ?? 1;
        if (rowSpan < 1 ||
            colSpan < 1 ||
            column + colSpan > days.length ||
            rowIndex + rowSpan > dataRows.length) {
          throw const FormatException(
            'The ERP timetable contains an invalid merged cell.',
          );
        }
        final end = times[rowIndex + rowSpan - 1]?.$2;
        if (end == null) {
          throw const FormatException(
            'A timetable session has an invalid end time.',
          );
        }
        final labels = cell
            .querySelectorAll('.timetable_label')
            .map(_label)
            .where((label) => label.isNotEmpty)
            .toList();
        if (labels.isEmpty && _label(cell).isNotEmpty) {
          labels.add(_label(cell));
        }
        for (var offset = 0; offset < colSpan; offset++) {
          occupiedUntil[column + offset] = rowIndex + rowSpan - 1;
          if (labels.isNotEmpty) {
            lessons.add(
              TimetableLesson(
                weekday: days[column + offset],
                startMinute: time.$1,
                endMinute: end,
                classes: List.unmodifiable(
                  labels.map((label) => _class(label, subjects)),
                ),
              ),
            );
          }
        }
        column += colSpan;
      }
    }
    // ERP emits a table directly inside another table (outside a td). Browsers
    // repair this into sibling tables, so metadata need not be an ancestor.
    final metadataTable = document.querySelectorAll('table').where((candidate) {
      return candidate != table &&
          _rows(candidate)
              .take(3)
              .expand(_cells)
              .any(
                (cell) =>
                    _clean(cell.text).toUpperCase() == 'DIVISION TIME TABLE',
              );
    }).firstOrNull;
    final metadata = metadataTable == null
        ? <String>[]
        : _rows(
            metadataTable,
          ).take(3).expand(_cells).map((cell) => _clean(cell.text)).toList();
    String field(String prefix) =>
        metadata
            .where((text) => text.startsWith(prefix))
            .map((text) => text.substring(prefix.length).trim())
            .firstOrNull ??
        '';
    final division =
        metadata
            .where(
              (text) =>
                  text.toUpperCase().contains('DIVISION') &&
                  !text.toUpperCase().contains('TIME TABLE'),
            )
            .firstOrNull ??
        '';
    return Timetable(
      division: division,
      department: field('Dept.:'),
      academicYear: field('A.Y.:'),
      effectiveFrom: field('W.E.F.:'),
      weekdays: List.unmodifiable(days),
      lessons: List.unmodifiable(lessons),
      breaks: List.unmodifiable(breaks),
      subjects: Map.unmodifiable(subjects),
      faculty: Map.unmodifiable(faculty),
      fetchedAt: fetchedAt ?? DateTime.now(),
    );
  }

  TimetableClass _class(String label, Map<String, String> subjects) {
    final text = _clean(label);
    final codes = subjects.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final code in codes) {
      final match = RegExp(
        '(?:^|\\s)${RegExp.escape(code)}(?=\\s|\$)',
      ).firstMatch(text);
      if (match == null) continue;
      final prefix = text
          .substring(0, match.start)
          .replaceAll(RegExp(r'[\s-]+$'), '')
          .trim();
      final location = text.substring(match.end).trim();
      return TimetableClass(
        label: label,
        code: code,
        subject: subjects[code],
        location: location.isEmpty ? null : location,
        batch: prefix.isEmpty ? null : prefix,
      );
    }
    return TimetableClass(label: label);
  }

  (int, int)? _range(String text) {
    final match = RegExp(
      r'(\d{1,2}):(\d{2})\s*(AM|PM)\s+to\s+(\d{1,2}):(\d{2})\s*(AM|PM)',
      caseSensitive: false,
    ).firstMatch(_clean(text));
    if (match == null) return null;
    int minute(int group) {
      final hour = int.parse(match.group(group)!);
      final minutes = int.parse(match.group(group + 1)!);
      if (hour < 1 || hour > 12 || minutes > 59) {
        throw const FormatException('An ERP timetable time is invalid.');
      }
      return (hour % 12 +
                  (match.group(group + 2)!.toUpperCase() == 'PM' ? 12 : 0)) *
              60 +
          minutes;
    }

    final start = minute(1), end = minute(4);
    if (end <= start) {
      throw const FormatException('An ERP timetable time range is invalid.');
    }
    return (start, end);
  }
}
