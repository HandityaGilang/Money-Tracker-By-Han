import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/formatters/rupiah_input_formatter.dart';
import 'package:provider/provider.dart';

import '../models/personal_month.dart';
import '../models/personal_transaction.dart';
import '../providers/personal_finance_provider.dart';

class PersonalFinanceScreen extends StatefulWidget {
  const PersonalFinanceScreen({super.key});

  @override
  State<PersonalFinanceScreen> createState() => _PersonalFinanceScreenState();
}

class _PersonalFinanceScreenState extends State<PersonalFinanceScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final provider = context.read<PersonalFinanceProvider>();
      provider.initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PersonalFinanceProvider>();

    if (provider.isLoading && provider.selectedMonth == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Keuangan Pribadi'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 72,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                if (index < provider.months.length) {
                  final month = provider.months[index];
                  final isSelected = provider.selectedMonth?.id == month.id;
                  return _MonthChip(
                    month: month,
                    isSelected: isSelected,
                    onTap: () {
                      provider.selectMonth(month);
                    },
                  );
                }
                return _AddMonthChip(
                  onTap: () {
                    _showCreateMonthDialog(context);
                  },
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: provider.months.length + 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SummaryRow(
              income: provider.totalIncome,
              expense: provider.totalExpense,
              balance: provider.balance,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _TransactionList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddTransactionSheet(context);
        },
        icon: const Icon(Icons.add),
        label: const Text('Tambah Transaksi'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _showAddTransactionSheet(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.read<PersonalFinanceProvider>();

    final formKey = GlobalKey<FormState>();
    PersonalTransactionType selectedType = PersonalTransactionType.expense;
    DateTime selectedDate = DateTime.now();
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    final targetAccountController = TextEditingController();

    final expenseCategories = [
      'Makanan',
      'Hutang',
      'Shopping',
      'Hiburan',
      'Pendidikan',
      'Beauty',
      'Olahraga',
      'Social',
      'Transportasi',
      'Pakaian',
      'Kesehatan',
      'Peliharaan',
      'Donation',
    ];

    final incomeCategories = [
      'Uang Kejut',
      'Mingguan',
      'Gaji',
      'Investment',
      'Lainnya',
    ];

    String selectedCategory = expenseCategories.first;

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
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              if (selectedType == PersonalTransactionType.transfer &&
                  provider.knownAccounts.isEmpty) {
                provider.loadKnownAccounts();
              }
              return Form(
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
                      'Tambah Transaksi',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SegmentedButton<PersonalTransactionType>(
                      segments: const [
                        ButtonSegment(
                          value: PersonalTransactionType.expense,
                          label: Text('Expense'),
                        ),
                        ButtonSegment(
                          value: PersonalTransactionType.income,
                          label: Text('Income'),
                        ),
                        ButtonSegment(
                          value: PersonalTransactionType.transfer,
                          label: Text('Transfer'),
                        ),
                      ],
                      selected: {selectedType},
                      onSelectionChanged: (values) {
                        final value = values.first;
                        setSheetState(() {
                          selectedType = value;
                          selectedCategory =
                              value == PersonalTransactionType.expense
                                  ? expenseCategories.first
                                  : value == PersonalTransactionType.income
                                      ? incomeCategories.first
                                      : 'Transfer';
                        });
                      },
                    ),
                    const SizedBox(height: 12),
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
                          setSheetState(() {
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
                        hintText: 'Contoh: 150.000',
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
                    if (selectedType != PersonalTransactionType.transfer)
                      TextFormField(
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Kategori',
                        ),
                        controller: TextEditingController(
                          text: selectedCategory,
                        ),
                        onTap: () async {
                          final result = await _showCategoryPicker(
                            context: context,
                            title: 'Pilih Kategori',
                            categories:
                                selectedType == PersonalTransactionType.expense
                                    ? expenseCategories
                                    : incomeCategories,
                            selected: selectedCategory,
                          );
                          if (result != null) {
                            setSheetState(() {
                              selectedCategory = result;
                            });
                          }
                        },
                      ),
                    if (selectedType == PersonalTransactionType.transfer)
                      Builder(
                        builder: (context) {
                          final knownAccounts = provider.knownAccounts;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (knownAccounts.isNotEmpty) ...[
                                Text(
                                  'Pilih Akun Tujuan',
                                  style: theme.textTheme.labelMedium,
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: knownAccounts
                                      .map(
                                        (name) => _CategoryCircle(
                                          label: name,
                                          isSelected:
                                              targetAccountController.text ==
                                                  name,
                                          onTap: () {
                                            setSheetState(() {
                                              targetAccountController.text =
                                                  name;
                                            });
                                          },
                                        ),
                                      )
                                      .toList(),
                                ),
                                const SizedBox(height: 12),
                              ],
                              TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Akun Tujuan',
                                  hintText:
                                      'Contoh: Tabungan Jenius, Dana, dll',
                                ),
                                controller: targetAccountController,
                              ),
                            ],
                          );
                        },
                      ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Catatan (opsional)',
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        if (!formKey.currentState!.validate()) {
                          return;
                        }

                        final amount = double.parse(
                          amountController.text
                              .replaceAll('.', '')
                              .replaceAll(',', ''),
                        );

                        if (Navigator.canPop(context)) {
                          Navigator.of(context).pop();
                        }

                        provider.addTransaction(
                          type: selectedType,
                          date: selectedDate,
                          category:
                              selectedType == PersonalTransactionType.transfer
                                  ? 'Transfer'
                                  : selectedCategory,
                          amount: amount,
                          description: descriptionController.text.isEmpty
                              ? null
                              : descriptionController.text,
                          targetAccount: targetAccountController.text.isEmpty
                              ? null
                              : targetAccountController.text,
                        );
                      },
                      child: const Text('Simpan'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showCreateMonthDialog(BuildContext context) async {
    final provider = context.read<PersonalFinanceProvider>();
    final now = DateTime.now();
    int selectedYear = now.year;
    int selectedMonth = now.month;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Buat Folder Bulan'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: selectedYear,
                          decoration: const InputDecoration(
                            labelText: 'Tahun',
                          ),
                          items: List<int>.generate(
                            7,
                            (index) => now.year - 3 + index,
                          )
                              .map(
                                (year) => DropdownMenuItem(
                                  value: year,
                                  child: Text(year.toString()),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() {
                                selectedYear = value;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: selectedMonth,
                          decoration: const InputDecoration(
                            labelText: 'Bulan',
                          ),
                          items: List<int>.generate(
                            12,
                            (index) => index + 1,
                          )
                              .map(
                                (month) => DropdownMenuItem(
                                  value: month,
                                  child: Text(month.toString()),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() {
                                selectedMonth = value;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final matchingMonths = provider.months.where(
                  (month) =>
                      month.year == selectedYear &&
                      month.month == selectedMonth,
                );
                if (matchingMonths.isNotEmpty) {
                  provider.selectMonth(matchingMonths.first);
                } else {
                  provider.createMonth(
                    year: selectedYear,
                    month: selectedMonth,
                  );
                }
                Navigator.of(context).pop();
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _showCategoryPicker({
    required BuildContext context,
    required String title,
    required List<String> categories,
    required String selected,
  }) async {
    String current = selected;

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                return SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories
                        .map(
                          (value) => _CategoryCircle(
                            label: value,
                            isSelected: current == value,
                            onTap: () {
                              setDialogState(() {
                                current = value;
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(current);
              },
              child: const Text('Pilih'),
            ),
          ],
        );
      },
    );
  }
}

class _CategoryCircle extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryCircle({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isSelected ? colorScheme.primary : colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              label.length > 4 ? label.substring(0, 4) : label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isSelected
                    ? Colors.white
                    : theme.textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: theme.textTheme.labelSmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthChip extends StatelessWidget {
  final PersonalMonth month;
  final bool isSelected;
  final VoidCallback onTap;

  const _MonthChip({
    required this.month,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : colorScheme.surface,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          month.label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isSelected ? Colors.white : null,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _AddMonthChip extends StatelessWidget {
  final VoidCallback onTap;

  const _AddMonthChip({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: colorScheme.primary,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add,
              size: 18,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              'Bulan',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final double income;
  final double expense;
  final double balance;

  const _SummaryRow({
    required this.income,
    required this.expense,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Income',
            valueText: formatter.format(income),
            valueColor: Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            label: 'Expense',
            valueText: formatter.format(expense),
            valueColor: Colors.red,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            label: 'Balance',
            valueText: formatter.format(balance),
            valueColor: balance >= 0 ? theme.colorScheme.primary : Colors.red,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String valueText;
  final Color valueColor;

  const _SummaryCard({
    required this.label,
    required this.valueText,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium,
          ),
          const SizedBox(height: 4),
          Text(
            valueText,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PersonalFinanceProvider>();
    final theme = Theme.of(context);

    final transactions = provider.transactionsForSelectedMonth;

    if (transactions.isEmpty) {
      return Center(
        child: Text(
          'Belum ada transaksi untuk bulan ini.',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        final formatter = NumberFormat.currency(
          locale: 'id_ID',
          symbol: 'Rp ',
          decimalDigits: 0,
        );
        final amountText = formatter.format(transaction.amount);
        final dateText = DateFormat('dd MMM yyyy').format(
          transaction.date,
        );
        final isIncome = transaction.type == PersonalTransactionType.income;
        final isExpense = transaction.type == PersonalTransactionType.expense;

        final Color backgroundColor;
        if (isIncome) {
          backgroundColor = Colors.green.withAlpha((0.06 * 255).round());
        } else if (isExpense) {
          backgroundColor = Colors.red.withAlpha((0.06 * 255).round());
        } else {
          backgroundColor =
              theme.colorScheme.primary.withAlpha((0.06 * 255).round());
        }

        final IconData iconData;
        switch (transaction.category.toLowerCase()) {
          case 'makanan':
            iconData = Icons.restaurant;
            break;
          case 'hutang':
            iconData = Icons.request_quote;
            break;
          case 'shopping':
            iconData = Icons.shopping_bag;
            break;
          case 'hiburan':
            iconData = Icons.movie;
            break;
          case 'pendidikan':
            iconData = Icons.school;
            break;
          case 'beauty':
            iconData = Icons.brush;
            break;
          case 'olahraga':
            iconData = Icons.fitness_center;
            break;
          case 'social':
            iconData = Icons.group;
            break;
          case 'transportasi':
            iconData = Icons.directions_car;
            break;
          case 'pakaian':
            iconData = Icons.checkroom;
            break;
          case 'kesehatan':
            iconData = Icons.local_hospital;
            break;
          case 'peliharaan':
            iconData = Icons.pets;
            break;
          case 'donation':
            iconData = Icons.volunteer_activism;
            break;
          case 'uang kejut':
            iconData = Icons.stars;
            break;
          case 'mingguan':
            iconData = Icons.calendar_view_week;
            break;
          case 'gaji':
            iconData = Icons.work;
            break;
          case 'investment':
            iconData = Icons.trending_up;
            break;
          case 'lainnya':
            iconData = Icons.more_horiz;
            break;
          case 'transfer':
            iconData = Icons.swap_horiz;
            break;
          default:
            iconData = Icons.category;
            break;
        }

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Dismissible(
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
                  .read<PersonalFinanceProvider>()
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
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.surface,
                child: Icon(
                  iconData,
                  color: theme.colorScheme.primary,
                ),
              ),
              title: Text(
                transaction.category,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                '${transaction.description ?? '-'}\n$dateText',
              ),
              isThreeLine: true,
              trailing: Text(
                isExpense ? '-$amountText' : amountText,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isIncome
                      ? Colors.green
                      : isExpense
                          ? Colors.red
                          : theme.colorScheme.primary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
