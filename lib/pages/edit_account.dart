import 'package:flutter/material.dart';
import 'package:myfinance2/model/account.dart';
import 'package:myfinance2/services/account_entity_service.dart';

class EditAccountPage extends StatefulWidget {
  final Account account;
  final bool? isNew;
  final int sort;

  const EditAccountPage({super.key, required this.account, required this.isNew, required this.sort});


  @override
  State createState() => EditAccountPageState();
}

class EditAccountPageState extends State<EditAccountPage> {
  String? _accountName;

  TextEditingController nameController = TextEditingController();  

  @override
  void initState() {
    super.initState();
    _accountName = widget.account.name;
    nameController.text = widget.account.name;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.unfocus();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: widget.isNew! ? const Text("Create new account") : const Text("Edit account")),
        body: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(20),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Account name'
                ),
                controller: nameController,
                keyboardType: TextInputType.text,
                onChanged: (value) {
                  setState(() {
                    if(value != ''){
                      _accountName = value;
                    } else {
                      _accountName = null;
                    }
                  });
                },
              ),
            ),
            ElevatedButton(
              onPressed: _accountName != null && _accountName != '' ? _saveAccount : null,
              child: const Text('Save'),
            ),
          ],
        ),
      )
    );
  }

  _saveAccount() {
    Account account = widget.account;
    account.name = _accountName!;
    account.sort = widget.sort;
    if(widget.isNew!){
      AccountEntityService.insertAccount(account);
    } else {
      AccountEntityService.updateAccount(account); // TODO
    }
    Navigator.pop(context);
  }
} 