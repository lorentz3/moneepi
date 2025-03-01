import 'package:flutter/material.dart';
import 'package:myfinance2/model/transaction_type.dart';
import 'package:myfinance2/pages/accounts_page.dart';
import 'package:myfinance2/pages/categories_page.dart';
import 'package:myfinance2/services/account_entity_service.dart';
import 'package:myfinance2/services/category_entity_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  bool _hasAccounts = true;
  bool _hasExpenseCategories = true;
  bool _hasIncomeCategories = true;

  @override
  void initState() {
    super.initState();
    _updateButtonFlags();
  }

  _updateButtonFlags() async {
    _hasAccounts = await AccountEntityService.existsAtLeastOneAccount();
    _hasExpenseCategories = await CategoryEntityService.existsAtLeastOneCategoryByType(TransactionType.EXPENSE);
    _hasIncomeCategories = await CategoryEntityService.existsAtLeastOneCategoryByType(TransactionType.INCOME);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    double buttonSize = (MediaQuery.of(context).size.width - 32) / 4; // 32 = 8 padding per lato * 4

    return Scaffold(
      appBar: AppBar(title: Text("Settings")),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.count(
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: [
            _buildSquareButton(
              "Accounts",
              Icons.account_balance,
              buttonSize,
              !_hasAccounts,
              "Set your accounts!",
              () => _navigateToAccounts(context),
            ),
            _buildSquareButton("Expense Categories", Icons.category_outlined, buttonSize, !_hasExpenseCategories, "Set your categories!",
              () => _navigateToCategory(context, TransactionType.EXPENSE)),
            _buildSquareButton("Income Categories", Icons.category, buttonSize, !_hasIncomeCategories, "Set your categories!", 
              () => _navigateToCategory(context, TransactionType.INCOME)),
            _buildSquareButton("Reports", Icons.bar_chart, buttonSize, false, "", () {}),
            _buildSquareButton("Backup", Icons.cloud_upload, buttonSize, false, "", () {}),
            _buildSquareButton("Backup", Icons.cloud_upload, buttonSize, false, "", () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildSquareButton(
    String label,
    IconData icon,
    double size,
    bool highlight,
    String highlightText,
    VoidCallback onPressed,
  ) {
    return Stack(
      clipBehavior: Clip.none, // Permette al badge di uscire dai confini del bottone
      children: [
        SizedBox(
          width: size,
          height: size,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: highlight ? BorderSide(color: Colors.deepPurple, width: 2) : BorderSide.none,
              ),
              backgroundColor: Colors.deepPurple[100],
              padding: EdgeInsets.symmetric(vertical: 4),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 30, color: Colors.black54),
                SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        if (highlight)
        Positioned(
          bottom: -5,
          left: 0,
          right: 0,
          child: LayoutBuilder(
            builder: (context, constraints) {
              double fontSize = 12;
              double maxWidth = constraints.maxWidth - 8; // Margine interno

              TextPainter textPainter = TextPainter(
                text: TextSpan(
                  text: highlightText,
                  style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
                ),
                maxLines: 1,
                textDirection: TextDirection.ltr,
              );

              // Riduciamo il font size finché il testo non rientra nel massimo spazio disponibile
              while (fontSize > 6) { 
                textPainter.text = TextSpan(
                  text: highlightText,
                  style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
                );
                textPainter.layout();
                if (textPainter.width <= maxWidth) break;
                fontSize -= 1;
              }

              return Container(
                padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  highlightText,
                  style: TextStyle(fontSize: fontSize, color: Colors.white, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _navigateToAccounts(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AccountsPage()),
    ).then((_) {
      _updateButtonFlags();
    });
  }
    
  void _navigateToCategory(BuildContext context, TransactionType transactionType) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CategoriesPage(type: transactionType,)),
    ).then((_) {
      _updateButtonFlags();
    });
    
  }
} 