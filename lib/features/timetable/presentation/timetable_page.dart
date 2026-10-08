import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:port/shared/theme/app_style.dart';
import '../../college_resources/presentation/erp_page.dart';
import '../../home/presentation/widgets/journal_cover.dart';
import '../../profile/presentation/profile_page.dart';
import '../data/erp_timetable_flow.dart';
import '../data/timetable_parser.dart';
import '../data/timetable_cache.dart';
import '../models/timetable.dart';
import 'timetable_session.dart';

typedef TimetableSessionBuilder =
    Widget Function({
      required ValueChanged<Timetable> onLoaded,
      required ValueChanged<TimetableLoadException> onError,
      required ValueChanged<String> onStatus,
    });

class TimetablePage extends StatefulWidget {
  final TimetableSessionBuilder? sessionBuilder;
  final DateTime Function()? clock;
  const TimetablePage({super.key, this.sessionBuilder, this.clock});
  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  Timetable? _timetable;
  TimetableLoadException? _error;
  String _status = 'Checking your ERP session…';
  int _attempt = 0;
  bool _fetching = false;
  bool _readingCache = true;
  Completer<void>? _refresh;
  final _cache = const TimetableCache();
  late int _day;
  Timer? _clockTimer;
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
    _day = _now.weekday;
    _restore();
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted && _timetable != null) {
        final fetched = _timetable!.fetchedAt.toLocal();
        if (!_fetching &&
            (fetched.year != _now.year || fetched.month != _now.month)) {
          _reload();
        } else {
          setState(() {});
        }
      }
    });
  }

  Future<void> _restore() async {
    final data = await _cache.read(_now);
    if (!mounted) return;
    setState(() {
      _readingCache = false;
      _timetable = data;
      _error = null;
    });
    if (data == null && _supported) unawaited(_reload());
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

  void _finishRefresh() {
    if (_refresh?.isCompleted == false) _refresh!.complete();
  }

  Future<void> _profile() async {
    _finishRefresh();
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
    if (mounted) _reload();
  }

  Widget _session() {
    final attempt = _attempt;
    Future<void> loaded(Timetable value) async {
      if (!mounted || attempt != _attempt) return;
      try {
        await _cache.write(value);
      } catch (_) {
        // The current schedule is still usable if local storage is unavailable.
      }
      if (!mounted || attempt != _attempt) return;
      setState(() {
        _timetable = value;
        _error = null;
        _fetching = false;
      });
      _finishRefresh();
    }

    void failed(TimetableLoadException error) {
      if (!mounted || attempt != _attempt) return;
      setState(() {
        _fetching = false;
        if (_timetable == null) _error = error;
      });
      _finishRefresh();
      if (_timetable != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Couldn’t refresh. Showing your saved timetable. ${error.message}',
            ),
          ),
        );
      }
    }

    void status(String message) {
      if (!mounted || attempt != _attempt) return;
      setState(() => _status = message);
    }

    return KeyedSubtree(
      key: ValueKey(_attempt),
      child:
          widget.sessionBuilder?.call(
            onLoaded: loaded,
            onError: failed,
            onStatus: status,
          ) ??
          TimetableSession(onLoaded: loaded, onError: failed, onStatus: status),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Timetable'),
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
            _messagePanel(
              icon: Icons.devices_outlined,
              title: 'Your schedule, on mobile.',
              message:
                  'The ERP timetable is available in the Android and iOS app.',
            )
          else if (_error != null)
            _messagePanel(
              icon: _error!.reason == TimetableFailure.credentialsRequired
                  ? Icons.key_rounded
                  : Icons.calendar_month_outlined,
              title: _error!.reason == TimetableFailure.credentialsRequired
                  ? 'Connect your ERP.'
                  : 'A small pause.',
              message: _error!.message,
              actions: true,
            )
          else if (_timetable == null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppStyle.lilac,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Making room for your week.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -.6,
                      ),
                    ),
                    const SizedBox(height: 12),
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
              child: _schedule(_timetable!),
            ),
          if (_supported && !_readingCache && _fetching)
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

  Widget _messagePanel({
    required IconData icon,
    required String title,
    required String message,
    bool actions = false,
  }) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppStyle.lilac, size: 38),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                letterSpacing: -.8,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppStyle.muted, height: 1.6),
            ),
            if (actions) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed:
                    _error!.reason == TimetableFailure.credentialsRequired ||
                        _error!.reason == TimetableFailure.authentication
                    ? _profile
                    : _reload,
                icon: Icon(
                  _error!.reason == TimetableFailure.credentialsRequired ||
                          _error!.reason == TimetableFailure.authentication
                      ? Icons.person_outline_rounded
                      : Icons.refresh_rounded,
                ),
                label: Text(
                  _error!.reason == TimetableFailure.credentialsRequired ||
                          _error!.reason == TimetableFailure.authentication
                      ? 'Edit ERP credentials'
                      : 'Try again',
                ),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: _erp,
                icon: const Icon(Icons.open_in_new_rounded, size: 17),
                label: const Text('Open ERP'),
              ),
            ],
          ],
        ),
      ),
    ),
  );

  Widget _schedule(Timetable data) {
    final lessons = data.forDay(_day);
    final now = _now;
    final currentMinute = now.hour * 60 + now.minute;
    final current = _day == now.weekday
        ? lessons
              .where(
                (lesson) =>
                    lesson.startMinute <= currentMinute &&
                    lesson.endMinute > currentMinute,
              )
              .firstOrNull
        : null;
    final entries = <({int minute, Widget child})>[
      for (final lesson in lessons)
        (
          minute: lesson.startMinute,
          child: _lesson(lesson, active: lesson == current),
        ),
      if (lessons.isNotEmpty)
        for (final pause in data.breaks)
          (
            minute: pause.startMinute,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  SizedBox(
                    width: _timeWidth,
                    child: Text(
                      _time(pause.startMinute),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppStyle.muted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.coffee_outlined,
                    size: 16,
                    color: AppStyle.muted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Break · ${pause.endMinute - pause.startMinute} min',
                      style: const TextStyle(
                        color: AppStyle.muted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    ]..sort((a, b) => a.minute.compareTo(b.minute));
    final multiple = lessons.any((lesson) => lesson.classes.length > 1);
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _day == now.weekday
                                    ? 'Today'
                                    : 'Weekly schedule',
                                style: AppStyle.eyebrow,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '${TimetableParser.dayNames[_day - 1]}.',
                                style: const TextStyle(
                                  fontSize: 30,
                                  height: 1.1,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -.9,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Open ERP',
                          onPressed: _erp,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          icon: const Icon(
                            Icons.north_east_rounded,
                            size: 20,
                            color: AppStyle.paper,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      data.division.isEmpty
                          ? 'Your ERP division timetable'
                          : data.division,
                      style: const TextStyle(
                        color: AppStyle.paper,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                    if (data.academicYear.isNotEmpty ||
                        data.effectiveFrom.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        [
                          if (data.academicYear.isNotEmpty) data.academicYear,
                          if (data.effectiveFrom.isNotEmpty)
                            'Effective ${data.effectiveFrom}',
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
          ),
        ),
        SliverToBoxAdapter(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 14),
            child: Row(
              children: [
                for (var day = 1; day <= 7; day++) ...[
                  if (day > 1) const SizedBox(width: 8),
                  Semantics(
                    selected: _day == day,
                    label:
                        '${TimetableParser.dayNames[day - 1]}, ${data.forDay(day).length} sessions',
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => setState(() => _day = day),
                        child: AnimatedContainer(
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 17,
                            vertical: 15,
                          ),
                          decoration: BoxDecoration(
                            color: _day == day
                                ? AppStyle.paper
                                : AppStyle.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: _day == day
                                  ? AppStyle.paper
                                  : day == now.weekday
                                  ? AppStyle.lilac.withValues(alpha: .55)
                                  : AppStyle.rule,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                TimetableParser.dayNames[day - 1].substring(
                                  0,
                                  3,
                                ),
                                style: TextStyle(
                                  color: _day == day
                                      ? AppStyle.background
                                      : AppStyle.text,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${data.forDay(day).length} ${data.forDay(day).length == 1 ? 'class' : 'classes'}',
                                style: TextStyle(
                                  color: _day == day
                                      ? AppStyle.cover
                                      : AppStyle.muted,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _day == now.weekday
                        ? 'TODAY’S LINEUP'
                        : '${TimetableParser.dayNames[_day - 1].toUpperCase()}’S LINEUP',
                    style: AppStyle.eyebrow,
                  ),
                ),
                if (_day != now.weekday)
                  TextButton.icon(
                    onPressed: () => setState(() => _day = now.weekday),
                    icon: const Icon(Icons.undo_rounded, size: 15),
                    label: const Text(
                      'Back to today',
                      style: TextStyle(fontSize: 12),
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Icon(
                      Icons.today_outlined,
                      size: 17,
                      color: AppStyle.muted,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (multiple)
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(24, 4, 24, 20),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Some periods list multiple subjects. All ERP entries are shown.',
                style: TextStyle(
                  color: AppStyle.muted,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
          ),
        if (lessons.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 48),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.wb_sunny_outlined,
                    color: AppStyle.gold,
                    size: 32,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'A little breathing room.',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    data.weekdays.contains(_day)
                        ? 'No classes are listed for this day in ERP.'
                        : 'ERP doesn’t include this day in your division timetable.',
                    style: const TextStyle(color: AppStyle.muted, height: 1.6),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
            sliver: SliverList.builder(
              itemCount: entries.length,
              itemBuilder: (_, index) => entries[index].child,
            ),
          ),
        if (data.subjects.isNotEmpty || data.faculty.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  if (data.subjects.isNotEmpty)
                    _legend('Subject full names', data.subjects, AppStyle.blue),
                  if (data.faculty.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _legend('Faculty full names', data.faculty, AppStyle.lilac),
                  ],
                ],
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
          sliver: SliverToBoxAdapter(
            child: Text(
              'Saved on ${data.fetchedAt.day}/${data.fetchedAt.month}/${data.fetchedAt.year}. Cached through this calendar month. Pull down to refresh.',
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

  double get _timeWidth =>
      MediaQuery.textScalerOf(context).scale(62).clamp(62, 96).toDouble();

  Widget _legend(
    String title,
    Map<String, String> entries,
    Color color,
  ) => Container(
    decoration: BoxDecoration(
      color: AppStyle.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppStyle.rule),
    ),
    clipBehavior: Clip.antiAlias,
    child: ExpansionTile(
      key: ValueKey(title),
      shape: const Border(),
      collapsedShape: const Border(),
      tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      iconColor: color,
      collapsedIconColor: AppStyle.muted,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        '${entries.length} listed in ERP',
        style: const TextStyle(color: AppStyle.muted, fontSize: 12),
      ),
      children: [
        for (final entry in entries.entries)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: MediaQuery.textScalerOf(context).scale(60),
                  child: Text(
                    entry.key,
                    style: TextStyle(color: color, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(entry.value, style: const TextStyle(height: 1.5)),
                ),
              ],
            ),
          ),
      ],
    ),
  );

  Widget _lesson(TimetableLesson lesson, {required bool active}) {
    final color = active
        ? AppStyle.accent
        : lesson.isLab
        ? AppStyle.lilac
        : AppStyle.blue;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _timeWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  _time(lesson.startMinute),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppStyle.paper,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _time(lesson.endMinute),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppStyle.muted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppStyle.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active ? color.withValues(alpha: .6) : AppStyle.rule,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Text(
                        active
                            ? 'IN SESSION'
                            : lesson.isLab
                            ? 'LAB SESSION'
                            : 'CLASS',
                        style: AppStyle.eyebrow.copyWith(
                          color: color,
                          fontSize: 9,
                        ),
                      ),
                      Text(
                        _duration(lesson.endMinute - lesson.startMinute),
                        style: const TextStyle(
                          color: AppStyle.muted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  for (
                    var index = 0;
                    index < lesson.classes.length;
                    index++
                  ) ...[
                    if (index > 0)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Divider(height: 1),
                      ),
                    const SizedBox(height: 10),
                    Text(
                      lesson.classes[index].title,
                      style: TextStyle(
                        color: active ? AppStyle.text : AppStyle.paper,
                        fontSize: 17,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      [
                        if (lesson.classes[index].code != null)
                          lesson.classes[index].code!,
                        if (lesson.classes[index].batch != null)
                          'Batch ${lesson.classes[index].batch}',
                      ].join(' · '),
                      style: TextStyle(color: color, fontSize: 11, height: 1.5),
                    ),
                    if (lesson.classes[index].location != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: AppStyle.muted,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              lesson.classes[index].location!,
                              style: const TextStyle(
                                color: AppStyle.muted,
                                fontSize: 11,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _time(int minute) =>
      '${(minute ~/ 60) % 12 == 0 ? 12 : (minute ~/ 60) % 12}:${(minute % 60).toString().padLeft(2, '0')} ${minute < 720 ? 'AM' : 'PM'}';
  static String _duration(int minute) => minute < 60
      ? '${minute}m'
      : '${minute ~/ 60}h${minute % 60 == 0 ? '' : ' ${minute % 60}m'}';

  @override
  void dispose() {
    _clockTimer?.cancel();
    _finishRefresh();
    super.dispose();
  }
}
