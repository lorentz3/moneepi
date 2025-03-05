import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:myfinance2/model/category.dart';
import 'package:myfinance2/model/transaction_type.dart';
import 'package:myfinance2/pages/category_form_page.dart';
import 'package:myfinance2/services/category_entity_service.dart';
import 'package:myfinance2/services/transaction_entity_service.dart';

class CategoriesPage extends StatefulWidget {
  final TransactionType type;

  const CategoriesPage({super.key, required this.type});

  @override
  State createState() => CategoriesPageState();
}

class CategoriesPageState extends State<CategoriesPage> {
  int? _listSize = 0;
  final GlobalKey<CategoriesPageState> categoriesPageKey = GlobalKey();
  bool _isFabVisible = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      if (_isFabVisible) {
        setState(() => _isFabVisible = false);
      }
    } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
      if (!_isFabVisible) {
        setState(() => _isFabVisible = true);
      }
    }
    debugPrint("_isFabVisible = $_isFabVisible");
  }
   
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = 300;
    if (mounted) width = MediaQuery.of(context).size.width;
    return Scaffold(
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
                        flex: 1,
                        child: elements[index].icon != null ? Text(elements[index].icon!) : const Text(" - "),
                      ),
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
                              MaterialPageRoute(builder: (context) => CategoryFormPage(
                                category: elements[index],
                                isNew: false,
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
      floatingActionButton: AnimatedOpacity(
        opacity: _isFabVisible ? 1.0 : 0.0,
        duration: Duration(milliseconds: 300),
        child: _isFabVisible ? FloatingActionButton (
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => CategoryFormPage(
                  category: Category(id: 0, name: "", type: widget.type, sort: _listSize! + 1),
                  isNew: true,
                ))
              ).then((_) => setState(() {}));
            },
            tooltip: 'Add category',
            child: const Icon(Icons.add),
        ) : null,
      ),
    );
  }

  _handleClick(String value, BuildContext context) {
    if (widget.type == TransactionType.EXPENSE){
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
                      const Text("This will add app default categories to your expense categories list, like:"),
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
                        CategoryEntityService.insertDefaultExpenseCategories();
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
    else if (widget.type == TransactionType.INCOME){
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
                      const Text("This will add app default categories to your income categories list, like:"),
                      const Text(" - Salary"),
                      const Text(" - Refunds"),
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
                        CategoryEntityService.insertDefaultIncomeCategories();
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
            content: const Text("The category cannot be deleted, there are Categories referencing this account.")
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