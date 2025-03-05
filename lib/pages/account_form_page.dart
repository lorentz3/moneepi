import 'package:flutter/material.dart';
import 'package:myfinance2/model/account.dart';
import 'package:myfinance2/services/account_entity_service.dart';

class AccountFormPage extends StatefulWidget {
  final Account account;
  final bool? isNew;

  const AccountFormPage({super.key, required this.account, required this.isNew});


  @override
  State createState() => AccountFormPageState();
}

class AccountFormPageState extends State<AccountFormPage> {
  final _formKey = GlobalKey<FormState>();
  String? _accountName;
  String? _icon;

  @override
  void initState() {
    super.initState();
    _accountName = widget.account.name;
    _icon = widget.account.icon;
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
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child:
            Column(
              children: [
                TextFormField(
                  decoration: InputDecoration(labelText: 'Account symbol', hintText: 'Emoji strongly suggested'),
                  initialValue: _icon,
                  onChanged: (value) => _icon = value,
                  validator: (value) => value != null && value.length > 2 ? 'Symbol must be 1 emoji or max 2 characters' : null,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Account name'),
                  initialValue: _accountName,
                  onChanged: (value) => _accountName = value,
                  validator: (value) => value!.isEmpty ? 'Enter a name' : null,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _saveAccount();
                    }
                  },
                  child: Text('Save'),
                ),
              ],
            ),
          ),
        ),
      )
    );
  }

  _saveAccount() {
    Account account = widget.account;
    account.name = _accountName!;
    account.icon = _icon;
    if (widget.isNew!) {
      AccountEntityService.insertAccount(account);
    } else {
      AccountEntityService.updateAccount(account);
    }
    Navigator.pop(context);
  }
} 