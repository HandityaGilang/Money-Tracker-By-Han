import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/supabase/supabase_manager.dart';
import '../models/personal_month.dart';
import '../models/personal_transaction.dart';

class PersonalFinanceProvider extends ChangeNotifier {
  final List<PersonalMonth> _months = [];
  final List<PersonalTransaction> _transactions = [];
  final List<String> _knownAccounts = [];
  PersonalMonth? _selectedMonth;
  bool _isLoading = false;
  String? _errorMessage;

  List<PersonalMonth> get months => List.unmodifiable(_months);
  List<PersonalTransaction> get transactionsForSelectedMonth =>
      _transactions.where((t) => t.monthId == _selectedMonth?.id).toList();
  List<String> get knownAccounts => List.unmodifiable(_knownAccounts);

  PersonalMonth? get selectedMonth => _selectedMonth;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get totalIncome {
    return transactionsForSelectedMonth
        .where((t) => t.type == PersonalTransactionType.income)
        .fold(0, (sum, t) => sum + t.amount);
  }

  double get totalExpense {
    return transactionsForSelectedMonth
        .where((t) => t.type == PersonalTransactionType.expense)
        .fold(0, (sum, t) => sum + t.amount);
  }

  double get balance => totalIncome - totalExpense;

  Future<void> initialize() async {
    if (_isLoading) {
      return;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (!SupabaseManager.isInitialized) {
        _seedLocalPlaceholderData();
      } else {
        await _loadFromSupabase();
      }
    } catch (_) {
      _errorMessage = 'Gagal memuat data keuangan pribadi.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _seedLocalPlaceholderData() {
    if (_months.isNotEmpty) {
      return;
    }
    final now = DateTime.now();
    final currentId = 'local-${now.year}-${now.month}';
    final month = PersonalMonth(
      id: currentId,
      year: now.year,
      month: now.month,
    );
    _months.add(month);
    _selectedMonth = month;

    _transactions.addAll([
      PersonalTransaction(
        id: 'local-tx-1',
        monthId: currentId,
        date: now.subtract(const Duration(days: 1)),
        type: PersonalTransactionType.expense,
        category: 'Makanan',
        amount: 50000,
        description: 'Sarapan',
      ),
      PersonalTransaction(
        id: 'local-tx-2',
        monthId: currentId,
        date: now.subtract(const Duration(days: 2)),
        type: PersonalTransactionType.income,
        category: 'Mingguan',
        amount: 150000,
        description: 'Uang jajan',
      ),
    ]);
  }

  Future<void> _loadFromSupabase() async {
    final user = SupabaseManager.client.auth.currentUser;
    if (user == null) {
      _seedLocalPlaceholderData();
      return;
    }

    final monthResponse = await SupabaseManager.client
        .from('personal_months')
        .select('id, year, month')
        .eq('user_id', user.id)
        .order('year', ascending: true)
        .order('month', ascending: true);

    _months
      ..clear()
      ..addAll(
        List<Map<String, dynamic>>.from(monthResponse as List)
            .map(
              (row) => PersonalMonth(
                id: row['id'] as String,
                year: row['year'] as int,
                month: row['month'] as int,
              ),
            )
            .toList(),
      );

    if (_months.isEmpty) {
      final now = DateTime.now();
      final insert = await SupabaseManager.client
          .from('personal_months')
          .insert({
            'user_id': user.id,
            'year': now.year,
            'month': now.month,
          })
          .select('id, year, month')
          .single();

      final created = PersonalMonth(
        id: insert['id'] as String,
        year: insert['year'] as int,
        month: insert['month'] as int,
      );
      _months.add(created);
      _selectedMonth = created;
    } else {
      _selectedMonth = _months.last;
    }

    await _loadTransactionsForSelectedMonth();
  }

  Future<void> _loadTransactionsForSelectedMonth() async {
    if (_selectedMonth == null) {
      return;
    }

    final user = SupabaseManager.client.auth.currentUser;
    if (user == null) {
      return;
    }

    final response = await SupabaseManager.client
        .from('personal_transactions')
        .select(
          'id, personal_month_id, date, type, category, amount, description, target_account',
        )
        .eq('user_id', user.id)
        .eq('personal_month_id', _selectedMonth!.id)
        .order('date', ascending: false);

    _transactions
      ..removeWhere((t) => t.monthId == _selectedMonth!.id)
      ..addAll(
        List<Map<String, dynamic>>.from(response as List)
            .map(
              (row) => PersonalTransaction(
                id: row['id'] as String,
                monthId: row['personal_month_id'] as String,
                date: DateTime.parse(row['date'] as String),
                type: PersonalTransactionType.values.firstWhere(
                  (value) =>
                      value.name.toLowerCase() ==
                      (row['type'] as String).toLowerCase(),
                  orElse: () => PersonalTransactionType.expense,
                ),
                category: row['category'] as String,
                amount: (row['amount'] as num).toDouble(),
                description: row['description'] as String?,
                targetAccount: row['target_account'] as String?,
              ),
            )
            .toList(),
      );
  }

  void selectMonth(PersonalMonth month) {
    if (_selectedMonth?.id == month.id) {
      return;
    }
    _selectedMonth = month;
    if (SupabaseManager.isInitialized) {
      _loadTransactionsForSelectedMonth();
    }
    notifyListeners();
  }

  Future<void> createMonth({int? year, int? month}) async {
    final now = DateTime.now();
    final targetYear = year ?? now.year;
    final targetMonth = month ?? now.month;

    if (!SupabaseManager.isInitialized) {
      final id = 'local-$targetYear-$targetMonth-${_months.length + 1}';
      final created = PersonalMonth(
        id: id,
        year: targetYear,
        month: targetMonth,
      );
      _months.add(created);
      _selectedMonth = created;
      notifyListeners();
      return;
    }

    final user = SupabaseManager.client.auth.currentUser;
    if (user == null) {
      return;
    }

    final insert = await SupabaseManager.client
        .from('personal_months')
        .insert({
          'user_id': user.id,
          'year': targetYear,
          'month': targetMonth,
        })
        .select('id, year, month')
        .single();

    final created = PersonalMonth(
      id: insert['id'] as String,
      year: insert['year'] as int,
      month: insert['month'] as int,
    );
    _months.add(created);
    _selectedMonth = created;
    notifyListeners();
  }

  Future<void> loadKnownAccounts() async {
    if (!SupabaseManager.isInitialized) {
      _knownAccounts.clear();
      return;
    }

    final user = SupabaseManager.client.auth.currentUser;
    if (user == null) {
      return;
    }

    try {
      final response = await SupabaseManager.client
          .from('personal_accounts')
          .select('name')
          .eq('user_id', user.id);

      _knownAccounts
        ..clear()
        ..addAll(
          List<Map<String, dynamic>>.from(response as List)
              .map((row) => row['name'] as String)
              .where((name) => name.isNotEmpty)
              .toSet()
              .toList(),
        );
      notifyListeners();
    } catch (_) {}
  }

  Future<void> addTransaction({
    required PersonalTransactionType type,
    required DateTime date,
    required String category,
    required double amount,
    String? description,
    String? targetAccount,
  }) async {
    if (_selectedMonth == null) {
      return;
    }

    final id = 'local-tx-${_transactions.length + 1}';
    final transaction = PersonalTransaction(
      id: id,
      monthId: _selectedMonth!.id,
      date: date,
      type: type,
      category: category,
      amount: amount,
      description: description,
      targetAccount: targetAccount,
    );

    _transactions.insert(0, transaction);
    notifyListeners();

    if (!SupabaseManager.isInitialized) {
      return;
    }

    final user = SupabaseManager.client.auth.currentUser;
    if (user == null) {
      return;
    }

    await SupabaseManager.client.from('personal_transactions').insert({
      'id': id,
      'user_id': user.id,
      'personal_month_id': _selectedMonth!.id,
      'date': DateFormat('yyyy-MM-dd').format(date),
      'type': type.name,
      'category': category,
      'amount': amount,
      'description': description,
      'target_account': targetAccount,
    });
  }

  Future<void> deleteTransaction(String id) async {
    final existing = _transactions.where((t) => t.id == id).toList();
    if (existing.isEmpty) {
      return;
    }
    _transactions.removeWhere((t) => t.id == id);
    notifyListeners();

    if (!SupabaseManager.isInitialized) {
      return;
    }

    final user = SupabaseManager.client.auth.currentUser;
    if (user == null) {
      return;
    }

    try {
      await SupabaseManager.client
          .from('personal_transactions')
          .delete()
          .eq('id', id)
          .eq('user_id', user.id);
    } catch (_) {}
  }
}
