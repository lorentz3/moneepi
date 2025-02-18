import 'package:flutter/material.dart';
import 'package:myfinance2/model/account.dart';
import 'package:myfinance2/model/category.dart';
import 'package:myfinance2/model/transaction_type.dart';
import 'package:myfinance2/pages/edit_account.dart';
import 'package:myfinance2/pages/edit_category.dart';
import 'package:myfinance2/services/account_entity_service.dart';
import 'package:myfinance2/services/category_entity_service.dart';

class CategoriesPage extends StatefulWidget {
  final TransactionType type;

  const CategoriesPage({super.key, required this.type});

  @override
  State createState() => CategoriesPageState();
}

class CategoriesPageState extends State<CategoriesPage> {
  int? _listSize = 0;

  @override
  Widget build(BuildContext context) {
    double width = 300;
    if (mounted) width = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: () {
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.unfocus();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_getTitle(widget.type)),
          actions: [
            PopupMenuButton(
              onSelected: (value) => _handleClick(value, context),
              itemBuilder: (context) => [
                const PopupMenuItem(value: "AddDefaultCategories", child: Text("Add default categories")),
              ],
            )
          ],
        ),
        body: FutureBuilder<List<Category>>(
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
                    height: 20,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 10,
                          child: Text(elements[index].name),
                        ),
                        Expanded(
                          flex: 2,
                          child: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              Navigator.push(
                                context, 
                                MaterialPageRoute(builder: (context) => EditCategoryPage(
                                  category: elements[index],
                                  isNew: false,
                                  sort: _listSize! + 1
                                  )
                                )
                              ).then((_) => setState(() {}));
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
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => EditAccountPage(
                account: Account(id: 0, name: "", balance: 0, sort: _listSize! + 1),
                isNew: true,
                sort: _listSize! + 1,
              ))
            ).then((_) => setState(() {}));
          },
          tooltip: 'Add category',
          child: const Icon(Icons.add),
        ),
      )
    );
  }

  _handleClick(String value, BuildContext context){
    // TODO by widget.type
    switch(value) {
      case "AddDefaultCategories":
        showDialog(
          context: context, 
          barrierDismissible: true,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Adding default categories'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    const Text("This will add app default categories to your categories list, like:"),
                    const Text(" - House"),
                    const Text(" - Car"),
                    const Text(" - ..."),
                    const Text("Continue?"),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(context, 'Cancel'),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  child: const Text('Continue'),
                  onPressed: () {
                    setState(() {
                      CategoryEntityService.insertDefaultCategories();
                      Navigator.pop(context);
                    });
                  },
                ),
              ],
            );
          }
        );
        break;
    }
  }

  Future<List<Category>> _getCategories() async {
    Future<List<Category>?> categories = CategoryEntityService.getAllCategories();
    List<Category>? list = await categories;
    if (list != null) {
      return list;
    }
    return [];
  }

  Future<void> _showDeleteDialog(Category category) async {
    // TODO check if expenses exist for this acategory
    bool expenseExists = false;
    return showDialog<void>(
      context: context,
      barrierDismissible: true, 
      builder: (BuildContext context) {
        if (expenseExists) {
          return AlertDialog(
            content: const Text("The account cannot be deleted, there are Categories referencing this account.")
          );
        } else {
          return AlertDialog(
            title: const Text('Delete confirmation'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text("Delete the account '${category.name}'? You cannot revert this operation."),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, 'Cancel'),
                child: const Text('Cancel'),
              ),
              TextButton(
                child: const Text('Delete account'),
                onPressed: () {
                  setState(() {
                    AccountEntityService.deleteAccount(category.id!);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Account deleted."),
                    ));
                    Navigator.pop(context);
                  });
                },
              ),
            ],
          );
        }
      },
    );
  }
  
  String _getTitle(TransactionType type) {
    switch(type) {
      case TransactionType.EXPENSE:
        return "Expense categories";
      case TransactionType.INCOME:
        return "Income categories";
    }

  }
} 