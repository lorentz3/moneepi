import 'package:flutter/material.dart';
import 'package:myfinance2/model/category.dart';
import 'package:myfinance2/model/category_type.dart';
import 'package:myfinance2/services/category_entity_service.dart';

class CategoryFormPage extends StatefulWidget {
  final Category category;
  final bool? isNew;

  const CategoryFormPage({super.key, required this.category, required this.isNew});

  @override
  State createState() => CategoryFormPageState();
}

class CategoryFormPageState extends State<CategoryFormPage> {
  final _formKey = GlobalKey<FormState>();
  String? _categoryName;
  double? _monthThreshold;
  double? _yearThreshold;
  String? _icon;
  late CategoryType _categoryType;
  bool _showAnnualBudget = false;

  @override
  void initState() {
    super.initState();
    _categoryName = widget.category.name;
    _monthThreshold = widget.category.monthThreshold;
    _yearThreshold = widget.category.yearThreshold;
    _icon = widget.category.icon;
    _categoryType = widget.category.type;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          debugPrint("Popping AccountFormPage _dataChanged=false, result=$result");
          Navigator.pop(context, false);
        }
      },
      child: GestureDetector(
        onTap: () {
          FocusScopeNode currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus) {
            currentFocus.unfocus();
          }
        },
        child: Scaffold(
          appBar: AppBar(title: widget.isNew! ? const Text("Create new category") : const Text("Edit category")),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Category symbol', hintText: 'Emoji strongly suggested'),
                    initialValue: _icon,
                    onChanged: (value) => _icon = value,
                    validator: (value) => value != null && value.length > 4 ? 'Symbol must be 1 emoji or max 2 characters' : null,
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Category name *'),
                    initialValue: _categoryName,
                    onChanged: (value) => _categoryName = value,
                    validator: (value) => value!.isEmpty ? 'Enter a name' : null,
                  ),
                  if (_categoryType == CategoryType.EXPENSE) TextFormField(
                    decoration: InputDecoration(labelText: 'Monthly Budget'),
                    initialValue: _monthThreshold != null ? "$_monthThreshold" : "",
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                      signed: false
                    ),
                    onChanged: (value) => _monthThreshold = double.tryParse(value),
                  ),
                  if (_showAnnualBudget && _categoryType == CategoryType.EXPENSE) TextFormField(
                    decoration: InputDecoration(labelText: 'Annual Budget'),
                    initialValue: _yearThreshold != null ? "$_yearThreshold" : "",
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                      signed: false
                    ),
                    onChanged: (value) => _yearThreshold = double.tryParse(value),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _saveCategory();
                      }
                    },
                    child: Text('Save'),
                  ),
                ],
              ),
            )
          )
        )
      ),
    );
  }

  _saveCategory() {
    Category category = widget.category;
    category.name = _categoryName!;
    category.monthThreshold = _monthThreshold;
    category.yearThreshold = _yearThreshold;
    category.icon = _icon;
    if(widget.isNew!){
      CategoryEntityService.insertCategory(category);
    } else {
      CategoryEntityService.updateCategory(category);
    }
    Navigator.pop(context, true);
  }
} 