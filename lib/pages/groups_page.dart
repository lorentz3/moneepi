import 'package:flutter/material.dart';
import 'package:myfinance2/dto/group_dto.dart';
import 'package:myfinance2/pages/group_form_page.dart';
import 'package:myfinance2/services/group_entity_service.dart';

class GroupListPage extends StatefulWidget {
  const GroupListPage({Key? key}) : super(key: key);

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

  void _navigateToEditGroup([GroupDto? group]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GroupFormPage(group: group)),
    );

    if (result != null) {
      setState(() {
        if (result is GroupDto) {
          if (group != null) {
            // Modifica gruppo esistente
            int index = groups.indexWhere((g) => g.id == group.id);
            if (index != -1) groups[index] = result;
          } else {
            // Nuovo gruppo
            groups.add(result);
          }
        } else if (result is int) {
          // Eliminazione gruppo
          groups.removeWhere((g) => g.id == result);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gruppi e Categorie")),
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
        onPressed: () => _navigateToEditGroup(),
        child: const Icon(Icons.add),
      ),
    );
  }
}