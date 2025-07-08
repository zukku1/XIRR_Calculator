import 'package:flutter/material.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'commons.dart';

class XirrHomePage extends StatefulWidget {
  final TabData tabData;
  final Function(TabData) onDataChanged;

  const XirrHomePage({super.key, required this.tabData, required this.onDataChanged});

  @override
  XirrHomePageState createState() => XirrHomePageState();
}

class XirrHomePageState extends State<XirrHomePage> {
  List<CashEntry> entries = [];
  List<XirrResult> history = [];
  double? result;
  double finalReturn = 0;
  DateTime finalDate = DateTime.now();
  final DateFormat formatter = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _loadFromTabData();
  }

  void _loadFromTabData() {
    entries = List.from(widget.tabData.entries);
    history = List.from(widget.tabData.history);
    finalReturn = widget.tabData.finalReturn;
    finalDate = widget.tabData.finalDate;
    setState(() {});
  }

  void _notifyDataChanged() {
    widget.onDataChanged(TabData(
      entries: entries,
      history: history,
      finalReturn: finalReturn,
      finalDate: finalDate,
    ));
  }

  void _addEntry() {
    setState(() {
      entries.add(CashEntry(date: DateTime.now(), amount: 0));
    });
    _notifyDataChanged();
  }

  Future<void> _pickDate(int index) async {
    DateTime initial = entries[index].date;
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        entries[index].date = picked;
      });
      _notifyDataChanged();
    }
  }

  void _updateAmount(int idx, String val) {
    setState(() {
      entries[idx].amount = -(double.tryParse(val) ?? 0);
    });
    _notifyDataChanged();
  }

  void _updateFinal(String val) {
    setState(() {
      finalReturn = double.tryParse(val) ?? 0;
    });
    _notifyDataChanged();
  }

  double xnpv(double rate) {
    DateTime d0 = entries.first.date;
    double sum = 0;
    for (var e in entries) {
      double days = e.date.difference(d0).inDays.toDouble();
      sum += e.amount / pow((1 + rate), days / 365);
    }
    double daysFinal = finalDate.difference(d0).inDays.toDouble();
    sum += finalReturn / pow((1 + rate), daysFinal / 365);
    return sum;
  }

  double computeXirr() {
    const tol = 1e-8;
    const maxIter = 100;
    double x1 = 0.1;
    for (int i = 0; i < maxIter; i++) {
      double f0 = xnpv(x1);
      double h = 1e-6;
      double f1 = xnpv(x1 + h);
      double df = (f1 - f0) / h;
      if (df == 0) break;
      double xNext = x1 - f0 / df;
      if ((xNext - x1).abs() < tol) return xNext;
      x1 = xNext;
    }
    throw Exception("XIRR did not converge");
  }

  void _calculate() {
    if (entries.isEmpty) return;
    entries.sort((a, b) => a.date.compareTo(b.date));
    try {
      double xirr = computeXirr();
      setState(() {
        result = xirr;
        history.add(XirrResult(value: xirr, finalReturn: finalReturn, timestamp: DateTime.now()));
        history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      });
      _notifyDataChanged();
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("XIRR calculation failed.")));
    }
  }

  List<FlSpot> _buildChartData() {
    final sortedHistory = [...history]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    List<FlSpot> spots = [];
    for (int i = 0; i < sortedHistory.length; i++) {
      final daysSinceStart = sortedHistory[i].timestamp.difference(sortedHistory.first.timestamp).inDays.toDouble();
      final xirrPercent = sortedHistory[i].value * 100;
      spots.add(FlSpot(daysSinceStart, xirrPercent));
    }
    return spots;
  }

  void _deleteEntry(int idx) {
    setState(() {
      entries.removeAt(idx);
    });
    _notifyDataChanged();
  }

  void _deleteHistoryItem(int index) {
    setState(() {
      history.removeAt(index);
    });
    _notifyDataChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Cash Flow Entries', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              ...entries.asMap().entries.map((e) {
                int idx = e.key;
                CashEntry entry = e.value;
                return Card(
                  elevation: 2,
                  margin: EdgeInsets.symmetric(vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _pickDate(idx),
                            child: Text(formatter.format(entry.date)),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: (entry.amount == 0)
                                ? "0.00"
                                : (-entry.amount).toStringAsFixed(2),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(prefixText: 'Rs. ', labelText: 'Amount Outflow'),
                            onChanged: (val) => _updateAmount(idx, val),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline),
                          onPressed: () => _deleteEntry(idx),
                        )
                      ],
                    ),
                  ),
                );
              }),
              SizedBox(height: 12),
              ElevatedButton.icon(
                icon: Icon(Icons.add),
                label: Text('Add Entry'),
                onPressed: _addEntry,
              ),
              SizedBox(height: 20),
              Divider(),
              SizedBox(height: 12),
              Text('Final Return', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: finalDate,
                              firstDate: entries.isNotEmpty ? entries.first.date : DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() {
                                finalDate = picked;
                              });
                              _notifyDataChanged();
                            }
                          },
                          child: Text(formatter.format(finalDate)),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          initialValue: (finalReturn == 0)
                              ? "0.00"
                              : finalReturn.toStringAsFixed(2),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(prefixText: 'Rs. ', labelText: 'Amount Inflow'),
                          onChanged: _updateFinal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _calculate,
                child: Text('Calculate XIRR'),
              ),
              if (result != null) ...[
                SizedBox(height: 20),
                Text('XIRR: ${(result! * 100).toStringAsFixed(2)}%', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text('Total Invested: ₹${(-entries.fold(0.0, (sum, e) => sum + e.amount)).toStringAsFixed(2)}'),
              ],
              if (history.isNotEmpty) ...[
                SizedBox(height: 30),
                Text('Calculation History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ...history.asMap().entries.map((e) => ListTile(
                  leading: Icon(Icons.history),
                  title: Text('XIRR: ${(e.value.value * 100).toStringAsFixed(2)}%'),
                  subtitle: Text('Return: Rs. ${e.value.finalReturn}\n${formatter.format(e.value.timestamp)}'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _deleteHistoryItem(e.key),
                  ),
                )),
              ],
              if (history.length > 1) ...[
                SizedBox(height: 30),
                Text('XIRR Trend', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      minY: 0,
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 10,
                            getTitlesWidget: (value, meta) => Text('${value.toInt()}d'),
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 5,
                            getTitlesWidget: (value, meta) => Text('${value.toInt()}%'),
                          ),
                        ),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          isCurved: true,
                          spots: _buildChartData(),
                          barWidth: 2,
                          color: Colors.blue,
                          dotData: FlDotData(show: true),
                        )
                      ],
                    ),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
