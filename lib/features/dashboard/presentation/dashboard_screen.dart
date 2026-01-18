import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/supabase/supabase_manager.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../joint_saving/providers/joint_saving_provider.dart';
import '../../personal_finance/providers/personal_finance_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final personalProvider = context.read<PersonalFinanceProvider>();
      final jointProvider = context.read<JointSavingProvider>();
      personalProvider.initialize();
      jointProvider.initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeProvider = context.watch<ThemeProvider>();
    final personalProvider = context.watch<PersonalFinanceProvider>();
    final jointProvider = context.watch<JointSavingProvider>();
    final user = SupabaseManager.client.auth.currentUser;
    final metadataName = (user?.userMetadata?['full_name'] as String?)?.trim();
    String displayName;
    if (metadataName != null && metadataName.isNotEmpty) {
      displayName = metadataName;
    } else {
      final email = user?.email ?? '';
      if (email.isNotEmpty) {
        displayName = email.split('@').first;
      } else {
        displayName = 'Pengguna';
      }
    }

    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final jointSaving = jointProvider.jointSaving;
    final jointValueText =
        jointSaving != null ? jointProvider.formattedCurrentBalance : 'Rp 0';
    final jointSubtitle = jointSaving != null
        ? 'dari ${jointProvider.formattedTargetAmount}'
        : 'Belum ada tabungan bersama';

    final balance = personalProvider.balance;
    final personalValueText = formatter.format(balance);
    const personalSubtitle = 'Total saldo keuangan pribadi';

    String motivation;
    if (balance < 0) {
      motivation =
          'Wah $displayName, keuangan kamu lagi minus. Yuk cek pengeluaran dan kurangi yang tidak penting.';
    } else if (balance == 0) {
      motivation =
          '$displayName, keuangan kamu masih seimbang. Pertahankan kontrol pengeluaranmu.';
    } else if (jointSaving != null && balance < jointSaving.targetAmount) {
      motivation =
          'Keren $displayName, kamu sudah berhasil menyisihkan uang. Sedikit lagi menuju target!';
    } else {
      motivation =
          'Luar biasa $displayName! Target tabunganmu sudah terlampaui. Saatnya merencanakan hal menyenangkan berikutnya.';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('OurFinance'),
        actions: [
          IconButton(
            onPressed: () {
              context.read<AuthProvider>().signOut();
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Halo, $displayName',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Tema:',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('White'),
                  selected:
                      themeProvider.currentThemeMode == AppThemeMode.white,
                  onSelected: (_) {
                    themeProvider.setTheme(AppThemeMode.white);
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Black'),
                  selected:
                      themeProvider.currentThemeMode == AppThemeMode.black,
                  onSelected: (_) {
                    themeProvider.setTheme(AppThemeMode.black);
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Navy'),
                  selected: themeProvider.currentThemeMode == AppThemeMode.navy,
                  onSelected: (_) {
                    themeProvider.setTheme(AppThemeMode.navy);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'Tabungan Bersama',
                    value: jointValueText,
                    subtitle: jointSubtitle,
                    primaryColor: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    title: 'Saldo Pribadi',
                    value: personalValueText,
                    subtitle: personalSubtitle,
                    primaryColor: colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _SpendingChartCard(),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analisa Keuangan',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    motivation,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color primaryColor;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: textTheme.labelMedium?.copyWith(
              color: textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _SpendingChartCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final categories = [
      _CategorySlice(label: 'Makanan', percent: 40, color: Colors.blue),
      _CategorySlice(label: 'Hiburan', percent: 20, color: Colors.purple),
      _CategorySlice(label: 'Transportasi', percent: 15, color: Colors.teal),
      _CategorySlice(label: 'Shopping', percent: 25, color: Colors.orange),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Distribusi Pengeluaran',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: categories
                          .map(
                            (category) => PieChartSectionData(
                              color: category.color,
                              value: category.percent.toDouble(),
                              title: '${category.percent}%',
                              radius: 60,
                              titleStyle: textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: ListView.separated(
                    itemCount: categories.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: category.color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              category.label,
                              style: textTheme.bodyMedium,
                            ),
                          ),
                          Text(
                            '${category.percent}%',
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySlice {
  final String label;
  final int percent;
  final Color color;

  _CategorySlice({
    required this.label,
    required this.percent,
    required this.color,
  });
}

class _JointSavingEntryScreen extends StatelessWidget {
  const _JointSavingEntryScreen();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _PersonalFinanceEntryScreen extends StatelessWidget {
  const _PersonalFinanceEntryScreen();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
