class CashEntry {
  DateTime date;
  double amount;

  CashEntry({required this.date, required this.amount});

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'amount': amount,
  };

  factory CashEntry.fromJson(Map<String, dynamic> json) => CashEntry(
    date: DateTime.parse(json['date']),
    amount: json['amount'],
  );
}

class XirrResult {
  double value;
  double finalReturn;
  DateTime timestamp;

  XirrResult({required this.value, required this.finalReturn, required this.timestamp});

  Map<String, dynamic> toJson() => {
    'value': value,
    'finalReturn': finalReturn,
    'timestamp': timestamp.toIso8601String(),
  };

  factory XirrResult.fromJson(Map<String, dynamic> json) => XirrResult(
    value: json['value'],
    finalReturn: json['finalReturn'] ?? 0,
    timestamp: DateTime.parse(json['timestamp']),
  );
}

class TabData {
  List<CashEntry> entries;
  List<XirrResult> history;
  double finalReturn;
  DateTime finalDate;

  TabData({required this.entries, required this.history, required this.finalReturn, required this.finalDate});

  Map<String, dynamic> toJson() => {
    'entries': entries.map((e) => e.toJson()).toList(),
    'history': history.map((e) => e.toJson()).toList(),
    'finalReturn': finalReturn,
    'finalDate': finalDate.toIso8601String(),
  };

  factory TabData.fromJson(Map<String, dynamic> json) => TabData(
    entries: (json['entries'] as List).map((e) => CashEntry.fromJson(e)).toList(),
    history: (json['history'] as List).map((e) => XirrResult.fromJson(e)).toList(),
    finalReturn: json['finalReturn'] ?? 0.0,
    finalDate: DateTime.parse(json['finalDate']),
  );
}