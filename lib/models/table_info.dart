class TableInfo {
  const TableInfo({
    required this.tableNo,
    this.label,
    this.gridX,
    this.gridY,
    this.hidden = false,
  });

  final String tableNo;
  final String? label;
  final int? gridX;
  final int? gridY;
  final bool hidden;

  factory TableInfo.fromJson(Map<String, dynamic> json) {
    return TableInfo(
      tableNo: json['tableNo'] as String,
      label: json['label'] as String?,
      gridX: (json['gridX'] as num?)?.toInt(),
      gridY: (json['gridY'] as num?)?.toInt(),
      hidden: json['hidden'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'tableNo': tableNo,
        if (label != null) 'label': label,
        if (gridX != null) 'gridX': gridX,
        if (gridY != null) 'gridY': gridY,
        'hidden': hidden,
      };
}
