import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  final Function(Pages) onNavigate;

  const AppDrawer({
    super.key,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.deepPurple,
            ),
            child: Text(
              'Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text('Change currency'),
            onTap: () => onNavigate(Pages.currencies),
          ),
          Divider(),
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text('Expense Categories setup'),
            onTap: () => onNavigate(Pages.expenseCategories),
          ),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Income Categories setup'),
            onTap: () => onNavigate(Pages.incomeCategories),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance),
            title: const Text('Accounts setup'),
            onTap: () => onNavigate(Pages.accounts),
          ),
          ListTile(
            leading: const Icon(Icons.data_thresholding_outlined),
            title: const Text('Category Budgets'),
            onTap: () => onNavigate(Pages.categoryBudgets),
          ),
          ListTile(
            leading: const Icon(Icons.group_work_outlined),
            title: const Text('Groups setup'),
            onTap: () => onNavigate(Pages.groups),
          ),
          Divider(),
          ListTile(
            leading: const Icon(Icons.savings),
            title: const Text('Monthly saving settings'),
            onTap: () => onNavigate(Pages.monthlySavingsSettings),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month),
            title: const Text('Period settings'),
            onTap: () => onNavigate(Pages.periodSettings),
          ),
          Divider(),
          ListTile(
            leading: const Icon(Icons.dataset_outlined),
            title: const Text('XLSX Import'),
            onTap: () => onNavigate(Pages.xlsxImport),
          ),
          ListTile(
            leading: const Icon(Icons.dataset_rounded),
            title: const Text('XLSX Export'),
            onTap: () => onNavigate(Pages.xlsxExport),
          ),
          Divider(),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Info'),
            onTap: () => onNavigate(Pages.about),
          ),
          SizedBox(height: 50,),
        ],
      ),
    );
  }
}

enum Pages {
  currencies,
  accounts,
  expenseCategories,
  incomeCategories,
  categoryBudgets,
  groups,
  xlsxImport,
  xlsxExport,
  monthlySavingsSettings,
  periodSettings,
  about,
}
