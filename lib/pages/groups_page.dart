import 'package:flutter/material.dart';
import 'package:myfinance2/dto/group_dto.dart';
import 'package:myfinance2/pages/group_form_page.dart';
import 'package:myfinance2/services/group_entity_service.dart';

class GroupListPage extends StatefulWidget {
  const GroupListPage({super.key});

  @override
  State<GroupListPage> createState() => _GroupListPageState();
}

class _GroupListPageState extends State<GroupListPage> {
  List<GroupDto> groups = [];

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    groups = await GroupEntityService.getGroupsWithCategories();
    setState(() {});
  }

  void _navigateToEditGroup(GroupDto group) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GroupFormPage(group: group)),
    ).then((_) => setState(() {
      _loadGroups();
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Groups")),
      body: ListView.builder(
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: ListTile(
              title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              onTap: () => _navigateToEditGroup(group),
              trailing: const Icon(Icons.edit),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEditGroup(GroupDto(name: "", sort: 1, categories: [])),
        child: const Icon(Icons.add),
      ),
    );
  }
}