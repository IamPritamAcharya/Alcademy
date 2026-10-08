import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:port/shared/theme/app_style.dart';
import '../../college_resources/data/erp_data_flow.dart';
import '../../college_resources/presentation/erp_data_session.dart';
import '../../college_resources/presentation/erp_page.dart';
import '../../profile/presentation/profile_page.dart';
import '../../home/presentation/widgets/journal_cover.dart';
import '../data/attendance_cache.dart';
import '../data/attendance_parser.dart';
import '../data/attendance_source.dart';
import '../models/attendance.dart';

typedef AttendanceSessionBuilder =
    Widget Function({
      required ValueChanged<Attendance> onLoaded,
      required ValueChanged<ErpDataException> onError,
      required ValueChanged<String> onStatus,
    });

class AttendancePage extends StatefulWidget {
  final AttendanceSessionBuilder? sessionBuilder;
  final DateTime Function()? clock;
  const AttendancePage({super.key, this.sessionBuilder, this.clock});
  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final _cache = const AttendanceCache();
  Attendance? _data;
  ErpDataException? _error;
  String _status = 'Checking your saved attendance…';
  bool _fetching = false, _monthly = false;
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
    if (_data == null) return;
    final delay = AttendanceCache.expiresAt(_data!.fetchedAt).difference(_now);
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
    Future<void> loaded(Attendance data) async {
      if (!mounted || attempt != _attempt) return;
      try {
        await _cache.write(data);
      } catch (_) {
        /* Keep the live response usable. */
      }
      if (!mounted || attempt != _attempt) return;
      setState(() {
        _data = data;
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
              'Couldn’t refresh. Showing saved attendance. ${error.message}',
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
          ErpDataSession<Attendance>(
            target: AttendanceSource.uri,
            resource: 'attendance',
            extractionScript: AttendanceSource.script,
            decode: AttendanceSource.decode,
            parse: AttendanceParser().parse,
            onLoaded: loaded,
            onError: failed,
            onStatus: status,
          ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Attendance'),
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
              'Your attendance, on mobile.',
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
  Widget _overview(Attendance data) {
    final records = _monthly ? data.months : data.subjects;
    final expiry = AttendanceCache.expiresAt(data.fetchedAt);
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
                            'RECORDED ATTENDANCE',
                            style: AppStyle.eyebrow,
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
                      data.percentage == null
                          ? 'Not recorded yet.'
                          : '${_percent(data.percentage!)}%',
                      style: TextStyle(
                        fontSize: data.percentage == null ? 26 : 38,
                        height: 1.15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${data.attended} attended of ${data.filled} recorded${data.leave == 0 ? '' : ' · ${data.leave} leave credited'}',
                      style: const TextStyle(
                        color: AppStyle.paper,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppStyle.rule)),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _viewTab('Subjects', false)),
                      Expanded(child: _viewTab('Months', true)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _monthly ? 'MONTH BY MONTH' : 'SUBJECT BY SUBJECT',
                  style: AppStyle.eyebrow,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pending classes are waiting for ERP attendance entries.',
                  style: TextStyle(
                    color: AppStyle.muted,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (records.isEmpty)
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(24, 12, 24, 32),
            sliver: SliverToBoxAdapter(
              child: Text(
                'No attendance records published yet.',
                style: TextStyle(color: AppStyle.muted, height: 1.5),
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverList.builder(
            itemCount: records.length,
            itemBuilder: (_, i) => _record(records[i], i),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          sliver: SliverToBoxAdapter(
            child: Text(
              'Saved ${data.fetchedAt.day}/${data.fetchedAt.month} at ${_time(data.fetchedAt)}. Next refresh ${expiry.day}/${expiry.month} at 9:00 AM. Pull down to refresh now.',
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

  Widget _viewTab(String label, bool monthly) {
    final selected = _monthly == monthly;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: () => setState(() => _monthly = monthly),
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppStyle.paper : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? AppStyle.text : AppStyle.muted,
              fontSize: 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _record(AttendanceRecord row, int index) {
    final color = index.isEven ? AppStyle.lilac : AppStyle.blue;
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.only(top: 20, bottom: 4),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppStyle.rule)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    row.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  row.filled == 0 ? '—' : '${_percent(row.percentage)}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -.6,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              row.filled == 0
                  ? 'No entries recorded'
                  : '${row.attended} of ${row.filled} attended',
              style: const TextStyle(
                color: AppStyle.muted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            Semantics(
              label: 'Recorded attendance ${_percent(row.percentage)} percent',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: row.filled == 0
                      ? 0
                      : (row.percentage / 100).clamp(0, 1),
                  minHeight: 2,
                  color: color,
                  backgroundColor: AppStyle.rule,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 20,
              runSpacing: 8,
              children: [
                _inlineCount('absent', row.absent),
                _inlineCount('pending', row.pending),
              ],
            ),
            ExpansionTile(
              key: ValueKey('attendance-details-${row.name}'),
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 16),
              dense: true,
              shape: const Border(),
              collapsedShape: const Border(),
              iconColor: AppStyle.paper,
              collapsedIconColor: AppStyle.muted,
              title: const Text(
                'Leave & totals',
                style: TextStyle(fontSize: 11, color: AppStyle.muted),
              ),
              children: [
                _detail('Lectures conducted', '${row.conducted}'),
                _detail('Attendance recorded', '${row.filled}'),
                _detail('Leave credited as present', '${row.leave}'),
                _detail(
                  'Leave percentage',
                  '${_percent(row.leavePercentage)}%',
                ),
                _detail(
                  'Aggregate including leave',
                  '${_percent(row.aggregatePercentage)}%',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _inlineCount(String label, int value) => Text.rich(
    TextSpan(
      children: [
        TextSpan(
          text: '$value ',
          style: const TextStyle(
            color: AppStyle.paper,
            fontWeight: FontWeight.w600,
          ),
        ),
        TextSpan(text: label),
      ],
    ),
    style: const TextStyle(color: AppStyle.muted, fontSize: 12),
  );

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppStyle.muted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: const TextStyle(
            color: AppStyle.paper,
            fontSize: 12,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
  static String _percent(double value) =>
      value.toStringAsFixed(2).replaceFirst(RegExp(r'\.00$'), '');
  static String _time(DateTime value) =>
      '${value.hour % 12 == 0 ? 12 : value.hour % 12}:${value.minute.toString().padLeft(2, '0')} ${value.hour < 12 ? 'AM' : 'PM'}';
  @override
  void dispose() {
    _expiryTimer?.cancel();
    _finish();
    super.dispose();
  }
}
