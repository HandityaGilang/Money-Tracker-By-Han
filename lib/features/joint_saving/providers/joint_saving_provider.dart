import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_manager.dart';
import '../models/joint_saving.dart';
import '../models/joint_saving_transaction.dart';

class JointSavingProvider extends ChangeNotifier {
  JointSaving? _jointSaving;
  List<JointSavingTransaction> _transactions = [];
  bool _isLoading = false;
  String? _errorMessage;
  RealtimeChannel? _channel;

  JointSaving? get jointSaving => _jointSaving;
  List<JointSavingTransaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get progress => _jointSaving?.progress ?? 0;

  String get formattedCurrentBalance {
    final value = _jointSaving?.currentBalance ?? 0;
    return _formatCurrency(value);
  }

  String get formattedTargetAmount {
    final value = _jointSaving?.targetAmount ?? 0;
    return _formatCurrency(value);
  }

  String get progressMessage => _jointSaving?.progressMessage ?? '';

  Future<void> initialize() async {
    if (_isLoading) {
      return;
    }
    if (!SupabaseManager.isInitialized) {
      _errorMessage = 'Supabase belum dikonfigurasi.';
      _isLoading = false;
      notifyListeners();
      return;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _loadJointSaving();
      await _loadTransactions();
      _subscribeRealtime();
    } catch (error) {
      _errorMessage = 'Gagal memuat tabungan bersama.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    try {
      await _loadJointSaving();
      await _loadTransactions();
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _loadJointSaving() async {
    final userId = SupabaseManager.client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('User belum login.');
    }

    final response = await SupabaseManager.client
        .from('joint_savings')
        .select(
          'id, name, target_amount, bank_name, bank_account_number, '
          'joint_saving_transactions(amount), '
          'joint_saving_members!inner(user_id)',
        )
        .eq('joint_saving_members.user_id', userId)
        .limit(1)
        .maybeSingle();

    if (response == null) {
      throw StateError('Tidak ada tabungan bersama yang terdaftar.');
    }

    double currentBalance = 0;
    final transactions = response['joint_saving_transactions'];
    if (transactions is List) {
      for (final transaction in transactions) {
        if (transaction is Map<String, dynamic>) {
          currentBalance += (transaction['amount'] as num?)?.toDouble() ?? 0;
        }
      }
    }

    final data = Map<String, dynamic>.from(response);
    data['current_balance'] = currentBalance;

    _jointSaving = JointSaving.fromMap(data);
  }

  Future<void> _loadTransactions() async {
    if (_jointSaving == null) {
      _transactions = [];
      return;
    }

    final response = await SupabaseManager.client
        .from('joint_saving_transactions')
        .select('id, date, amount, source')
        .eq('joint_saving_id', _jointSaving!.id)
        .order('date', ascending: false);

    final list = List<Map<String, dynamic>>.from(response as List);
    _transactions = list.map(JointSavingTransaction.fromMap).toList();
  }

  void _subscribeRealtime() {
    _channel?.unsubscribe();

    if (_jointSaving == null) {
      return;
    }

    _channel = SupabaseManager.client
        .channel('joint_saving_transactions')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'joint_saving_transactions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'joint_saving_id',
            value: _jointSaving!.id,
          ),
          callback: (payload) {
            final newRecord = Map<String, dynamic>.from(payload.newRecord);
            final transaction = JointSavingTransaction.fromMap(newRecord);
            _transactions = [transaction, ..._transactions];

            final current = _jointSaving;
            if (current != null) {
              final updated = JointSaving(
                id: current.id,
                name: current.name,
                targetAmount: current.targetAmount,
                currentBalance: current.currentBalance + transaction.amount,
                bankName: current.bankName,
                bankAccountNumber: current.bankAccountNumber,
              );
              _jointSaving = updated;
            }

            notifyListeners();
          },
        )
        .subscribe();
  }

  Future<void> addTransaction({
    required DateTime date,
    required double amount,
    required String source,
  }) async {
    if (_jointSaving == null) {
      throw StateError('Tabungan bersama belum dimuat.');
    }

    final user = SupabaseManager.client.auth.currentUser;
    if (user == null) {
      throw StateError('User belum login.');
    }

    final response = await SupabaseManager.client
        .from('joint_saving_transactions')
        .insert({
          'joint_saving_id': _jointSaving!.id,
          'date': DateFormat('yyyy-MM-dd').format(date),
          'amount': amount,
          'source': source,
          'sender_id': user.id,
        })
        .select('id, date, amount, source')
        .single();

    final data = Map<String, dynamic>.from(response);
    final transaction = JointSavingTransaction.fromMap(data);
    _transactions = [transaction, ..._transactions];

    final current = _jointSaving;
    if (current != null) {
      _jointSaving = JointSaving(
        id: current.id,
        name: current.name,
        targetAmount: current.targetAmount,
        currentBalance: current.currentBalance + transaction.amount,
        bankName: current.bankName,
        bankAccountNumber: current.bankAccountNumber,
      );
    }

    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    final existing = _transactions.where((t) => t.id == id).toList();
    if (existing.isEmpty) {
      return;
    }
    final removedTx = existing.first;

    _transactions = _transactions.where((t) => t.id != id).toList();

    final current = _jointSaving;
    if (current != null) {
      _jointSaving = JointSaving(
        id: current.id,
        name: current.name,
        targetAmount: current.targetAmount,
        currentBalance: current.currentBalance - removedTx.amount,
        bankName: current.bankName,
        bankAccountNumber: current.bankAccountNumber,
      );
    }

    notifyListeners();

    if (!SupabaseManager.isInitialized) {
      return;
    }

    try {
      await SupabaseManager.client
          .from('joint_saving_transactions')
          .delete()
          .eq('id', id);
    } catch (_) {}
  }

  String _formatCurrency(double value) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(value);
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}
