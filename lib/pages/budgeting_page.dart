import 'package:flutter/material.dart';
import 'package:myfinance2/model/category.dart';
import 'package:myfinance2/model/transaction_type.dart';
import 'package:myfinance2/services/category_entity_service.dart';

class BudgetingPage extends StatefulWidget {
  const BudgetingPage({super.key});

  @override
  BudgetingPageState createState() => BudgetingPageState();
}

class BudgetingPageState extends State<BudgetingPage> {
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }
  
  Future<void> _loadCategories() async {
    _categories = await CategoryEntityService.getAllCategories(TransactionType.EXPENSE);
    setState(() { });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Budgeting")),
      body: ListView.builder(
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return ListTile(
            leading: Text(
              category.icon ?? "🔘",
              style: TextStyle(fontSize: 24),
            ),
            title: Text(category.name, style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: SizedBox(
              width: 100,
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                ),
                controller: TextEditingController(text: category.monthThreshold?.toStringAsFixed(2) ?? ""),
                onSubmitted: (value) {
                  setState(() {
                    category.monthThreshold = double.tryParse(value) ?? category.monthThreshold;
                  });
                },
              ),
            ),
          );
        },
      ),
    );
  }
}