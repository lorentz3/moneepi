import 'package:flutter/material.dart';
import 'package:myfinance2/model/account.dart';
import 'package:myfinance2/model/category.dart';
import 'package:myfinance2/pages/edit_account.dart';
import 'package:myfinance2/services/account_entity_service.dart';
import 'package:myfinance2/services/category_entity_service.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

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
          title: const Text("Categories"),
          actions: [
            PopupMenuButton(
              onSelected: (value) => _handleClick(value, context),
              itemBuilder: (context) => [
                const PopupMenuItem(value: "AddDefaultAccounts", child: Text("Add default accounts")),
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
                    height: 30,
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
                                  account: elements[index],
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
              return const Text("No accounts");
            }
            return const Text("No accounts");
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
    switch(value) {
      case "AddDefaultAccounts":
        showDialog(
          context: context, 
          barrierDismissible: true,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Adding default accounts'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    const Text("This will add app default accounts to your accounts list, like:"),
                    const Text(" - Bank account"),
                    const Text(" - Cash"),
                    const Text(" - Credit card"),
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
                      AccountEntityService.insertDefaultAccounts();
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

  Future<void> _showDeleteDialog(Account account) async {
    // TODO check if categories exist for this account
    bool categoryExists = false;
    return showDialog<void>(
      context: context,
      barrierDismissible: true, 
      builder: (BuildContext context) {
        if (categoryExists) {
          return AlertDialog(
            content: const Text("The account cannot be deleted, there are Categories referencing this account.")
          );
        } else {
          return AlertDialog(
            title: const Text('Delete confirmation'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text("Delete the account '${account.name}'? You cannot revert this operation."),
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
                    AccountEntityService.deleteAccount(account.id!);
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
} 