// main.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'commons.dart';
import 'ui.dart';


void main() => runApp(XirrCalculatorApp());

class XirrCalculatorApp extends StatelessWidget {
  const XirrCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'XIRR Calculator',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MultiXirrHomePage(),
    );
  }
}

class MultiXirrHomePage extends StatefulWidget {
  const MultiXirrHomePage({super.key});

  @override
  MultiXirrHomePageState createState() => MultiXirrHomePageState();
}

class MultiXirrHomePageState extends State<MultiXirrHomePage> {
  List<TabData> tabsData = [];
  List<String> tabNames = [];
  int currentTabIndex = 0;
  bool isLoading = true; // Change: Add loading state

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  // CHANGE: Renamed and made it properly handle loading state
  Future<void> _initializeApp() async {
    await _loadTabs();
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _loadTabs() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // CHANGE: Clear old incompatible data format
      await prefs.remove('entries');
      await prefs.remove('history');
      await prefs.remove('finalReturn');

      String? tabJsonList = prefs.getString('multiTabs');
      List<String>? tabNameList = prefs.getStringList('multiTabNames');

      if (tabJsonList != null && tabNameList != null) {
        try {
          List list1 = jsonDecode(tabJsonList);
          tabsData = list1.map<TabData>((e) => TabData.fromJson(e)).toList();
          tabNames = tabNameList;
        } catch (e) {
          // If parsing fails, clear corrupted data and create default tab
          await prefs.remove('multiTabs');
          await prefs.remove('multiTabNames');
          tabsData = [
            TabData(entries: [],
                history: [],
                finalReturn: 0.0,
                finalDate: DateTime.now())
          ];
          tabNames = ["Main"];
        }
      } else {
        tabsData = [
          TabData(entries: [],
              history: [],
              finalReturn: 0.0,
              finalDate: DateTime.now())
        ];
        tabNames = ["Main"];
      }
    } catch (e) {
      // CHANGE: Handle any other errors and provide default state
      print('Error loading tabs: $e');
      tabsData = [TabData(entries: [], history: [], finalReturn: 0.0, finalDate: DateTime.now())];
      tabNames = ["Main"];
    }
    setState(() {});
  }

  Future<void> _saveTabs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsonTabs = jsonEncode(tabsData.map((e) => e.toJson()).toList());
    await prefs.setString('multiTabs', jsonTabs);
    await prefs.setStringList('multiTabNames', tabNames);
  }

  Future<void> _addTab() async {
    String name = await _askName();
    setState(() {
      tabsData.add(TabData(entries: [], history: [], finalReturn: 0.0, finalDate: DateTime.now()));
      tabNames.add(name);
      currentTabIndex = tabsData.length - 1;
    });
    _saveTabs();
    Navigator.of(context).pop();
  }

  Future<String> _askName() async {
    String name = "";
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Name your calculator"),
        content: TextField(onChanged: (val) => name = val),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, "Calculator"), child: Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, name), child: Text("OK")),
        ],
      ),
    ) ?? "Calculator";
  }

  Future<bool> _confirmDelete(String calculatorName) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Calculator"),
        content: Text("Are you sure you want to delete '$calculatorName'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
  }

  void _deleteTab(int index) async {
    if (tabsData.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Cannot delete the last tab")),
      );
      return;
    }

    bool confirmed = await _confirmDelete(tabNames[index]);
    if (!confirmed) return;

    setState(() {
      tabsData.removeAt(index);
      tabNames.removeAt(index);
      if (currentTabIndex >= tabsData.length) {
        currentTabIndex = tabsData.length - 1;
      }
    });
    _saveTabs();
    Navigator.of(context).pop();
  }

  void _selectCalculator(int index) {
    setState(() {
      currentTabIndex = index;
    });
    Navigator.of(context).pop(); // Close drawer
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text("XIRR Calculator")),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text("XIRR Calculator - ${tabNames[currentTabIndex]}"),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            // Drawer Header
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Container(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calculate,
                      color: Colors.white,
                      size: 48,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'XIRR Calculators',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${tabNames.length} calculator${tabNames.length > 1 ? 's' : ''}',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Calculator List
            Expanded(
              child: ListView.builder(
                itemCount: tabNames.length,
                itemBuilder: (context, index) {
                  bool isSelected = index == currentTabIndex;
                  return Container(
                    color: isSelected ? Colors.blue.withOpacity(0.1) : null,
                    child: ListTile(
                      leading: Icon(
                        Icons.calculate_outlined,
                        color: isSelected ? Colors.blue : Colors.grey[600],
                      ),
                      title: Text(
                        tabNames[index],
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.blue : null,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: Colors.blue,
                              size: 20,
                            ),
                          SizedBox(width: 8),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: Colors.red[400],
                              size: 20,
                            ),
                            onPressed: () => _deleteTab(index),
                          ),
                        ],
                      ),
                      onTap: () => _selectCalculator(index),
                    ),
                  );
                },
              ),
            ),
            // Add New Calculator Button
            Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(Icons.add),
                  label: Text('Add New Calculator'),
                  onPressed: _addTab,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: XirrHomePage(
        tabData: tabsData[currentTabIndex],
        onDataChanged: (updatedData) {
          setState(() {
            tabsData[currentTabIndex] = updatedData;
          });
          _saveTabs();
        },
      ),
    );
  }
}

