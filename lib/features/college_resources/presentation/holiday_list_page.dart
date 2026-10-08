import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:port/shared/theme/app_style.dart';
import '../../profile/presentation/profile_page.dart';
import '../data/document_repository.dart';
import '../data/erp_data_flow.dart';
import '../data/holiday_source.dart';
import '../data/erp_monthly_cache.dart';
import '../data/erp_session_manager.dart';
import '../models/college_holiday.dart';
import 'erp_data_session.dart';
import 'erp_loading_panel.dart';
import 'erp_page.dart';
import 'remote_document_page.dart';

typedef HolidaySessionBuilder =
    Widget Function({
      required ValueChanged<List<CollegeHoliday>> onLoaded,
      required ValueChanged<ErpDataException> onError,
      required ValueChanged<String> onStatus,
    });

class HolidayListPage extends StatefulWidget {
  final HolidaySessionBuilder? sessionBuilder;
  final WidgetBuilder? pdfBuilder;
  final DateTime Function()? clock;
  const HolidayListPage({
    super.key,
    this.sessionBuilder,
    this.pdfBuilder,
    this.clock,
  });
  @override
  State<HolidayListPage> createState() => _HolidayListPageState();
}

class _HolidayListPageState extends State<HolidayListPage> {
  final _cache = ErpMonthlyCache<CollegeHoliday>(
    key: ErpSessionManager.holidaysCacheKey,
    fromJson: CollegeHoliday.fromJson,
    toJson: (holiday) => holiday.toJson(),
  );
  List<CollegeHoliday>? _holidays;
  DateTime? _fetchedAt;
  Timer? _expiryTimer;
  bool _restoring = true;
  DateTime get _now => widget.clock?.call() ?? DateTime.now();
  ErpDataException? _error;
  String _status = 'Checking your ERP session…';
  bool _fetching = false;
  int _attempt = 0;
  Completer<void>? _refresh;
  bool get _supported =>
      widget.sessionBuilder != null ||
      (!kIsWeb &&
          {
            TargetPlatform.android,
            TargetPlatform.iOS,
            TargetPlatform.macOS,
          }.contains(defaultTargetPlatform));
  DateTime get _today {
    final now = _now;
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();
    unawaited(_restore());
  }

  Future<void> _restore() async {
    final cached = await _cache.read(_now);
    if (!mounted) return;
    setState(() {
      _holidays = cached?.records;
      _fetchedAt = cached?.fetchedAt;
      _restoring = false;
      _error = null;
    });
    _scheduleExpiry();
    if (cached == null && _supported) unawaited(_reload());
  }

  void _scheduleExpiry() {
    _expiryTimer?.cancel();
    if (_fetchedAt == null) return;
    final delay = ErpMonthlyCache.expiresAt(_fetchedAt!).difference(_now);
    if (delay <= Duration.zero) return;
    _expiryTimer = Timer(delay, () {
      if (mounted) unawaited(_reload());
    });
  }

  void _finish() {
    if (_refresh?.isCompleted == false) _refresh!.complete();
  }

