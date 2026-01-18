import 'package:supabase_flutter/supabase_flutter.dart';

class JointSaving {
  final String id;
  final String name;
  final double targetAmount;
  final double currentBalance;
  final String bankName;
  final String? bankAccountNumber;

  JointSaving({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentBalance,
    required this.bankName,
    this.bankAccountNumber,
  });

  double get progress {
    if (targetAmount <= 0) {
      return 0;
    }
    final value = currentBalance / targetAmount;
    if (value < 0) {
      return 0;
    }
    if (value > 1) {
      return 1;
    }
    return value;
  }

  String get progressMessage {
    if (progress >= 1) {
      return 'Hal mengejutkan menanti!! 🎉';
    }
    if (progress >= 0.5) {
      return 'Hebat! Sebentar lagi kita bisa liburan! ✈️';
    }
    return 'Yuk, pelan-pelan kita kejar targetnya!';
  }

  factory JointSaving.fromMap(Map<String, dynamic> map) {
    final id = map['id'] as String;
    final name = map['name'] as String? ?? '';
    final targetAmount = (map['target_amount'] as num?)?.toDouble() ?? 0;
    final currentBalance = (map['current_balance'] as num?)?.toDouble() ?? 0;
    final bankName = map['bank_name'] as String? ?? 'Jenius';
    final bankAccountNumber = map['bank_account_number'] as String?;

    return JointSaving(
      id: id,
      name: name,
      targetAmount: targetAmount,
      currentBalance: currentBalance,
      bankName: bankName,
      bankAccountNumber: bankAccountNumber,
    );
  }

  static JointSaving fromPostgrestResult(PostgrestMap map) {
    return JointSaving.fromMap(map);
  }
}

