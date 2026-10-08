import '../../college_resources/data/erp_data_flow.dart';
import '../models/timetable.dart';
import 'timetable_parser.dart';

typedef TimetableFailure = ErpDataFailure;
typedef TimetableLoadException = ErpDataException;

class ErpTimetableFlow extends ErpDataFlow<Timetable> {
  static final timetableUri = Uri.parse(
    'https://igit.icrp.in/academic/Student-cp/Form_Display_Division_TimeTableS.aspx',
  );
  static bool trusted(String url) => ErpDataFlow.trusted(url);
  ErpTimetableFlow({
    required super.readCredentials,
    required super.navigate,
    required super.signIn,
    required Future<String> Function() readTimetable,
    required super.onLoaded,
    required super.onError,
    required super.onStatus,
  }) : super(
         target: timetableUri,
         resource: 'timetable',
         parse: TimetableParser().parse,
         readMarkup: readTimetable,
       );
}
