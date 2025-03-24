import 'package:flutter/material.dart';
import 'package:myfinance2/dto/group_dto.dart';

class GroupFormPage extends StatefulWidget {
  final GroupDto? group;
  const GroupFormPage({super.key, this.group});

  @override
  State<GroupFormPage> createState() => _GroupFormPageState();
}

class _GroupFormPageState extends State<GroupFormPage> {
  late TextEditingController _nameController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.group != null;
    _nameController = TextEditingController(text: widget.group?.name ?? "");
  }

  void _saveGroup() {
    if (_nameController.text.isEmpty) return;

    final newGroup = GroupDto(
      id: widget.group?.id ?? DateTime.now().millisecondsSinceEpoch, // Simula un ID
      name: _nameController.text,
      sort: widget.group?.sort ?? 0,
      categories: widget.group?.categories ?? [],
    );

    Navigator.pop(context, newGroup);
  }

  void _deleteGroup() {
    if (widget.group != null) {
      Navigator.pop(context, widget.group!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? "Modifica Gruppo" : "Nuovo Gruppo")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Nome Gruppo"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveGroup,
              child: Text(_isEditing ? "Salva Modifiche" : "Crea Gruppo"),
            ),
            if (_isEditing)
              TextButton(
                onPressed: _deleteGroup,
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text("Elimina Gruppo"),
              ),
          ],
        ),
      ),
    );
  }
}
