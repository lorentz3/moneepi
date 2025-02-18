import 'package:flutter/material.dart';
import 'package:myfinance2/model/category.dart';
import 'package:myfinance2/services/category_entity_service.dart';

class EditCategoryPage extends StatefulWidget {
  final Category category;
  final bool? isNew;
  final int sort;

  const EditCategoryPage({super.key, required this.category, required this.isNew, required this.sort});


  @override
  State createState() => EditCategoryPageState();
}

class EditCategoryPageState extends State<EditCategoryPage> {
  String? _categoryName;

  TextEditingController nameController = TextEditingController();  

  @override
  void initState() {
    super.initState();
    _categoryName = widget.category.name;
    nameController.text = widget.category.name;
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
        body: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(20),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Category name'
                ),
                controller: nameController,
                keyboardType: TextInputType.text,
                onChanged: (value) {
                  setState(() {
                    if(value != ''){
                      _categoryName = value;
                    } else {
                      _categoryName = null;
                    }
                  });
                },
              ),
            ),
            /*Row(
              children: [
                const Text("Monthly threshold"),
                TextField(
                  keyboardType: TextInputType.number,
                )
              ],
            ),
            Row(
              children: [
                const Text("Annual threshold"),
                TextField(
                  keyboardType: TextInputType.number,
                )
              ],
            ),*/
            ElevatedButton(
              onPressed: _categoryName != null && _categoryName != '' ? _saveCategory : null,
              child: const Text('Save'),
            ),
          ],
        ),
      )
    );
  }

  _saveCategory() {
    Category category = widget.category;
    category.name = _categoryName!;
    category.sort = widget.sort;
    if(widget.isNew!){
      CategoryEntityService.insertCategory(category);
    } else {
      CategoryEntityService.updateCategory(category);
    }
    Navigator.pop(context);
  }
} 