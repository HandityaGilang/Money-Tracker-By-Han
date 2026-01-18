class PersonalMonth {
  final String id;
  final int year;
  final int month;

  PersonalMonth({
    required this.id,
    required this.year,
    required this.month,
  });

  String get label {
    const monthNames = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final name = monthNames[month - 1];
    return '$name $year';
  }
}

