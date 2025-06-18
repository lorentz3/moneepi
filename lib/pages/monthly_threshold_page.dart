import 'package:flutter/material.dart';
import 'package:myfinance2/model/category.dart';
import 'package:myfinance2/model/category_type.dart';
import 'package:myfinance2/model/group.dart';
import 'package:myfinance2/services/category_entity_service.dart';
import 'package:myfinance2/services/clean_service.dart';
import 'package:myfinance2/services/group_entity_service.dart';
import 'package:myfinance2/utils/color_identity.dart';

class MonthlyThresholdsPage extends StatefulWidget {
  final String currencySymbol;
  const MonthlyThresholdsPage({super.key, required this.currencySymbol});

  @override
  MonthlyThresholdsPageState createState() => MonthlyThresholdsPageState();
}

class MonthlyThresholdsPageState extends State<MonthlyThresholdsPage> {
  List<Category> _categories = [];
  List<Group> _groups = [];
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, TextEditingController> _groupControllers = {};
  final Map<int, String> _initialValues = {};
  final Map<int, String> _initialGroupValues = {};
  late String _currencySymbol;

  @override
  void initState() {
    super.initState();
    _clean();
    _loadCategories();
    _loadGroups();
    _currencySymbol = widget.currencySymbol;
  }

  Future<void> _clean() async {
    await CleanService.cleanTablesFromDeletedObjects();
  }
  
  Future<void> _loadCategories() async {
    _categories = await CategoryEntityService.getAllCategories(CategoryType.EXPENSE);
    for (var category in _categories) {
      _controllers[category.id!] = TextEditingController(
        text: category.monthThreshold?.toStringAsFixed(2) ?? "",
      );
      _initialValues[category.id!] = "${category.monthThreshold ?? ""}";
    }
    setState(() { });
  }
    
  Future<void> _loadGroups() async {
    _groups = await GroupEntityService.getAllGroups();
    for (var group in _groups) {
      _groupControllers[group.id!] = TextEditingController(
        text: group.monthThreshold?.toStringAsFixed(2) ?? "",
      );
      _initialGroupValues[group.id!] = "${group.monthThreshold ?? ""}";
    }
    setState(() { });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          debugPrint("Popping MonthlyThresholdsPage _dataChanged=false, result=$result");
          Navigator.pop(context, false);
        }
      },
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus(); // Nasconde la tastiera quando si clicca fuori dai TextField
        },
        child: Scaffold(
            appBar: AppBar(title: Text("Budgeting")),
            body: SafeArea(child: Padding(
              padding: const EdgeInsets.all(0),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Table(
                        columnWidths: {
                          0: FlexColumnWidth(2), // Categoria
                          1: FlexColumnWidth(1), // Threshold
                        },
                        children: [
                          // Intestazione tabella
                          TableRow(
                            decoration: BoxDecoration(color: Colors.grey.shade200),
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 12, top: 8),
                                child: Text(_groups.isEmpty ? "Category" : "Group or Category", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text("Monthly Budget ($_currencySymbol)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                              ),
                            ],
                          ),
                          // Gruppi
                          ..._groups.map((group) => TableRow(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 12, top: 4),
                                    child: Text(
                                      "${group.icon ?? ""} ${group.name}",
                                      textAlign: TextAlign.left,
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: blue()),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: SizedBox(
                                      height: 30,
                                      child: TextField(
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.right,
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                        ),
                                        controller: _groupControllers[group.id],
                                        onChanged: (value) {
                                          group.monthThreshold = double.tryParse(value) ?? group.monthThreshold;
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              )),
                          // Categorie
                          ..._categories.map((category) => TableRow(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 12, top: 4),
                                    child: Text(
                                      "${category.icon ?? ""} ${category.name}",
                                      textAlign: TextAlign.left,
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: SizedBox(
                                      height: 30,
                                      child: TextField(
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.right,
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                        ),
                                        controller: _controllers[category.id],
                                        onChanged: (value) {
                                          category.monthThreshold = double.tryParse(value) ?? category.monthThreshold;
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              )),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ),
            bottomNavigationBar: _buildSaveButton(),
          ),
        ),
    );
  }
  
  Widget _buildSaveButton() {
    return Padding(
      padding: EdgeInsets.only(left: 60, right: 60, bottom: 10, top: 10),
      child: ElevatedButton(
        onPressed: () {
          _saveThresholds();
        },
        child: Text(
          'Save',
          style: TextStyle(
            fontSize: 20,
          ),
        ),
      ),
    );
  }

  void _saveThresholds() async {
    for (Category category in _categories) {
      final text = _controllers[category.id]?.text ?? "";
      final value = double.tryParse(text);
      if (value != null && value < 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Negative values are not allowed."),
              backgroundColor: red(),
            ),
          );
        }
        return;
      }
    }
    for (Group group in _groups) {
      final text = _groupControllers[group.id]?.text ?? "";
      final value = double.tryParse(text);
      if (value != null && value < 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Negative values are not allowed."),
              backgroundColor: red(),
            ),
          );
        }
        return;
      }
    }

    for (Category category in _categories) {
      String actualValue = _controllers[category.id]?.text ?? "";
      if (actualValue != _initialValues[category.id]){
        category.monthThreshold = double.tryParse(_controllers[category.id]?.text ?? "");
        debugPrint("updating category ${category.id} monthThreshold: ${category.monthThreshold}");
        await CategoryEntityService.updateMonthThresholdById(category.id, category.monthThreshold);
      }
    }
    for (Group group in _groups) {
      String actualValue = _groupControllers[group.id]?.text ?? "";
      if (actualValue != _initialGroupValues[group.id]){
        group.monthThreshold = double.tryParse(_groupControllers[group.id]?.text ?? "");
        debugPrint("updating group ${group.id} monthThreshold: ${group.monthThreshold}");
        await GroupEntityService.updateMonthThresholdById(group.id, group.monthThreshold);
      }
    }
    if (mounted){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Monthly thresholds updated")),
      );
      Navigator.pop(context, true);
    }
  }
}