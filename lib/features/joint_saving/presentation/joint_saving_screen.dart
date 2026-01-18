import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/formatters/rupiah_input_formatter.dart';
import '../providers/joint_saving_provider.dart';

class JointSavingScreen extends StatefulWidget {
  const JointSavingScreen({super.key});

  @override
  State<JointSavingScreen> createState() => _JointSavingScreenState();
}

class _JointSavingScreenState extends State<JointSavingScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final provider = context.read<JointSavingProvider>();
      provider.initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JointSavingProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (provider.isLoading && provider.jointSaving == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (provider.errorMessage != null && provider.jointSaving == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tabungan Bersama'),
        ),
        body: Center(
          child: Text(provider.errorMessage!),
        ),
      );
    }

    final saving = provider.jointSaving;

    return Scaffold(
      appBar: AppBar(
        title: Text(saving?.name ?? 'Tabungan Bersama'),
      ),
      body: RefreshIndicator(
        onRefresh: provider.refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (saving != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      saving.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          provider.formattedCurrentBalance,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Target: ${provider.formattedTargetAmount}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: provider.progress,
                        minHeight: 10,
                        backgroundColor: theme.dividerColor.withAlpha(
                          (0.2 * 255).round(),
                        ),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(colorScheme.primary),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      saving.progressMessage,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: colorScheme.primary.withAlpha(
                          (0.1 * 255).round(),
                        ),
                      ),
                      child: const Icon(Icons.credit_card),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            saving.bankName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (saving.bankAccountNumber != null &&
                              saving.bankAccountNumber!.isNotEmpty)
                            Text(
                              saving.bankAccountNumber!,
                              style: theme.textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            Text(
              'Riwayat Pengisian',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            if (provider.transactions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Belum ada riwayat pengisian.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              )
            else
              ...provider.transactions.map(
                (transaction) {
                  final formattedDate =
                      DateFormat('dd MMM yyyy').format(transaction.date);
                  final amountText = NumberFormat.currency(
                    locale: 'id_ID',
                    symbol: 'Rp ',
                    decimalDigits: 0,
                  ).format(transaction.amount);

                  return Dismissible(
                    key: ValueKey(transaction.id),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (direction) async {
                      return await showDialog<bool>(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('Hapus?'),
                                content: const Text(
                                  'Yakin ingin menghapus transaksi ini?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop(false);
                                    },
                                    child: const Text('Batal'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop(true);
                                    },
                                    child: const Text('Hapus'),
                                  ),
                                ],
                              );
                            },
                          ) ??
                          false;
                    },
                    onDismissed: (direction) {
                      context
                          .read<JointSavingProvider>()
                          .deleteTransaction(transaction.id);
                    },
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      leading: CircleAvatar(
                        backgroundColor: colorScheme.primary.withAlpha(
                          (0.1 * 255).round(),
                        ),
                        child: Icon(
                          Icons.arrow_upward,
                          color: colorScheme.primary,
                        ),
                      ),
                      title: Text(
                        amountText,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        '${transaction.source} • ${transaction.senderName.isEmpty ? '-' : transaction.senderName}\n$formattedDate',
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddTransactionSheet(context);
        },
        icon: const Icon(Icons.add),
        label: const Text('Tambah Pengisian'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _showAddTransactionSheet(BuildContext context) {
    final provider = context.read<JointSavingProvider>();
    final theme = Theme.of(context);

    final formKey = GlobalKey<FormState>();
    DateTime selectedDate = DateTime.now();
    final amountController = TextEditingController();
    String selectedSource = 'Shopeepay';
    final sources = ['Shopeepay', 'BCA', 'BNI', 'BRI', 'Mandiri', 'Tunai'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Text(
                  'Tambah Pengisian',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Tanggal',
                  ),
                  controller: TextEditingController(
                    text: DateFormat('dd MMM yyyy').format(selectedDate),
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    RupiahInputFormatter(),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Jumlah',
                    hintText: 'Contoh: 500.000',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Jumlah wajib diisi';
                    }
                    final parsed = double.tryParse(
                      value.replaceAll('.', '').replaceAll(',', ''),
                    );
                    if (parsed == null || parsed <= 0) {
                      return 'Jumlah tidak valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedSource,
                  items: sources
                      .map(
                        (source) => DropdownMenuItem(
                          value: source,
                          child: Text(source),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      selectedSource = value;
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Sumber',
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) {
                      return;
                    }
                    final amount = double.parse(
                      amountController.text
                          .replaceAll('.', '')
                          .replaceAll(',', ''),
                    );
                    try {
                      await provider.addTransaction(
                        date: selectedDate,
                        amount: amount,
                        source: selectedSource,
                      );
                      if (Navigator.canPop(context)) {
                        Navigator.of(context).pop();
                      }
                    } catch (error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Gagal menyimpan pengisian: $error',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
