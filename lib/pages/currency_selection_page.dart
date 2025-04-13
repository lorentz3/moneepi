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

  @override
  void initState() {
    super.initState();
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    final code = await AppConfig.instance.getCurrencyCode();
    setState(() {
      _selectedCurrencyCode = code;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose your currency:')),
      body: ListView.builder(
        itemCount: CurrencyDto.availableCurrencies.length,
        itemBuilder: (context, index) {
          final currency = CurrencyDto.availableCurrencies[index];
          final isSelected = currency.code == _selectedCurrencyCode;

          return ListTile(
            leading: Text(currency.symbol, style: const TextStyle(fontSize: 20)),
            title: Text('${currency.name} (${currency.code})'),
            trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
            onTap: () async {
              // Salva in Configurations
              await ConfigurationEntityService.updateCurrency(currency.code);
              _loadCurrency();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Currency updated!"))
              );
            },
          );
        },
      ),
    );
  }

}
