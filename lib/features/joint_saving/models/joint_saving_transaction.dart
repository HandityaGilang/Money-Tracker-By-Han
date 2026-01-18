class JointSavingTransaction {
  final String id;
  final DateTime date;
  final double amount;
  final String source;
  final String senderName;

  JointSavingTransaction({
    required this.id,
    required this.date,
    required this.amount,
    required this.source,
    required this.senderName,
  });

  factory JointSavingTransaction.fromMap(Map<String, dynamic> map) {
    final id = map['id'] as String;
    final dateString = map['date'] as String?;
    final date = dateString != null ? DateTime.parse(dateString) : DateTime.now();
    final amount = (map['amount'] as num?)?.toDouble() ?? 0;
    final source = map['source'] as String? ?? '-';

    String senderName = '';
    final sender = map['sender'];
    if (sender is Map<String, dynamic>) {
      senderName = sender['full_name'] as String? ?? '';
    } else {
      senderName = map['sender_name'] as String? ?? '';
    }

    return JointSavingTransaction(
      id: id,
      date: date,
      amount: amount,
      source: source,
      senderName: senderName,
    );
  }
}

