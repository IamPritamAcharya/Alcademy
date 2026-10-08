import 'package:flutter/material.dart';
import '../../college_resources/presentation/erp_data_session.dart';
import '../data/erp_timetable_flow.dart';
import '../data/erp_timetable_markup.dart';
import '../data/timetable_parser.dart';
import '../models/timetable.dart';

class TimetableSession extends StatelessWidget {
  final ValueChanged<Timetable> onLoaded;
  final ValueChanged<TimetableLoadException> onError;
  final ValueChanged<String> onStatus;
  const TimetableSession({
    super.key,
    required this.onLoaded,
    required this.onError,
    required this.onStatus,
  });
  @override
  Widget build(BuildContext context) => ErpDataSession<Timetable>(
    target: ErpTimetableFlow.timetableUri,
    resource: 'timetable',
    extractionScript: ErpTimetableMarkup.extractionScript,
    decode: ErpTimetableMarkup.decode,
    parse: TimetableParser().parse,
    onLoaded: onLoaded,
    onError: onError,
    onStatus: onStatus,
  );
}
