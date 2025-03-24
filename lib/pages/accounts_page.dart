import 'package:flutter/material.dart';
import 'package:myfinance2/model/account.dart';
import 'package:myfinance2/pages/account_form_page.dart';
import 'package:myfinance2/services/account_entity_service.dart';
import 'package:myfinance2/services/transaction_entity_service.dart';

class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

  @override
  State createState() => AccountsPageState();
}

class AccountsPageState extends State<AccountsPage> {
  int? _listSize = 0;

  @override
  Widget build(BuildContext context) {
    double width = 300;
    if (mounted) width = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: () {
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.unfocus();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Accounts"),
          actions: [
            PopupMenuButton(
              onSelected: (value) => _handleClick(value, context),
              itemBuilder: (context) => [
                const PopupMenuItem(value: "AddDefaultAccounts", child: Text("Add default accounts")),
              ],
            )
          ],
        ),
        body: FutureBuilder<List<Account>>(
          future: _getAccounts(), 
          builder: (BuildContext context, AsyncSnapshot<List<Account>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString()));
            } else if (snapshot.hasData) {
              if (snapshot.data != null) {
                List<Account> elements = snapshot.data!;
                _listSize = elements.length;
                if (_listSize == 0) {
                  return const Text("  No accounts configured: tap '+', or add defaults");
                }
                return ListView.builder(
                  itemCount: elements.length,
                  itemBuilder: (context, index) => Container(
                    width: width,
                    margin: const EdgeInsets.all(10),
                    height: 30,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: elements[index].icon != null ? Text(
                            elements[index].icon!,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ) : const Text(" - "),
                        ),
                        Expanded(
                          flex: 10,
                          child: Text(
                            elements[index].name,
                            textAlign: TextAlign.left,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              Navigator.push(
                                context, 
                                MaterialPageRoute(builder: (context) => AccountFormPage(
                                  account: elements[index],
                                  isNew: false,
                                  )
                                )
                              ).then((_) => setState(() {}));
                            },
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              _showDeleteDialog(elements[index]);
                            },
                          ),
                        ),
                      ],
                    )
                  )
                );
              }
              return const Text("No accounts");
            }
            return const Text("No accounts");
          }
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => AccountFormPage(
                account: Account(id: 0, name: "", initialBalance: 0, sort: 0),
                isNew: true,
              ))
            ).then((_) => setState(() {}));
          },
          tooltip: 'Add account',
          child: const Icon(Icons.add),
        ),
      )
    );
  }

  _handleClick(String value, BuildContext context){
    switch(value) {
      case "AddDefaultAccounts":
        showDialog(
          context: context, 
          barrierDismissible: true,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Adding default accounts'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    const Text("This will add app default accounts to your accounts list, like:"),
                    const Text(" - Bank account"),
                    const Text(" - Cash"),
                    const Text("Continue?"),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(context, 'Cancel'),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  child: const Text('Continue'),
                  onPressed: () {
                    setState(() {
                      AccountEntityService.insertDefaultAccounts();
                      Navigator.pop(context);
                    });
                  },
                ),
              ],
            );
          }
        );
        break;
    }
  }

  Future<List<Account>> _getAccounts() async {
    Future<List<Account>?> accounts = AccountEntityService.getAllAccounts();
    List<Account>? list = await accounts;
    if(list != null){
      return list;
    }
    return [];
  }

  Future<void> _showDeleteDialog(Account account) async {
    bool transactionExists = await TransactionEntityService.transactionExistsByAccountId(account.id!);
    return showDialog<void>(
      context: context,
      barrierDismissible: true, 
      builder: (BuildContext context) {
        if (transactionExists) {
          return AlertDialog(
            content: const Text("The account cannot be deleted, there are Transactions referencing this account.")
          );
        } else {
          return AlertDialog(
            title: const Text('Delete confirmation'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text("Delete the account '${account.name}'? You cannot revert this operation."),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, 'Cancel'),
                child: const Text('Cancel'),
              ),
              TextButton(
                child: const Text('Delete account'),
                onPressed: () {
                  setState(() {
                    AccountEntityService.deleteAccount(account.id!);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Account deleted."),
                    ));
                    Navigator.pop(context);
                  });
                },
              ),
            ],
          );
        }
      },
    );
  }
} 