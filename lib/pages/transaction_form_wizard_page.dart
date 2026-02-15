import 'package:flutter/material.dart';
import 'package:myfinance2/model/account.dart';
import 'package:myfinance2/model/category.dart';
import 'package:myfinance2/model/category_type.dart';
import 'package:myfinance2/model/transaction.dart';
import 'package:myfinance2/model/transaction_type.dart';
import 'package:myfinance2/pages/account_form_page.dart';
import 'package:myfinance2/pages/category_form_page.dart';
import 'package:myfinance2/services/account_entity_service.dart';
import 'package:myfinance2/services/category_entity_service.dart';
import 'package:myfinance2/services/transaction_entity_service.dart';
import 'package:myfinance2/utils/color_identity.dart';
import 'package:myfinance2/utils/date_utils.dart';
import 'package:myfinance2/widgets/amount_input_field.dart';
import 'package:myfinance2/widgets/circular_add_button.dart';
import 'package:myfinance2/widgets/emoji_button.dart';
import 'package:myfinance2/widgets/footer_button.dart';
import 'package:myfinance2/widgets/section_divider.dart';

class TransactionFormWizardPage extends StatefulWidget {
  final int? transactionId;
  final Transaction transaction;
  final bool isNew;
  final DateTime? initialDate;
  final int? initialAccount;
  final int? initialCategory;
  final bool startOnAmountPage;

  const TransactionFormWizardPage({
    super.key,
    this.transactionId,
    required this.transaction,
    required this.isNew,
    this.initialDate,
    this.initialAccount,
    this.initialCategory,
    this.startOnAmountPage = false,
  });

  @override
  TransactionFormWizardPageState createState() => TransactionFormWizardPageState();
}

class TransactionFormWizardPageState extends State<TransactionFormWizardPage> {
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();
  
  TransactionType _selectedType = TransactionType.EXPENSE;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int? _selectedSourceAccount;
  int? _selectedAccount;
  int? _selectedCategory;
  double _amount = 0.0;
  String? _notes = '';
  
  List<Account> _accounts = [];
  List<Category> _categories = [];
  Account? _selectedAccountObject;
  Account? _selectedSourceAccountObject;
  Category? _selectedCategoryObject;
  
  int? _oldCategoryId;
  int? _oldAccountId;
  DateTime? _oldTimestamp;
  int? _oldSourceAccountId;
  
  bool _isLoading = true;
  final Color? _selectedButtonColor = Colors.deepPurple[200];
  final Color? _notSelectedButtonColor = Colors.grey[50];
  final bool _showTime = true;
  bool _multipleAccounts = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.transaction.type;
    _selectedDate = widget.initialDate ?? DateTime.now();
    _selectedTime = TimeOfDay.fromDateTime(_selectedDate);
    _selectedAccount = widget.initialAccount;
    _selectedCategory = widget.initialCategory;
    