  Future<void> _reload() {
    if (!_supported) return Future.value();
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

  void _viewPdf() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder:
          widget.pdfBuilder ??
          (_) =>
              const RemoteDocumentPage(document: DocumentDefinition.holidays),
    ),
  );
  Future<void> _profile() async {
    _finish();
    setState(() {
      _attempt++;
      _fetching = false;
      _holidays = null;
      _restoring = true;
    });
    _expiryTimer?.cancel();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const UserProfilePage(focusErpCredentials: true),
      ),
    );
    if (mounted) unawaited(_restore());
  }

  Future<void> _openErp() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AcademicWebViewPage()),
    );
    if (mounted) unawaited(_reload());
  }

  Widget _session() {
    final attempt = _attempt;
    Future<void> loaded(List<CollegeHoliday> data) async {
      if (!mounted || attempt != _attempt) return;
      final fetched = _now;
      try {
        await _cache.write(data, fetched);
      } catch (_) {
        // Display the live list even if local storage is unavailable.
      }
      if (!mounted || attempt != _attempt) return;
      setState(() {
        _holidays = data;
        _fetching = false;
        _error = null;
        _fetchedAt = fetched;
      });
      _scheduleExpiry();
      _finish();
    }

    void failed(ErpDataException error) {
      if (!mounted || attempt != _attempt) return;
      setState(() {
        _fetching = false;
        _error = error;
      });
      _finish();
      if (_holidays != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Couldn’t refresh holidays. Keeping the current list.',
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
          ErpDataSession<List<CollegeHoliday>>(
            target: HolidaySource.uri,
            resource: 'holidays',
            extractionScript: HolidaySource.script,
            decode: HolidaySource.decode,
            parse: HolidaySource.parse,
            onLoaded: loaded,
            onError: failed,
            onStatus: status,
          ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Holidays'),
      actions: [
        TextButton.icon(
          onPressed: _viewPdf,
          icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
          label: const Text('View PDF'),
          style: TextButton.styleFrom(foregroundColor: AppStyle.lilac),
        ),
        const SizedBox(width: 8),
      ],
    ),
    body: SafeArea(
      top: false,
      child: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _reload,
            color: AppStyle.lilac,
            child: _holidays == null ? _fallback() : _list(),
          ),
          if (_fetching)
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
  Widget _fallback() {
    if (_restoring || _fetching) {
      return ErpLoadingPanel.holidays(
        status: _restoring ? 'Opening your saved holidays…' : _status,
      );
    }
    final loginRequired =
        _error?.reason == ErpDataFailure.credentialsRequired ||
        _error?.reason == ErpDataFailure.authentication;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 20),
        const Icon(Icons.event_note_outlined, size: 40, color: AppStyle.lilac),
        const SizedBox(height: 20),
        Text(
          _fetching ? 'Your college holidays' : 'The holiday list',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (_fetching) ...[
          Text(
            _status,
            style: const TextStyle(color: AppStyle.muted, height: 1.5),
          ),
          const SizedBox(height: 16),
          const LinearProgressIndicator(minHeight: 2, color: AppStyle.lilac),
        ] else
          Text(
            !_supported
                ? 'ERP holidays are available in the mobile app. You can still view the official PDF.'
                : loginRequired
                ? 'Connect ERP to see your college’s holidays here. Use View PDF above to open the official list.'
                : _error?.message ??
                      'Use View PDF above to open the official holiday list.',
            style: const TextStyle(color: AppStyle.muted, height: 1.6),
          ),
        if (!_fetching && _supported) ...[
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: loginRequired ? _profile : _reload,
            icon: Icon(
              loginRequired
                  ? Icons.person_outline_rounded
                  : Icons.refresh_rounded,
            ),
            label: Text(
              loginRequired ? 'Connect ERP in Profile' : 'Try ERP again',
            ),
          ),
          TextButton(onPressed: _openErp, child: const Text('Open ERP')),
        ],
      ],
    );
  }

  Widget _list() {
    final holidays = _holidays!;
    final next = holidays
        .where((holiday) => !holiday.to.isBefore(_today))
        .firstOrNull;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      children: [
        Text('FROM YOUR ERP', style: AppStyle.eyebrow),
        const SizedBox(height: 12),
        if (next != null) ...[
          Text(
            next.from.isAfter(_today) ? 'Next holiday' : 'Holiday today',
            style: const TextStyle(color: AppStyle.lilac, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            next.name,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(_range(next), style: const TextStyle(color: AppStyle.muted)),
        ] else
          Text(
            holidays.isEmpty
                ? 'No holidays listed yet.'
                : 'All listed holidays',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
        for (var index = 0; index < holidays.length; index++) ...[
          if (index == 0 ||
              holidays[index].from.month != holidays[index - 1].from.month ||
              holidays[index].from.year != holidays[index - 1].from.year)
            Padding(
              padding: const EdgeInsets.only(top: 26, bottom: 10),
              child: Text(
                DateFormat(
                  'MMMM yyyy',
                ).format(holidays[index].from).toUpperCase(),
                style: AppStyle.eyebrow,
              ),
            ),
          _holidayRow(holidays[index]),
        ],
        const SizedBox(height: 20),
        Text(
          '${_fetchedAt == null ? '' : 'Updated ${DateFormat('d MMM').format(_fetchedAt!)} · Saved for ${DateFormat('MMMM').format(_fetchedAt!)}\n'}Pull down to refresh from ERP.',
          style: TextStyle(color: AppStyle.muted, fontSize: 12),
        ),
      ],
    );
  }

  String _range(CollegeHoliday holiday) => holiday.from == holiday.to
      ? DateFormat('EEE, d MMM yyyy').format(holiday.from)
      : '${DateFormat('d MMM yyyy').format(holiday.from)} – ${DateFormat('d MMM yyyy').format(holiday.to)}';
  Widget _holidayRow(CollegeHoliday holiday) => Container(
    padding: const EdgeInsets.symmetric(vertical: 17),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: AppStyle.rule, width: .5)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 44,
          child: Column(
            children: [
              Text(
                DateFormat('dd').format(holiday.from),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                DateFormat('EEE').format(holiday.from).toUpperCase(),
                style: const TextStyle(fontSize: 10, color: AppStyle.muted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                holiday.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
              if (holiday.to != holiday.from) ...[
                const SizedBox(height: 5),
                Text(
                  'Until ${DateFormat('d MMM yyyy').format(holiday.to)}',
                  style: const TextStyle(color: AppStyle.lilac, fontSize: 12),
                ),
              ],
              if (holiday.description.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  holiday.description,
                  style: const TextStyle(
                    color: AppStyle.muted,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
  @override
  void dispose() {
    _expiryTimer?.cancel();
    _finish();
    super.dispose();
  }
}
