class FeeItem {
  final String head, type, amount;
  const FeeItem({required this.head, required this.type, required this.amount});
}

class FeeRecord {
  final int amountPaise;
  final String amountLabel, paymentType, accountHead, dateLabel, receiptNumber;
  final String orderId, trackingId, status;
  final DateTime paidAt;
  final bool canDownload;
  final List<FeeItem> items;
  const FeeRecord({
    required this.amountPaise,
    required this.amountLabel,
    required this.paymentType,
    required this.accountHead,
    required this.dateLabel,
    required this.receiptNumber,
    required this.orderId,
    required this.trackingId,
    required this.status,
    required this.paidAt,
    required this.canDownload,
    required this.items,
  });
  factory FeeRecord.fromJson(Map<String, dynamic> data) => FeeRecord(
    amountPaise: data['amountPaise'] as int,
    amountLabel: data['amountLabel'] as String,
    paymentType: data['paymentType'] as String,
    accountHead: data['accountHead'] as String,
    dateLabel: data['dateLabel'] as String,
    receiptNumber: data['receiptNumber'] as String,
    orderId: data['orderId'] as String,
    trackingId: data['trackingId'] as String,
    status: data['status'] as String,
    paidAt: DateTime.parse(data['paidAt'] as String),
    canDownload: data['canDownload'] as bool,
    items: List.unmodifiable(
      (data['items'] as List).map(
        (row) => FeeItem(
          head: row['head'] as String,
          type: row['type'] as String,
          amount: row['amount'] as String,
        ),
      ),
    ),
  );
  Map<String, dynamic> toJson() => {
    'amountPaise': amountPaise,
    'amountLabel': amountLabel,
    'paymentType': paymentType,
    'accountHead': accountHead,
    'dateLabel': dateLabel,
    'receiptNumber': receiptNumber,
    'orderId': orderId,
    'trackingId': trackingId,
    'status': status,
    'paidAt': paidAt.toIso8601String(),
    'canDownload': canDownload,
    'items': [
      for (final item in items)
        {'head': item.head, 'type': item.type, 'amount': item.amount},
    ],
  };
}