    if (widget.isNew) {
      _loadData();
    } else {
      _loadTransaction();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadTransaction() async {
    final transaction = await TransactionEntityService.getById(widget.transactionId!);
    _selectedType = transaction.type;
    _selectedDate = transaction.timestamp;
    _selectedTime = TimeOfDay.fromDateTime(transaction.timestamp);
    _selectedAccount = transaction.accountId;
    _selectedSourceAccount = transaction.sourceAccountId;
    _selectedCategory = transaction.categoryId;
    _amount = transaction.amount ?? 0.0;
    _notes = transaction.notes;
    _oldCategoryId = transaction.categoryId;
    _oldAccountId = transaction.accountId;
    _oldTimestamp = transaction.timestamp;
    _oldSourceAccountId = transaction.sourceAccountId;
    
    await _loadData();
    
    // For editing, determine which page to start on based on user's click
    int initialPage = widget.startOnAmountPage ? 1 : 0;
    if (_pageController.hasClients) {
      _pageController.jumpToPage(initialPage);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(initialPage);
        }
      });
    }
  }

  Future<void> _loadData() async {
    _accounts = await AccountEntityService.getAllAccounts();
    _categories = await CategoryEntityService.getAllCategories(
      _selectedType == TransactionType.EXPENSE ? CategoryType.EXPENSE : CategoryType.INCOME
    );
    
    if (_accounts.isNotEmpty) {
      if (_accounts.length > 1) {
        _multipleAccounts = true;
      } else {
        _selectedAccount ??= _accounts[0].id;
        _selectedSourceAccount ??= _accounts[0].id;
      }
    }
    
    if (_categories.isNotEmpty) {
      if (_categories.length == 1) {
        _selectedCategory ??= _categories[0].id;
      }
    }
    
    await _loadSelectedObjects();
    
    _isLoading = false;
    setState(() {});
    
    // Check if we should auto-navigate to step 2
    _checkAndNavigateToStep2();
  }

  Future<void> _loadSelectedObjects() async {
    if (_selectedAccount != null) {
      _selectedAccountObject = _accounts.firstWhere(
        (a) => a.id == _selectedAccount,
        orElse: () => _accounts.first
      );
    }
    
    if (_selectedSourceAccount != null) {
      _selectedSourceAccountObject = _accounts.firstWhere(
        (a) => a.id == _selectedSourceAccount,
        orElse: () => _accounts.first
      );
    }
    
    if (_selectedCategory != null) {
      _selectedCategoryObject = await CategoryEntityService.getCategoryById(_selectedCategory!);
    }
  }

  void _checkAndNavigateToStep2() {
    if (!widget.isNew) return; // Don't auto-navigate when editing
    
    bool canProceed = _selectedType == TransactionType.TRANSFER
        ? _selectedAccount != null && _selectedSourceAccount != null
        : _selectedAccount != null && _selectedCategory != null;
    
    if (canProceed) {
      // Use post-frame callback to ensure PageController is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          _pageController.animateToPage(
            1,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  void _goToStep1() {
    _pageController.animateToPage(
      0,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          _selectedTime.hour,
          _selectedTime.minute
        );
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoadingScaffold();
    if (_accounts.isEmpty || _categories.isEmpty) return _buildEmptyConfigScaffold();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        appBar: _buildAppBar(),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildDateTimeRow(context),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  children: [
                    _buildStep1(),
                    _buildStep2(),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: _buildSaveButton(),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(widget.isNew ? 'New ${getTransactionTypeText(_selectedType)}' : 'Edit ${getTransactionTypeText(_selectedType)}'),
      actions: [
        if (!widget.isNew)
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => _showDeleteConfirmationDialog(context),
          ),
      ],
    );
  }

  Widget _buildLoadingScaffold() {
    return Scaffold(
      appBar: AppBar(title: Text('Loading...')),
      body: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildEmptyConfigScaffold() {
    return Scaffold(
      appBar: AppBar(title: Text('Configuration Required')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: const [
            SizedBox(height: 20),
            Text("You still need to configure accounts and/or categories"),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildDateButton(context),
        ),
        const SizedBox(width: 12),
        _showTime ? Expanded(child: _buildTimeButton(context)) : const SizedBox(),
      ],
    );
  }

  Widget _buildDateButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _selectDate(context),
      style: _elevatedStyle(),
      child: Row(
        children: [
          Icon(Icons.calendar_month),
          const SizedBox(width: 10),
          Text(MyDateUtils.formatDate(_selectedDate) ?? "", style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildTimeButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _selectTime(context),
      style: _elevatedStyle(),
      child: Row(
        children: [
          Icon(Icons.access_time),
          const SizedBox(width: 10),
          Text(_selectedTime.format(context), style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  ButtonStyle _elevatedStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.grey[200],
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    );
  }

  // STEP 1: Account and Category Selection
  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildSourceAccountSelector(),
                  _buildTargetAccountSelector(),
                  _buildCategorySelector(),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
          if (!widget.isNew) _buildEditAmountHint(),
          SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildSourceAccountSelector() {
    if (_selectedType != TransactionType.TRANSFER) return const SizedBox();
    return Column(
      children: [
        SectionDivider(
          text: 'Source account',
        ),
        _buildEmojiGrid(
          items: _accounts,
          selectedId: _selectedSourceAccount,
          onPressed: (id) async {
            setState(() => _selectedSourceAccount = id);
            await _loadSelectedObjects();
            _checkAndNavigateToStep2();
          },
          onAddButtonPressed: _navigateToCreateAccount,
        ),
      ],
    );
  }

  Widget _buildTargetAccountSelector() {
    return Column(
      children: [
        _multipleAccounts 
          ? SectionDivider(
              text: _selectedType == TransactionType.TRANSFER ? 'Target account' : 'Select account',
            ) 
          : const SizedBox(),
        if (_multipleAccounts)
          _buildEmojiGrid(
            items: _accounts,
            selectedId: _selectedAccount,
            onPressed: (id) async {
              setState(() => _selectedAccount = id);
              await _loadSelectedObjects();
              _checkAndNavigateToStep2();
            },
            onAddButtonPressed: _navigateToCreateAccount,
          ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    if (_selectedType == TransactionType.TRANSFER) return const SizedBox();
    return Column(
      children: [
        SectionDivider(
          text: 'Select category',
        ),
        const SizedBox(height: 6),
        _buildEmojiGrid(
          items: _categories,
          selectedId: _selectedCategory,
          onPressed: (id) async {
            setState(() => _selectedCategory = id);
            await _loadSelectedObjects();
            _checkAndNavigateToStep2();
          },
          onAddButtonPressed: _navigateToCreateCategory,
        ),
      ],
    );
  }

  Future<void> _navigateToCreateCategory() async {
    final CategoryType categoryType = _selectedType == TransactionType.EXPENSE 
        ? CategoryType.EXPENSE 
        : CategoryType.INCOME;
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryFormPage(
          category: Category(
            id: 0,
            name: '',
            type: categoryType,
            sort: _categories.length + 1
          ),
          isNew: true,
        ),
      ),
    );
    
    // If the category was created, reload the categories
    if (result == true) {
      debugPrint("Category list updated, reloading.");
      await _reloadCategories();
    } else {
      debugPrint("No changes in category list");
    }
  }

  Future<void> _reloadCategories() async {
    _categories = await CategoryEntityService.getAllCategories(
      _selectedType == TransactionType.EXPENSE ? CategoryType.EXPENSE : CategoryType.INCOME
    );
    setState(() {});
  }

  Future<void> _navigateToCreateAccount() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AccountFormPage(
          account: Account(
            id: 0,
            name: '',
            initialBalance: 0.0,
            sort: _accounts.length + 1,
          ),
          isNew: true,
        ),
      ),
    );
    
    // If the account was created, reload the accounts
    if (result == true) {
      await _reloadAccounts();
    }
  }

  Future<void> _reloadAccounts() async {
    _accounts = await AccountEntityService.getAllAccounts();
    
    // Update multipleAccounts flag
    if (_accounts.isNotEmpty && _accounts.length > 1) {
      _multipleAccounts = true;
    }
    
    setState(() {});
  }

  Widget _buildEditAmountHint() {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: InkWell(
        onTap: () {
          _pageController.animateToPage(
            1,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        child: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Icon(Icons.arrow_forward, size: 20, color: Colors.grey[600]),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Swipe right to edit amount',
                  style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                ),
              ),
              Icon(Icons.edit, size: 20, color: Colors.grey[600]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmojiGrid({
    required List<dynamic> items,
    required int? selectedId,
    required Function(int) onPressed,
    VoidCallback? onAddButtonPressed,
  }) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double buttonSize = (screenWidth - (6 * 6) - 16 - 10) / 5;

    List<Widget> children = items.map<Widget>((item) {
      final String icon = item.icon ?? item.name.substring(0, 2);
      return EmojiButton(
        icon: icon,
        label: item.name,
        width: buttonSize,
        height: buttonSize,
        onPressed: () => onPressed(item.id),
        backgroundColor: selectedId == item.id ? _selectedButtonColor : _notSelectedButtonColor,
      );
    }).toList();

    // Add circular add button if callback is provided
    if (onAddButtonPressed != null) {
      children.add(
        CircularAddButton(
          size: buttonSize,
          onPressed: onAddButtonPressed,
        ),
      );
    }

    return Align(
      alignment: Alignment.center,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: children,
      ),
    );
  }

  // STEP 2: Amount and Notes
  Widget _buildStep2() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 12),
            _buildSelectedAccountCategoryRow(),
            SizedBox(height: 20),
            _buildAmountField(),
            _buildNotesField(),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedAccountCategoryRow() {
    return InkWell(
      onTap: _goToStep1,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildRowContent(),
            ),
            Icon(Icons.edit, size: 20, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Widget _buildRowContent() {
    List<Widget> items = [];
    
    // For transfers, show source and target accounts
    if (_selectedType == TransactionType.TRANSFER) {
      if (_selectedSourceAccountObject != null) {
        items.add(_buildItemChip(
          icon: _selectedSourceAccountObject!.icon ?? '💰',
          name: _selectedSourceAccountObject!.name,
          prefix: 'From: ',
        ));
      }
      if (_selectedAccountObject != null) {
        items.add(_buildItemChip(
          icon: _selectedAccountObject!.icon ?? '💰',
          name: _selectedAccountObject!.name,
          prefix: 'To: ',
        ));
      }
    } else {
      // For expense/income, show account (if multiple) and category
      if (_multipleAccounts && _selectedAccountObject != null) {
        items.add(_buildItemChip(
          icon: _selectedAccountObject!.icon ?? '💰',
          name: _selectedAccountObject!.name,
        ));
      }
      if (_selectedCategoryObject != null) {
        items.add(_buildItemChip(
          icon: _selectedCategoryObject!.icon ?? '📁',
          name: _selectedCategoryObject!.name,
        ));
      }
    }
    
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: items,
    );
  }

  Widget _buildItemChip({required String icon, required String name, String? prefix}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          icon,
          style: TextStyle(fontSize: 20),
        ),
        SizedBox(width: 6),
        Text(
          '${prefix ?? ''}$name',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildAmountField() {
    return AmountInputField(
      initialAmount: _amount,
      label: "Amount",
      onChanged: (val) {
        setState(() {
          _amount = val;
        });
      },
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      decoration: InputDecoration(labelText: 'Notes'),
      onChanged: (value) => _notes = value,
      initialValue: _notes,
    );
  }

  Widget _buildSaveButton() {
    bool isSaveEnabled = _selectedType == TransactionType.TRANSFER
        ? _selectedAccount != null && _selectedSourceAccount != null
        : _selectedAccount != null && _selectedCategory != null;
    
    return Container(
      color: backgroundGrey(),
      padding: EdgeInsets.only(left: 80, right: 80, bottom: 6, top: 6),
      child: FooterButton(
        text: "Save",
        onPressed: isSaveEnabled
            ? () {
                if (_formKey.currentState?.validate() ?? true) {
                  _saveTransaction();
                }
              }
            : null,
        color: isSaveEnabled ? deepPurple() : backgroundGrey()
      ),
    );
  }

  Future<void> _saveTransaction() async {
    bool isTransfer = _selectedType == TransactionType.TRANSFER;
    Transaction transaction = widget.transaction;
    transaction.type = _selectedType;
    transaction.timestamp = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    transaction.accountId = _selectedAccount!;
    transaction.sourceAccountId = isTransfer ? _selectedSourceAccount : null;
    transaction.categoryId = !isTransfer ? _selectedCategory : null;
    transaction.amount = _amount;
    transaction.notes = _notes;
    
    if (widget.isNew) {
      await TransactionEntityService.insertTransaction(transaction, true);
    } else {
      await TransactionEntityService.updateTransaction(
        transaction,
        _oldAccountId!,
        _oldCategoryId,
        _oldTimestamp!,
        _oldSourceAccountId
      );
    }
    
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Transaction'),
          content: Text('This action is irreversible. Are you sure you want to delete this transaction?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                _deleteTransaction();
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteTransaction() async {
    Transaction transaction = widget.transaction;
    transaction.accountId = _oldAccountId!;
    transaction.categoryId = _oldCategoryId;
    await TransactionEntityService.deleteTransaction(transaction);
    if (mounted) {
      Navigator.pop(context); // Close the dialog
      Navigator.pop(context); // Close the page
    }
  }
}

String getTransactionTypeText(TransactionType type) {
  switch (type) {
    case TransactionType.EXPENSE:
      return 'Expense';
    case TransactionType.INCOME:
      return 'Income';
    case TransactionType.TRANSFER:
      return 'Transfer';
  }
}
