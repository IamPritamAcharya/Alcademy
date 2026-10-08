import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:port/shared/theme/app_style.dart';
import '../../college_resources/data/erp_data_flow.dart';
import '../../college_resources/data/erp_monthly_cache.dart';
import '../../college_resources/data/erp_session_manager.dart';
import '../../college_resources/presentation/erp_data_session.dart';
import '../../college_resources/presentation/erp_loading_panel.dart';
import '../../profile/presentation/profile_page.dart';
import '../data/fees_parser.dart';
import '../data/fees_source.dart';
import '../models/fee_record.dart';

typedef FeesSessionBuilder =
    Widget Function({
      required ValueChanged<List<FeeRecord>> onLoaded,
      required ValueChanged<ErpDataException> onError,
      required ValueChanged<String> onStatus,
    });
typedef ReceiptSessionBuilder =
    Widget Function({
      required FeeRecord record,
      required ValueChanged<Uint8List> onLoaded,
      required ValueChanged<ErpDataException> onError,
      required ValueChanged<String> onStatus,
    });
typedef ReceiptSaver = Future<Uri?> Function(String name, Uint8List bytes);

class FeesPage extends StatefulWidget {
  final FeesSessionBuilder? sessionBuilder;
  final ReceiptSessionBuilder? receiptBuilder;
  final ReceiptSaver? saveReceipt;
  final DateTime Function()? clock;
  const FeesPage({
    super.key,
    this.sessionBuilder,
    this.receiptBuilder,
    this.saveReceipt,
    this.clock,
  });
  @override
  State<FeesPage> createState() => _FeesPageState();
}

class _FeesPageState extends State<FeesPage> {
  final _cache = ErpMonthlyCache<FeeRecord>(
    key: ErpSessionManager.feesCacheKey,
    fromJson: FeeRecord.fromJson,
    toJson: (record) => record.toJson(),
  );
  List<FeeRecord>? _records;
  DateTime? _fetchedAt;
  Timer? _expiryTimer;
  bool _restoring = true;
  DateTime get _now => widget.clock?.call() ?? DateTime.now();
  ErpDataException? _error;
  String _status = 'Checking your ERP session…';
  bool _fetching = false, _saving = false;
  int _attempt = 0;
  FeeRecord? _downloading;
  Completer<void>? _refresh;
  bool get _busy => _fetching || _downloading != null;
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

  Future<void> _restore() async {
    final cached = await _cache.read(_now);
    if (!mounted) return;
    setState(() {
      _records = cached?.records;
      _fetchedAt = cached?.fetchedAt;
      _restoring = false;
      _error = null;
    });
    if (cached == null && _supported) {
      unawaited(_reload());
    } else {
      _scheduleExpiry();
    }
  }

  void _scheduleExpiry() {
    _expiryTimer?.cancel();
    if (_fetchedAt == null) return;
    final delay = ErpMonthlyCache.expiresAt(_fetchedAt!).difference(_now);
    if (delay <= Duration.zero) {
      if (_downloading == null) unawaited(_reload());
    } else {
      _expiryTimer = Timer(delay, () {
        if (mounted) unawaited(_reload());
      });
    }
  }

  void _finish() {
    if (_refresh?.isCompleted == false) _refresh!.complete();
  }

