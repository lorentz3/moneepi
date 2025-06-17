import 'package:flutter/material.dart';
import 'package:myfinance2/dto/currency_dto.dart';
import 'package:myfinance2/services/app_config.dart';
import 'package:myfinance2/services/configuration_entity_service.dart';

class CurrencySelectionPage extends StatefulWidget {
  const CurrencySelectionPage({super.key});

  @override
  State<CurrencySelectionPage> createState() => _CurrencySelectionPageState();
}

class _CurrencySelectionPageState extends State<CurrencySelectionPage> {
  String? _selectedCurrencyCode;
  List<CurrencyDto> _filteredCurrencies = [];
  final TextEditingController _searchController = TextEditingController();
  bool _dataChanged = false;

  @override
  void initState() {
    super.initState();
    _initializePage();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _initializePage() async {
    final code = await AppConfig.instance.getCurrencyCode();
    setState(() {
      _selectedCurrencyCode = code;
      _filteredCurrencies = CurrencyDto.availableCurrencies;
    });
  }

  Future<void> _updateSelection() async {
    _dataChanged = true;
    final code = await AppConfig.instance.getCurrencyCode();
    setState(() {
      _selectedCurrencyCode = code;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCurrencies = CurrencyDto.availableCurrencies.where((currency) {
        return currency.name.toLowerCase().contains(query) ||
               currency.code.toLowerCase().contains(query) ||
               currency.symbol.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          debugPrint("Popping CurrencySelectionPage _dataChanged=$_dataChanged, result=$result");
          Navigator.pop(context, _dataChanged);
        }
      },
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(title: const Text('Choose your currency:')),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Search currency',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredCurrencies.length,
                  itemBuilder: (context, index) {
                    final currency = _filteredCurrencies[index];
                    final isSelected = currency.code == _selectedCurrencyCode;

                    return ListTile(
                      leading: Text(currency.symbol, style: const TextStyle(fontSize: 20)),
                      title: Text('${currency.name} (${currency.code})'),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: Colors.green)
                          : null,
                      onTap: () async {
                        await ConfigurationEntityService.updateCurrency(currency.code);
                        _updateSelection();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Currency updated!")),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
