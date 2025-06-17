import 'package:flutter/material.dart';
import 'package:myfinance2/model/account.dart';
import 'package:myfinance2/services/account_entity_service.dart';
import 'package:myfinance2/utils/color_identity.dart';

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
  String? _initialBalance;
  String? _icon;
  bool _dataChanged = false;

  @override
  void initState() {
    super.initState();
    _accountName = widget.account.name;
    _icon = widget.account.icon;
    _initialBalance = "${widget.account.initialBalance}";
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          debugPrint("Popping AccountFormPage _dataChanged=false, result=$result");
          Navigator.pop(context, _dataChanged);
        }
      },
      child: GestureDetector(
        onTap: () {
          FocusScopeNode currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus) {
            currentFocus.unfocus();
          }
        },
        child: SafeArea(
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
                      validator: (value) => value != null && value.length > 4 ? 'Symbol must be 1 emoji or max 2 characters' : null,
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Account name *'),
                      initialValue: _accountName,
                      onChanged: (value) => _accountName = value,
                      validator: (value) => value!.isEmpty ? 'Enter a name' : null,
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Initial balance', hintText: 'Account value before every transaction'),
                      initialValue: _initialBalance,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true
                      ),
                      onChanged: (value) => _initialBalance = value,
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
          ),
        )
      ),
    );
  }

  _saveAccount() async {
    Account account = widget.account;
    account.name = _accountName!;
    account.icon = _icon;
    account.initialBalance = double.tryParse(_initialBalance ?? "0") ?? 0;
    if (widget.isNew!) {
      if (await AccountEntityService.existsAccountByName(_accountName!)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Account name '$_accountName' already used!"),
            backgroundColor: red(),
          ));
        }
        return;
      }
      AccountEntityService.insertAccount(account);
    } else {
      AccountEntityService.updateAccount(account);
    }
    _dataChanged = true;
    Navigator.pop(context, true);
  }
} 