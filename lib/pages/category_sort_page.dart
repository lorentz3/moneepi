import 'package:flutter/material.dart';
import 'package:myfinance2/model/category.dart';
import 'package:myfinance2/model/category_type.dart';
import 'package:myfinance2/services/category_entity_service.dart';

class CategorySortPage extends StatefulWidget {
  final CategoryType categoryType;

  const CategorySortPage({
    super.key,
    required this.categoryType,
  });

  @override
  State<CategorySortPage> createState() => _CategorySortPageState();
}

class _CategorySortPageState extends State<CategorySortPage> {
  List<Category> _categories = [];
  bool _dataChanged = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _categories = await CategoryEntityService.getAllCategories(widget.categoryType);
    setState(() { });
  }

  void _onReorder(int oldIndex, int newIndex) {
    _dataChanged = true;
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final category = _categories.removeAt(oldIndex);
      _categories.insert(newIndex, category);

      // Aggiorna i sort dopo il riordinamento
      for (int i = 0; i < _categories.length; i++) {
        _categories[i].sort = i;
      }
    });
  }

  Future<void> _save() async {
    if (_dataChanged) {
      debugPrint("Saving categories sort");
      await CategoryEntityService.updateSort(_categories);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _save();
          debugPrint("Popping CategorySortState _dataChanged=$_dataChanged, result=$result");
          Navigator.pop(context, _dataChanged);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sort categories'),
          actions: [],
        ),
        body: ReorderableListView.builder(
          itemCount: _categories.length,
          onReorder: _onReorder,
          itemBuilder: (context, index) {
            final category = _categories[index];
            return Card(
              key: ValueKey(category.id),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                height: 40,
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: category.icon != null ? Text(
                        category.icon!,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ) : const Text(" - "),
                    ),
                    Expanded(
                      flex: 10,
                      child: Text(
                        category.name,
                        textAlign: TextAlign.left,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.unfold_more),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}