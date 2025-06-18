import 'package:flutter/material.dart';
import 'package:myfinance2/services/configuration_entity_service.dart';
import 'package:myfinance2/widgets/info_label.dart';
import 'package:myfinance2/widgets/save_button.dart';

class MonthlySavingSettingsPage extends StatefulWidget {
  final double monthlySaving;
  
  const MonthlySavingSettingsPage({super.key, required this.monthlySaving});

  @override
  State createState() => MonthlySavingSettingsPageState();
}

class MonthlySavingSettingsPageState extends State<MonthlySavingSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late double _monthlySaving;

  @override
  void initState() {
    super.initState();
    _monthlySaving = widget.monthlySaving;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          debugPrint("Popping MonthlySavingSettingsPage _dataChanged=false, result=$result");
          Navigator.pop(context, false);
        }
      },
      child: GestureDetector(
        onTap: () {
          FocusScopeNode currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus) {
            currentFocus.unfocus();
          }
        },
        child: Scaffold(
            appBar: AppBar(title: const Text("Settings")),
            body: SafeArea(child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child:
                Column(
                  children: [
                    InfoLabel(text: "You can set how much money you would like to save each month"),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Monthly saving amount'),
                      initialValue: _monthlySaving == 0.0 ? "" : _monthlySaving.toStringAsFixed(2),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: false,
                        signed: false
                      ),
                      onChanged: (value) => _monthlySaving = double.tryParse(value) ?? 0.00,
                      validator: (value) => value != null && (double.tryParse(value) ?? 0.00) < 0 ? 'The amount must be a positive value' : null,
                    ),
                    SizedBox(height: 20),
                    SaveButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _saveConfigurations();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _saveConfigurations() async {
    await ConfigurationEntityService.updateMonthlySaving(_monthlySaving);
    if (mounted) {
      Navigator.pop(context, true);
    }
  }
} 