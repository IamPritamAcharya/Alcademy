import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:port/shared/theme/app_style.dart';
import '../../college_resources/data/erp_data_flow.dart';
import '../../college_resources/presentation/erp_data_session.dart';
import '../../college_resources/presentation/erp_page.dart';
import '../../profile/presentation/profile_page.dart';
import '../../home/presentation/widgets/journal_cover.dart';
import '../data/results_cache.dart';
import '../data/results_parser.dart';
import '../data/results_source.dart';
import '../models/student_results.dart';

typedef ResultsSessionBuilder =
    Widget Function({
      required ValueChanged<StudentResults> onLoaded,
      required ValueChanged<ErpDataException> onError,
      required ValueChanged<String> onStatus,
    });

class ResultsPage extends StatefulWidget {
  final ResultsSessionBuilder? sessionBuilder;
  final DateTime Function()? clock;
  const ResultsPage({super.key, this.sessionBuilder, this.clock});
  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  final _cache = const ResultsCache();
  StudentResults? _data;
  ErpDataException? _error;
  String _status = 'Checking your saved results…';
  bool _fetching = false;
  int _selectedIndex = 0;
  int _attempt = 0;
  Completer<void>? _refresh;
  Timer? _expiryTimer;
  DateTime get _now => widget.clock?.call() ?? DateTime.now();
  bool get _supported =>
      widget.sessionBuilder != null ||
      (!kIsWeb &&
          {
            TargetPlatform.android,
            TargetPlatform.iOS,
            TargetPlatform.macOS,
          }.contains(defaultTargetPlatform));
  @override
  void initState() {
    super.initState();
    unawaited(_restore());
  }

  void _scheduleExpiry() {
    _expiryTimer?.cancel();
    if (_data == null || !_data!.complete) return;
    final delay = ResultsCache.expiresAt(_data!.fetchedAt).difference(_now);
    if (delay <= Duration.zero) return;
    _expiryTimer = Timer(delay, () {
      if (mounted) unawaited(_reload());
    });
  }

  Future<void> _restore() async {
    final data = await _cache.read(_now);
    if (!mounted) return;
    setState(() {
      _data = data;
      _error = null;
    });
    _scheduleExpiry();
    if (data == null && _supported) unawaited(_reload());
  }

  void _finish() {
    if (_refresh?.isCompleted == false) _refresh!.complete();
  }

  Future<void> _reload() {
    if (_fetching) return _refresh!.future;
    _refresh = Completer<void>();
    setState(() {
      _attempt++;
      _fetching = true;
      _error = null;
      _status = 'Checking your ERP session…';
    });
    return _refresh!.future;
  }

