enum PersonalTransactionType {
  income,
  expense,
  transfer,
}

class PersonalTransaction {
  final String id;
  final String monthId;
  final DateTime date;
  final PersonalTransactionType type;
  final String category;
  final double amount;
  final String? description;
  final String? targetAccount;

  PersonalTransaction({
    required this.id,
    required this.monthId,
    required this.date,
    required this.type,
    required this.category,
    required this.amount,
    this.description,
    this.targetAccount,
  });
}

