import 'package:flutter/material.dart';
import 'package:myfinance2/model/category.dart';
import 'package:myfinance2/model/category_type.dart';
import 'package:myfinance2/services/category_entity_service.dart';

class MonthlyThresholdsPage extends StatefulWidget {
  const MonthlyThresholdsPage({super.key});

  @override
  MonthlyThresholdsPageState createState() => MonthlyThresholdsPageState();
}

class MonthlyThresholdsPageState extends State<MonthlyThresholdsPage> {
  List<Category> _categories = [];
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, String> _initialValues = {};

  @override
  void initState() {
    super.initState();
    _loadCategories();
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Nasconde la tastiera quando si clicca fuori dai TextField
      },
      child: Scaffold(
        appBar: AppBar(title: Text("Budgeting")),
        body: Padding(
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
                            child: Text("Category", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text("Monthly Budget (€)", style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                          ),
                        ],
                      ),
                      // Dati
                      ..._categories.map((category) => TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 12, top: 4),
                                child: Text("${category.icon} ${category.name}"),
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
              SizedBox(height: 4),
              ElevatedButton(
                onPressed: _saveThresholds,
                child: Text("Save"),
              ),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _saveThresholds() async {
    for (Category category in _categories) {
      String actualValue = _controllers[category.id]?.text ?? "";
      if (actualValue != _initialValues[category.id]){
        category.monthThreshold = double.tryParse(_controllers[category.id]?.text ?? "");
        debugPrint("updating category ${category.id} monthThreshold: ${category.monthThreshold}");
        await CategoryEntityService.updateMonthThresholdById(category.id, category.monthThreshold);
      }
    }
    if (mounted){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Categories monthly thresholds updated")),
      );
      Navigator.pop(context);
    }
  }
}