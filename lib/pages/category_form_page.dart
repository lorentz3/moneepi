import 'package:flutter/material.dart';
import 'package:myfinance2/model/category.dart';
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

  @override
  void initState() {
    super.initState();
    _categoryName = widget.category.name;
    _monthThreshold = widget.category.monthThreshold;
    _yearThreshold = widget.category.yearThreshold;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
                  decoration: InputDecoration(labelText: 'Category name'),
                  initialValue: _categoryName,
                  onChanged: (value) => _categoryName = value,
                  validator: (value) => value!.isEmpty ? 'Enter a name' : null,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Monthly Threshold'),
                  initialValue: _monthThreshold != null ? "$_monthThreshold" : "",
                  keyboardType: TextInputType.numberWithOptions(
                    decimal: true,
                    signed: false
                  ),
                  onChanged: (value) => _monthThreshold = double.tryParse(value),
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Annual Threshold'),
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
    );
  }

  _saveCategory() {
    Category category = widget.category;
    category.name = _categoryName!;
    category.monthThreshold = _monthThreshold;
    category.yearThreshold = _yearThreshold;
    if(widget.isNew!){
      CategoryEntityService.insertCategory(category);
    } else {
      CategoryEntityService.updateCategory(category);
    }
    Navigator.pop(context);
  }
} 