/// 매출·통계 화면에서 쓰는 기간 선택
enum PeriodPreset {
  today,
  thisWeek,
  thisMonth,
  custom,
}

class PeriodFilter {
  const PeriodFilter({
    required this.preset,
    this.rangeStart,
    this.rangeEnd,
  });

  final PeriodPreset preset;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;

  factory PeriodFilter.fromJson(Map<String, dynamic> json) {
    final p = json['preset'] as String;
    final preset = PeriodPreset.values.firstWhere(
      (e) => e.name == p,
      orElse: () => PeriodPreset.today,
    );
    return PeriodFilter(
      preset: preset,
      rangeStart: json['rangeStart'] != null
          ? DateTime.parse(json['rangeStart'] as String)
          : null,
      rangeEnd: json['rangeEnd'] != null
          ? DateTime.parse(json['rangeEnd'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'preset': preset.name,
        if (rangeStart != null)
          'rangeStart': rangeStart!.toUtc().toIso8601String(),
        if (rangeEnd != null) 'rangeEnd': rangeEnd!.toUtc().toIso8601String(),
      };
}
