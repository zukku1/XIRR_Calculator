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

class MultiXirrHomePageState extends State<MultiXirrHomePage> with TickerProviderStateMixin {
  List<TabData> tabsData = [];
  List<String> tabNames = [];
  TabController? _tabController;
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
      _tabController = TabController(length: tabsData.length, vsync: this);
    } catch (e) {
      // CHANGE: Handle any other errors and provide default state
      print('Error loading tabs: $e');
      tabsData = [TabData(entries: [], history: [], finalReturn: 0.0, finalDate: DateTime.now())];
      tabNames = ["Main"];
      _tabController = TabController(length: 1, vsync: this);
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
      _tabController?.dispose();        //Dispose old controller before creating new one
      _tabController = TabController(length: tabsData.length, vsync: this);
      _tabController!.index = currentTabIndex;
    });
    _saveTabs();
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

  void _deleteTab(int index) async {
    if (tabsData.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Cannot delete the last tab")),
      );
      return;
    }

    setState(() {
      tabsData.removeAt(index);
      tabNames.removeAt(index);
      if (currentTabIndex >= tabsData.length) {
        currentTabIndex = tabsData.length - 1;
      }
      _tabController?.dispose();
      _tabController = TabController(length: tabsData.length, vsync: this);
      _tabController!.index = currentTabIndex;
    });
    _saveTabs();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
        return Scaffold(
          appBar: AppBar(title: Text("XIRR Calculator")),
          body: Center(child: CircularProgressIndicator())
        );
    }

    return DefaultTabController(
      length: tabsData.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text("XIRR Calculator"),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: [
              for (int i = 0; i < tabNames.length; i++)
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(tabNames[i]),
                      SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _deleteTab(i),
                        child: Icon(Icons.close, size: 14),
                      )
                    ],
                  ),
                )
            ],
            onTap: (i) => setState(() => currentTabIndex = i),
          ),
          actions: [IconButton(icon: Icon(Icons.add), onPressed: _addTab)],
        ),
        body: TabBarView(
          controller: _tabController,
          children: tabsData.asMap().entries.map((entry) {
            int index = entry.key;
            TabData data = entry.value;
            return XirrHomePage(
              tabData: data,
              onDataChanged: (updatedData) {
                setState(() {
                  tabsData[index] = updatedData;
                });
                _saveTabs();
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

