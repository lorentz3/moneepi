import 'package:flutter/material.dart';
import 'package:myfinance2/dto/group_dto.dart';
import 'package:myfinance2/model/category.dart';
import 'package:myfinance2/pages/group_form_page.dart';
import 'package:myfinance2/services/group_entity_service.dart';

class GroupListPage extends StatefulWidget {
  final String currencySymbol;
  const GroupListPage({super.key, required this.currencySymbol});

  @override
  State<GroupListPage> createState() => _GroupListPageState();
}

class _GroupListPageState extends State<GroupListPage> {
  List<GroupDto> _groups = [];
  late String _currencySymbol;
  bool _dataChanged = false;

  @override
  void initState() {
    super.initState();
    _loadGroups();
    _currencySymbol = widget.currencySymbol;
  }

  Future<void> _loadGroups() async {
    _groups = await GroupEntityService.getGroupsWithCategories();
    setState(() {});
  }

  void _navigateToEditGroup(GroupDto group) async {
    _dataChanged = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GroupFormPage(group: group)),
    );
    if (_dataChanged == true) {
      setState(() {
        _loadGroups();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color groupBgColor = Colors.blueGrey.shade100;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          debugPrint("Popping GroupListPage _dataChanged=$_dataChanged, result=$result");
          Navigator.pop(context, _dataChanged);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Groups"),
          actions: [
            IconButton(
              onPressed: () {
                _navigateToEditGroup(GroupDto(name: "", sort: 1, categories: []));
              },
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _groups.isEmpty ? Center(child: Text("No group configured")) : SizedBox(),
            ..._groups.map((group) {
              return InkWell(
                onTap: () => _navigateToEditGroup(group),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header con data raggruppata
                    Container(
                      color: groupBgColor,
                      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
                      child: Row(
                        children: [
                          Text(
                            "${group.icon ?? ""} ${group.name}",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: 10,),
                          if (group.monthThreshold != null) Text(
                            "(Monthly budget: ${group.monthThreshold!.toStringAsFixed(2)} $_currencySymbol)",
                            style: TextStyle(fontSize: 16,),
                          ),
                        ],
                      ),
                    ),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: group.categories.length,
                      itemBuilder: (context, index) {
                        Category category = group.categories[index];
                        Color rowColor = index % 2 == 0 ? Colors.white : Colors.grey[200]!;
                        return _getCategoryWidget(context, category, rowColor);
                      },
                    ),
                  ],
                ),
              );
            }),
          ]
        ),
      ),
    );
  }

  Widget _getCategoryWidget(BuildContext context, Category category, Color rowColor) {
    String categoryTitle = "${category.icon ?? ""} ${category.name}";
    return Container(
      color: rowColor,
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "    $categoryTitle",
            textAlign: TextAlign.left,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          SizedBox(width: 30,)
        ],
      ),
    );
  }
}