import 'package:flutter/material.dart';
import 'package:myfinance2/model/category.dart';
import 'package:myfinance2/model/category_type.dart';
import 'package:myfinance2/pages/category_form_page.dart';
import 'package:myfinance2/pages/category_sort_page.dart';
import 'package:myfinance2/services/category_entity_service.dart';
import 'package:myfinance2/services/transaction_entity_service.dart';

class CategoriesPage extends StatefulWidget {
  final CategoryType type;

  const CategoriesPage({super.key, required this.type});

  @override
  State createState() => CategoriesPageState();
}

class CategoriesPageState extends State<CategoriesPage> {
  int? _listSize = 0;
  final GlobalKey<CategoriesPageState> categoriesPageKey = GlobalKey();
  bool _dataChanged = false;

  @override
  Widget build(BuildContext context) {
    double width = 300;
    if (mounted) width = MediaQuery.of(context).size.width;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          debugPrint("Popping CategoriesPageState _dataChanged=$_dataChanged, result=$result");
          Navigator.pop(context, _dataChanged);
        }
      },
      child: Scaffold(
          appBar: AppBar(
            title: Text(_getTitle(widget.type)),
            actions: [
              IconButton(
                onPressed: () async {
                  _dataChanged = await Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => CategoryFormPage(
                      category: Category(id: 0, name: "", type: widget.type, sort: _listSize! + 1),
                      isNew: true,
                    ))
                  );
                  if (_dataChanged == true) {
                    setState(() {});
                  }
                },
                tooltip: 'Add category',
                icon: const Icon(Icons.add),
              ),
              IconButton(
                onPressed: () async {
                  _dataChanged = await Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => CategorySortPage(
                      categoryType: widget.type,
                    ))
                  );
                  if (_dataChanged == true) {
                    setState(() {});
                  }
                },
                tooltip: 'Sort categories',
                icon: const Icon(Icons.sort),
              ),
            ],
          ),
          body: SafeArea(child: FutureBuilder<List<Category>>(
            future: _getCategories(), 
            builder: (BuildContext context, AsyncSnapshot<List<Category>> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text(snapshot.error.toString()));
              } else if (snapshot.hasData) {
                if (snapshot.data != null) {
                  List<Category> elements = snapshot.data!;
                  _listSize = elements.length;
                  if (_listSize == 0) {
                    return const Text("  No categories configured: tap '+', or add defaults");
                  }
                  return ListView.builder(
                    itemCount: elements.length,
                    itemBuilder: (context, index) => Container(
                      width: width,
                      margin: const EdgeInsets.all(10),
                      height: 25,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: elements[index].icon != null ? Text(
                              elements[index].icon!,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ) : const Text(" - "),
                          ),
                          Expanded(
                            flex: 10,
                            child: Text(
                              elements[index].name,
                              textAlign: TextAlign.left,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () async {
                                _dataChanged = await Navigator.push(
                                  context, 
                                  MaterialPageRoute(builder: (context) => CategoryFormPage(
                                    category: elements[index],
                                    isNew: false,
                                    )
                                  )
                                );
                                if (_dataChanged == true) {
                                  setState(() {});
                                }
                              },
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                _showDeleteDialog(elements[index]);
                              },
                            ),
                          ),
                        ],
                      )
                    )
                  );
                }
                return const Text("No categories");
              }
              return const Text("No categories");
            }
          ),
        ),
      ),
    );
  }


  Future<List<Category>> _getCategories() async {
    Future<List<Category>?> categories = CategoryEntityService.getAllCategories(widget.type);
    List<Category>? list = await categories;
    if (list != null) {
      return list;
    }
    return [];
  }

  Future<void> _showDeleteDialog(Category category) async {
    bool transactionExists = await TransactionEntityService.transactionExistsByCategoryId(category.id!);
    return showDialog<void>(
      context: context,
      barrierDismissible: true, 
      builder: (BuildContext context) {
        if (transactionExists) {
          return AlertDialog(
            content: const Text("The category cannot be deleted, there are Transactions referencing this category.")
          );
        } else {
          return AlertDialog(
            title: const Text('Delete confirmation'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text("Delete the category '${category.name}'? You cannot revert this operation."),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, 'Cancel'),
                child: const Text('Cancel'),
              ),
              TextButton(
                child: const Text('Delete category'),
                onPressed: () {
                  setState(() {
                    CategoryEntityService.deleteCategory(category.id!);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Category deleted."),
                    ));
                    _dataChanged = true;
                    Navigator.pop(context, true);
                  });
                },
              ),
            ],
          );
        }
      },
    );
  }
  
  String _getTitle(CategoryType type) {
    switch(type) {
      case CategoryType.EXPENSE:
        return "Expense categories";
      case CategoryType.INCOME:
        return "Income categories";
    }

  }
} 