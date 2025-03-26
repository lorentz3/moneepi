import 'package:flutter/material.dart';
import 'package:myfinance2/dto/group_dto.dart';
import 'package:myfinance2/model/category.dart';
import 'package:myfinance2/model/category_type.dart';
import 'package:myfinance2/model/group.dart';
import 'package:myfinance2/services/category_entity_service.dart';
import 'package:myfinance2/services/group_entity_service.dart';
import 'package:myfinance2/widgets/emoji_button.dart';

class GroupFormPage extends StatefulWidget {
  final GroupDto group;

  const GroupFormPage({super.key, required this.group});

  @override
  State<GroupFormPage> createState() => _GroupFormPageState();
}

class _GroupFormPageState extends State<GroupFormPage> {
  final _formKey = GlobalKey<FormState>();
  String? _groupName;
  String? _icon;
  bool _isNew = false;
  List<Category> _categories = [];
  bool _isLoading = true;
  List<int> _selectedCategories = [];
  final Color? _selectedButtonColor = Colors.deepPurple[200]; 
  final Color? _notSelectedButtonColor = Colors.grey[50];

  @override
  void initState() {
    super.initState();
    _groupName = widget.group.name;
    _icon = widget.group.icon;
    _selectedCategories = widget.group.categories.map((c) => c.id!).toList();
    _isNew = widget.group.id == null;
    _loadCategories();
  }
  
  Future<void> _loadCategories() async {
    _categories = await CategoryEntityService.getAllCategories(CategoryType.EXPENSE);
    _isLoading = false;
    setState(() { });
  }

  @override
  Widget build(BuildContext context) {
    final double padding = 16.0;
    int buttonsPerRow = 6;
    double spaceBetweenButtons = 6;
    double screenWidth = MediaQuery.of(context).size.width;
    double buttonSize = (screenWidth - (buttonsPerRow * spaceBetweenButtons) - padding - 10) / buttonsPerRow;
    return Scaffold(
      appBar: AppBar(
        title: _isNew ? const Text("Create new group") : const Text("Edit group"),
        actions: [
          if (!_isNew) IconButton(
            icon: Icon(Icons.delete_forever),
            onPressed: () {
              _showDeleteDialog();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Group symbol', hintText: 'Emoji strongly suggested'),
                initialValue: _icon,
                onChanged: (value) => _icon = value,
                validator: (value) => value != null && value.length > 4 ? 'Symbol must be 1 emoji or max 2 characters' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Group name *'),
                initialValue: _groupName,
                onChanged: (value) => _groupName = value,
                validator: (value) => value!.isEmpty ? 'Enter a name' : null,
              ),
              const SizedBox(height: 20),
              
              SizedBox(height: spaceBetweenButtons,),
              !_isLoading ? Align(
                alignment: Alignment.center,
                child: Wrap(
                  spacing: spaceBetweenButtons,
                  runSpacing: spaceBetweenButtons,
                  children: _categories.map((category) {
                    bool isSelected = _selectedCategories.contains(category.id);
                    return EmojiButton(
                      icon: category.icon ?? category.name.substring(0, 2),
                      label: category.name,
                      width: buttonSize,
                      height: buttonSize,
                      onPressed: () {
                        setState(() {
                          if (isSelected) {
                            _selectedCategories.remove(category.id);
                          } else {
                            _selectedCategories.add(category.id!);
                          }
                        });
                      },
                      backgroundColor: _selectedCategories.contains(category.id)
                            ? _selectedButtonColor // Selected
                            : _notSelectedButtonColor,
                    );
                  }).toList(),
                ),
              ) : SizedBox(height: 1,),
              SizedBox(height: 20,),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _saveGroup();
                  }
                },
                child: Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveGroup() async {
    Group group = Group.fromDto(widget.group);
    group.name = _groupName!;
    group.icon = _icon;
    int? groupId = group.id;
    if (_isNew) {
      groupId = await GroupEntityService.insertGroup(group);
    } else {
      await GroupEntityService.updateGroup(group);
    }
    await GroupEntityService.updateGroupCategoriesLinks(groupId!, _selectedCategories);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  _showDeleteDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true, 
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete confirmation'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text("Delete the group '$_groupName'? You cannot revert this operation."),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, 'Cancel'),
              child: const Text('Cancel'),
            ),
            TextButton(
              child: const Text('Delete group'),
              onPressed: () {
                setState(() {
                  GroupEntityService.deleteGroup(widget.group.id!);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Group deleted."),
                  ));
                  Navigator.pop(context);
                });
              },
            ),
          ],
        );
      }
    );
  }
}