  Future<void> _profile() async {
    _finish();
    setState(() {
      _attempt++;
      _fetching = false;
    });
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const UserProfilePage(focusErpCredentials: true),
      ),
    );
    if (mounted) await _restore();
  }

  Future<void> _erp() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AcademicWebViewPage()),
    );
    if (mounted) unawaited(_reload());
  }

  Widget _session() {
    final attempt = _attempt;
    Future<void> loaded(StudentResults data) async {
      if (!mounted || attempt != _attempt) return;
      try {
        await _cache.write(data);
      } catch (_) {
        /* Keep the live response usable. */
      }
      if (!mounted || attempt != _attempt) return;
      setState(() {
        _data = data;
        if (_selectedIndex >= data.exams.length) _selectedIndex = 0;
        _fetching = false;
        _error = null;
      });
      _scheduleExpiry();
      _finish();
    }

    void failed(ErpDataException error) {
      if (!mounted || attempt != _attempt) return;
      setState(() {
        _fetching = false;
        if (_data == null) _error = error;
      });
      _finish();
      if (_data != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Couldn’t refresh. Showing saved results. ${error.message}',
            ),
          ),
        );
      }
    }

    void status(String value) {
      if (mounted && attempt == _attempt) setState(() => _status = value);
    }

    return KeyedSubtree(
      key: ValueKey(attempt),
      child:
          widget.sessionBuilder?.call(
            onLoaded: loaded,
            onError: failed,
            onStatus: status,
          ) ??
          ErpDataSession<StudentResults>(
            target: ResultsSource.uri,
            resource: 'results',
            extractionScript: ResultsSource.script,
            timeout: const Duration(minutes: 3),
            decode: ResultsSource.decode,
            parse: ResultsParser().parse,
            onLoaded: loaded,
            onError: failed,
            onStatus: status,
          ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Results'),
      actions: [
        IconButton(
          tooltip: 'ERP credentials',
          onPressed: _profile,
          icon: const Icon(Icons.person_outline_rounded),
        ),
        const SizedBox(width: 8),
      ],
    ),
    body: SafeArea(
      top: false,
      child: Stack(
        children: [
          if (!_supported)
            _message(
              'Your results, on mobile.',
              'Open the Android or iOS app to connect to ERP.',
            )
          else if (_error != null)
            _message(
              _error!.reason == ErpDataFailure.credentialsRequired
                  ? 'Connect your ERP.'
                  : 'A small pause.',
              _error!.message,
              actions: true,
            )
          else if (_data == null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppStyle.lilac,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _status,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppStyle.muted,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            RefreshIndicator(
              onRefresh: _reload,
              color: AppStyle.lilac,
              child: _overview(_data!),
            ),
          if (_supported && _fetching)
            Positioned(
              left: 0,
              bottom: 0,
              width: 1,
              height: 1,
              child: _session(),
            ),
        ],
      ),
    ),
  );
  Widget _message(String title, String message, {bool actions = false}) =>
      Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.fact_check_outlined,
                size: 38,
                color: AppStyle.lilac,
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppStyle.muted, height: 1.6),
              ),
              if (actions) ...[
                const SizedBox(height: 22),
                FilledButton(
                  onPressed:
                      _error!.reason == ErpDataFailure.credentialsRequired ||
                          _error!.reason == ErpDataFailure.authentication
                      ? _profile
                      : _reload,
                  child: Text(
                    _error!.reason == ErpDataFailure.credentialsRequired ||
                            _error!.reason == ErpDataFailure.authentication
                        ? 'Edit ERP credentials'
                        : 'Try again',
                  ),
                ),
                TextButton.icon(
                  onPressed: _erp,
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('Open ERP'),
                ),
              ],
            ],
          ),
        ),
      );
  Widget _overview(StudentResults data) {
    final exam = data.exams.isEmpty ? null : data.exams[_selectedIndex];
    final report = exam?.report;
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          sliver: SliverToBoxAdapter(
            child: JournalCover(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'SEMESTER RESULTS',
                            style: AppStyle.eyebrow,
                          ),
                        ),
                        if (report != null && report.status.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              report.status,
                              style: const TextStyle(
                                color: AppStyle.paper,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        IconButton(
                          tooltip: 'Open ERP',
                          onPressed: _erp,
                          icon: const Icon(Icons.north_east_rounded, size: 19),
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                    Text(
                      exam?.semester ?? 'No results yet.',
                      style: const TextStyle(
                        fontSize: 23,
                        height: 1.3,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -.6,
                      ),
                    ),
                    if (report != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _score('SGPA', report.sgpa)),
                          Expanded(child: _score('CGPA', report.cgpa)),
                          Expanded(child: _score('CREDITS', report.credits)),
                        ],
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      Text(
                        exam == null
                            ? 'ERP hasn’t published any exam results for this account.'
                            : exam.declared
                            ? 'The report couldn’t load. Pull down to try again.'
                            : 'This result has not been declared yet.',
                        style: const TextStyle(
                          color: AppStyle.paper,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        if (data.exams.isNotEmpty)
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
              child: Row(
                children: [
                  for (var i = 0; i < data.exams.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    _examTab(data.exams[i], i),
                  ],
                ],
              ),
            ),
          ),
        if (exam != null)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exam.exam,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppStyle.paper,
                      height: 1.5,
                    ),
                  ),
                  if (exam.examType.isNotEmpty ||
                      exam.publishedAt.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      [
                        if (exam.examType.isNotEmpty) exam.examType,
                        if (exam.publishedAt.isNotEmpty)
                          'Notification ${_date(exam.publishedAt)}',
                      ].join(' · '),
                      style: const TextStyle(
                        color: AppStyle.muted,
                        fontSize: 11,
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        if (report != null) ...[
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${report.subjects.length} SUBJECTS',
                        style: AppStyle.eyebrow,
                      ),
                    ),
                    SizedBox(
                      width: _creditWidth,
                      child: Text(
                        'CR.',
                        textAlign: TextAlign.center,
                        style: AppStyle.eyebrow.copyWith(letterSpacing: .8),
                      ),
                    ),
                    const SizedBox(width: 14),
                    SizedBox(
                      width: _gradeWidth,
                      child: Text(
                        'GRADE',
                        textAlign: TextAlign.center,
                        style: AppStyle.eyebrow.copyWith(
                          letterSpacing: .6,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList.builder(
              itemCount: report.subjects.length,
              itemBuilder: (_, i) => _subject(report.subjects[i]),
            ),
          ),
        ],
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          sliver: SliverToBoxAdapter(
            child: Text(
              data.complete
                  ? 'Saved ${data.fetchedAt.day}/${data.fetchedAt.month}/${data.fetchedAt.year} at ${_time(data.fetchedAt)}. Cached through this calendar month. Pull down to refresh.'
                  : 'Some declared reports couldn’t load. Incomplete results aren’t cached. Pull down to try again.',
              style: const TextStyle(
                color: AppStyle.muted,
                fontSize: 11,
                height: 1.6,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _score(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: AppStyle.eyebrow.copyWith(fontSize: 9, letterSpacing: 1),
      ),
      const SizedBox(height: 5),
      Text(
        value.isEmpty ? '—' : value,
        style: const TextStyle(
          fontSize: 26,
          height: 1.2,
          fontWeight: FontWeight.bold,
          letterSpacing: -.6,
        ),
      ),
    ],
  );

  Widget _examTab(ExamResult exam, int index) {
    final selected = index == _selectedIndex;
    return Semantics(
      selected: selected,
      button: true,
      label: '${exam.semester}, ${exam.exam}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedIndex = index),
          child: AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: selected ? AppStyle.paper : AppStyle.rule,
                  width: selected ? 2 : 1,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                Text(
                  exam.semesterNumber == 0
                      ? exam.semester
                      : 'Sem ${exam.semesterNumber}',
                  style: TextStyle(
                    color: selected ? AppStyle.text : AppStyle.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (dataHasMultipleAttempts(exam)) ...[
                  const SizedBox(height: 4),
                  Text(
                    exam.examType.isEmpty
                        ? 'Attempt ${index + 1}'
                        : exam.examType,
                    style: TextStyle(color: AppStyle.muted, fontSize: 10),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool dataHasMultipleAttempts(ExamResult exam) =>
      _data!.exams.where((row) => row.semester == exam.semester).length > 1;

  double get _creditWidth =>
      MediaQuery.textScalerOf(context).scale(36).clamp(36, 52).toDouble();
  double get _gradeWidth =>
      MediaQuery.textScalerOf(context).scale(42).clamp(42, 58).toDouble();

  static String _credit(String value) =>
      value.endsWith('.0') ? value.substring(0, value.length - 2) : value;

  Widget _subject(ResultSubject subject) => Container(
    padding: const EdgeInsets.symmetric(vertical: 18),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: AppStyle.rule)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subject.code,
                style: const TextStyle(
                  color: AppStyle.muted,
                  fontSize: 10,
                  letterSpacing: .5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subject.name,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: _creditWidth,
          child: Semantics(
            label: '${subject.credit} credits',
            child: Text(
              subject.credit.isEmpty ? '—' : _credit(subject.credit),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppStyle.paper, fontSize: 13),
            ),
          ),
        ),
        const SizedBox(width: 14),
        SizedBox(
          width: _gradeWidth,
          child: Semantics(
            label: 'Grade ${subject.grade}',
            child: Text(
              subject.grade.isEmpty ? '—' : subject.grade,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppStyle.lilac,
                fontSize: 24,
                height: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    ),
  );
  static String _date(String value) {
    final date = DateTime.tryParse(value);
    return date == null ? value : '${date.day}/${date.month}/${date.year}';
  }

  static String _time(DateTime value) =>
      '${value.hour % 12 == 0 ? 12 : value.hour % 12}:${value.minute.toString().padLeft(2, '0')} ${value.hour < 12 ? 'AM' : 'PM'}';
  @override
  void dispose() {
    _expiryTimer?.cancel();
    _finish();
    super.dispose();
  }
}
