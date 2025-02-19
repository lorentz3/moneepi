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

  @override
  void initState() {
    super.initState();
    _accountName = widget.account.name;
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
    if(widget.isNew!){
      AccountEntityService.insertAccount(account);
    } else {
      AccountEntityService.updateAccount(account); // TODO
    }
    Navigator.pop(context);
  }
} 