  Future<void> _reload() {
    if (!_supported || _downloading != null) return Future.value();
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
      _records = null;
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

  void _download(FeeRecord record) {
    if (_busy) return;
    setState(() {
      _attempt++;
      _downloading = record;
      _saving = false;
      _status = 'Downloading receipt…';
    });
  }

  void _failed(ErpDataException error, int attempt) {
    if (!mounted || attempt != _attempt) return;
    final receipt = _downloading != null;
    setState(() {
      _fetching = false;
      _downloading = null;
      _saving = false;
      _error = error;
    });
    _finish();
    if (_records != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            receipt
                ? error.message
                : 'Couldn’t refresh. Keeping the current fee records.',
          ),
        ),
      );
    }
    if (receipt) _scheduleExpiry();
  }

  Widget _session() {
    final attempt = _attempt;
    void failed(ErpDataException error) => _failed(error, attempt);
    void status(String message) {
      if (mounted && attempt == _attempt) setState(() => _status = message);
    }

    final record = _downloading;
    if (record != null) {
      Future<void> loaded(Uint8List bytes) async {
        if (!mounted || attempt != _attempt || _saving) return;
        setState(() {
          _saving = true;
          _status = 'Choose where to save your receipt…';
        });
        try {
          final saved =
              await (widget.saveReceipt ??
                  (name, data) => FilePicker.saveFile(
                    fileName: name,
                    bytes: data,
                    mimeType: 'application/pdf',
                    dialogTitle: 'Save fee receipt',
                  ))(FeesSource.fileName(record), bytes);
          if (!mounted || attempt != _attempt) return;
          setState(() {
            _downloading = null;
            _saving = false;
          });
          _scheduleExpiry();
          if (saved != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Receipt downloaded.')),
            );
          }
        } catch (_) {
          failed(
            const ErpDataException(
              ErpDataFailure.unavailable,
              'Couldn’t save the receipt. Please try again.',
            ),
          );
        }
      }

      return KeyedSubtree(
        key: ValueKey('receipt-$attempt'),
        child:
            widget.receiptBuilder?.call(
              record: record,
              onLoaded: loaded,
              onError: failed,
              onStatus: status,
            ) ??
            ErpDataSession<Uint8List>(
              target: FeesSource.uri,
              resource: 'fee receipt',
              extractionScript: FeesSource.receiptScript(record),
              decode: FeesSource.decodeReceipt,
              parse: FeesSource.parseReceipt,
              onLoaded: loaded,
              onError: failed,
              onStatus: status,
            ),
      );
    }
    Future<void> loaded(List<FeeRecord> records) async {
      if (!mounted || attempt != _attempt) return;
      final fetched = _now;
      try {
        await _cache.write(records, fetched);
      } catch (_) {
        // Keep a successful live response usable if local storage fails.
      }
      if (!mounted || attempt != _attempt) return;
      setState(() {
        _records = records;
        _fetching = false;
        _error = null;
        _fetchedAt = fetched;
      });
      _scheduleExpiry();
      _finish();
    }

    return KeyedSubtree(
      key: ValueKey('fees-$attempt'),
      child:
          widget.sessionBuilder?.call(
            onLoaded: loaded,
            onError: failed,
            onStatus: status,
          ) ??
          ErpDataSession<List<FeeRecord>>(
            target: FeesSource.uri,
            resource: 'fees',
            extractionScript: FeesSource.script,
            decode: FeesSource.decodeMarkup,
            parse: FeesParser.parse,
            onLoaded: loaded,
            onError: failed,
            onStatus: status,
          ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Fees & receipts'),
      actions: [
        IconButton(
          tooltip: 'ERP credentials',
          onPressed: _downloading == null ? _profile : null,
          icon: const Icon(Icons.person_outline_rounded),
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
            child: _records == null ? _message() : _list(),
          ),
          if (_busy && _records != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                minHeight: 2,
                color: AppStyle.lilac,
              ),
            ),
          if ((_fetching || _downloading != null) && !_saving)
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
  Widget _message() {
    if (_restoring || _fetching) {
      return ErpLoadingPanel.fees(
        status: _restoring ? 'Opening your saved records…' : _status,
      );
    }
    final login =
        _error?.reason == ErpDataFailure.credentialsRequired ||
        _error?.reason == ErpDataFailure.authentication;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 40),
        const Icon(
          Icons.receipt_long_outlined,
          size: 40,
          color: AppStyle.lilac,
        ),
        const SizedBox(height: 20),
        const Text(
          'Your fee records',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          !_supported
              ? 'Open the mobile app to connect to ERP.'
              : _fetching
              ? _status
              : _error?.message ?? 'No fee records available.',
          style: const TextStyle(color: AppStyle.muted, height: 1.6),
        ),
        if (!_fetching && _supported) ...[
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: login ? _profile : _reload,
            icon: Icon(
              login ? Icons.person_outline_rounded : Icons.refresh_rounded,
            ),
            label: Text(login ? 'Connect ERP in Profile' : 'Try again'),
          ),
        ],
      ],
    );
  }

  Widget _list() {
    final records = _records!;
    // Use only confirmed successful payments for the paid total.
    final total = records
        .where((row) => row.status.toLowerCase() == 'success')
        .fold<int>(0, (sum, row) => sum + row.amountPaise);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppStyle.surface, Color(0xFF302C36)],
            ),
            border: Border.all(color: AppStyle.rule.withValues(alpha: .5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TOTAL PAID', style: AppStyle.eyebrow),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  NumberFormat.currency(
                    locale: 'en_IN',
                    symbol: '₹',
                    decimalDigits: 2,
                  ).format(total / 100),
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -1,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Successful payments',
                style: TextStyle(color: AppStyle.muted, fontSize: 12),
              ),
              const SizedBox(height: 18),
              const Divider(height: 1),
              const SizedBox(height: 14),
              Wrap(
                spacing: 20,
                runSpacing: 6,
                children: [
                  Text(
                    '${records.length} ${records.length == 1 ? 'record' : 'records'}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (records.isNotEmpty)
                    Text(
                      'Latest · ${DateFormat('d MMM yyyy').format(records.first.paidAt)}',
                      style: const TextStyle(
                        color: AppStyle.muted,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('RECEIPTS', style: AppStyle.eyebrow),
        const SizedBox(height: 8),
        if (records.isEmpty)
          const Text(
            'No payment records listed by ERP.',
            style: TextStyle(color: AppStyle.muted),
          ),
        for (var index = 0; index < records.length; index++) ...[
          if (index == 0 ||
              records[index].paidAt.year != records[index - 1].paidAt.year)
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Text(
                '${records[index].paidAt.year}',
                style: AppStyle.eyebrow,
              ),
            ),
          _record(records[index]),
        ],
        const SizedBox(height: 20),
        Text(
          '${_fetchedAt == null ? '' : 'Updated ${DateFormat('d MMM').format(_fetchedAt!)} · Saved for ${DateFormat('MMMM').format(_fetchedAt!)}\n'}Pull down to refresh from ERP.',
          style: TextStyle(color: AppStyle.muted, fontSize: 12),
        ),
      ],
    );
  }

  Widget _record(FeeRecord record) {
    final downloading = _downloading == record;
    final statusColor = record.status.toLowerCase() == 'success'
        ? AppStyle.blue
        : AppStyle.gold;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
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
                  DateFormat('dd').format(record.paidAt),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM').format(record.paidAt).toUpperCase(),
                  style: AppStyle.eyebrow,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '₹${record.amountLabel}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (record.canDownload)
                      IconButton(
                        tooltip: 'Download receipt ${record.receiptNumber}',
                        onPressed: _busy ? null : () => _download(record),
                        style: IconButton.styleFrom(
                          side: const BorderSide(color: AppStyle.rule),
                        ),
                        icon: downloading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: AppStyle.lilac,
                                ),
                              )
                            : const Icon(
                                Icons.download_rounded,
                                size: 20,
                                color: AppStyle.lilac,
                              ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                if (record.accountHead.isNotEmpty)
                  Text(
                    record.accountHead,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    if (record.status.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            record.status,
                            style: TextStyle(color: statusColor, fontSize: 11),
                          ),
                        ],
                      ),
                    if (record.paymentType.isNotEmpty)
                      Text(
                        record.paymentType,
                        style: const TextStyle(
                          color: AppStyle.muted,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Receipt ${record.receiptNumber}',
                  style: const TextStyle(color: AppStyle.muted, fontSize: 12),
                ),
                if (downloading)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _status,
                      style: const TextStyle(
                        color: AppStyle.muted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (record.items.isNotEmpty ||
                    record.orderId.isNotEmpty ||
                    record.trackingId.isNotEmpty)
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    minTileHeight: 40,
                    shape: const Border(),
                    collapsedShape: const Border(),
                    childrenPadding: const EdgeInsets.only(bottom: 8),
                    title: const Text(
                      'Receipt details',
                      style: TextStyle(fontSize: 12, color: AppStyle.muted),
                    ),
                    children: [
                      for (final item in record.items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  [item.head, item.type]
                                      .where((value) => value.isNotEmpty)
                                      .join(' · '),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  item.amount,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (record.orderId.isNotEmpty)
                        _detail('Order / cheque no.', record.orderId),
                      if (record.trackingId.isNotEmpty)
                        _detail('Bank / tracking ID', record.trackingId),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 12,
          color: AppStyle.muted,
          height: 1.5,
        ),
      ),
    ),
  );
  @override
  void dispose() {
    _expiryTimer?.cancel();
    _finish();
    super.dispose();
  }
}
